// Code Assistant Agent
// Primary autonomous executor - uses distributed Ollama cluster
// Delegates work across 4 laptop nodes with smart model selection

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, warn};

// ============================================================================
// Node Configuration
// ============================================================================

const NODES: &[(&str, &str)] = &[
    ("hostbox", "192.168.12.106"),   // i9-13900H, 24GB - Coordinator
    ("helpbox", "192.168.12.66"),    // Ryzen 5, 32GB+GPU - Heavy compute
    ("workbox", "192.168.12.136"),   // Ultra 7, 16GB+NPU - Fast builds
    ("callbox", "192.168.12.9"),     // i3, 4GB - Monitoring
];

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct OllamaNode {
    name: String,
    address: String,
    available_models: Vec<String>,
    status: NodeStatus,
    load: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum NodeStatus {
    Online,
    Offline,
    Busy,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct TaskRequest {
    task_type: TaskType,
    content: String,
    priority: Priority,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum TaskType {
    QuickQuestion,
    CodeGeneration,
    CodeReview,
    Documentation,
    Architecture,
    Refactoring,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum Priority {
    Fast,      // Use fastest model available
    Balanced,  // Balance speed/quality
    Quality,   // Use best model, don't care about speed
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct TaskResponse {
    id: String,
    result: String,
    model_used: String,
    node_used: String,
    duration_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ModelSelection {
    model: String,
    node: String,
    reason: String,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    nodes: Arc<RwLock<HashMap<String, OllamaNode>>>,
    task_history: Arc<RwLock<Vec<TaskResponse>>>,
}

// ============================================================================
// Ollama Client
// ============================================================================

async fn ollama_generate(node_addr: &str, model: &str, prompt: &str) -> Result<String, String> {
    let url = format!("http://{}:11434/api/generate", node_addr);

    let payload = serde_json::json!({
        "model": model,
        "prompt": prompt,
        "stream": false
    });

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&payload)
        .timeout(std::time::Duration::from_secs(120))
        .send()
        .await
        .map_err(|e| format!("Request failed: {}", e))?;

    if !response.status().is_success() {
        return Err(format!("Ollama returned status: {}", response.status()));
    }

    let result: serde_json::Value = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;

    Ok(result["response"]
        .as_str()
        .unwrap_or("")
        .to_string())
}

async fn check_node_models(node_addr: &str) -> Result<Vec<String>, String> {
    let url = format!("http://{}:11434/api/tags", node_addr);

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .timeout(std::time::Duration::from_secs(5))
        .send()
        .await
        .map_err(|e| format!("Failed to reach node: {}", e))?;

    let data: serde_json::Value = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse: {}", e))?;

    let models = data["models"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|m| m["name"].as_str().map(|s| s.to_string()))
        .collect();

    Ok(models)
}

// ============================================================================
// Model Selection Logic
// ============================================================================

fn select_model(task_type: &TaskType, priority: &Priority, nodes: &HashMap<String, OllamaNode>) -> ModelSelection {
    match (task_type, priority) {
        // Quick questions - use fastest
        (TaskType::QuickQuestion, _) => {
            if let Some(node) = find_node_with_model(nodes, "phi3") {
                return ModelSelection {
                    model: "phi3:latest".to_string(),
                    node: node.clone(),
                    reason: "Super fast, good for quick answers".to_string(),
                };
            }
            ModelSelection {
                model: "phi:latest".to_string(),
                node: "callbox".to_string(),
                reason: "Lightweight fallback".to_string(),
            }
        }

        // Code generation - default to fast models
        (TaskType::CodeGeneration, Priority::Fast) => {
            ModelSelection {
                model: "codellama:7b-instruct".to_string(),
                node: "workbox".to_string(),
                reason: "Fast code generation".to_string(),
            }
        }

        (TaskType::CodeGeneration, Priority::Balanced) => {
            ModelSelection {
                model: "codellama:13b".to_string(),
                node: "helpbox".to_string(),
                reason: "Balanced quality/speed".to_string(),
            }
        }

        (TaskType::CodeGeneration, Priority::Quality) => {
            ModelSelection {
                model: "qwen2.5-coder:32b".to_string(),
                node: "helpbox".to_string(),
                reason: "Highest quality (slow)".to_string(),
            }
        }

        // Code review - balanced
        (TaskType::CodeReview, _) => {
            ModelSelection {
                model: "codellama:13b".to_string(),
                node: "helpbox".to_string(),
                reason: "Good reasoning for reviews".to_string(),
            }
        }

        // Documentation - great with text
        (TaskType::Documentation, _) => {
            ModelSelection {
                model: "mistral:latest".to_string(),
                node: "hostbox".to_string(),
                reason: "Excellent text generation".to_string(),
            }
        }

        // Architecture - use heavy model
        (TaskType::Architecture, _) => {
            ModelSelection {
                model: "qwen2.5-coder:32b".to_string(),
                node: "helpbox".to_string(),
                reason: "Complex reasoning required".to_string(),
            }
        }

        // Refactoring - balanced
        (TaskType::Refactoring, _) => {
            ModelSelection {
                model: "codellama:13b".to_string(),
                node: "helpbox".to_string(),
                reason: "Good code understanding".to_string(),
            }
        }
    }
}

fn find_node_with_model(nodes: &HashMap<String, OllamaNode>, model_name: &str) -> Option<String> {
    for (name, node) in nodes {
        if node.available_models.iter().any(|m| m.contains(model_name)) {
            return Some(name.clone());
        }
    }
    None
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Code Assistant: ONLINE")
}

async fn node_status(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let nodes = state.nodes.read().await;

    Json(serde_json::json!({
        "success": true,
        "nodes": nodes.values().collect::<Vec<_>>()
    }))
}

async fn execute_task(
    State(state): State<Arc<AppState>>,
    Json(req): Json<TaskRequest>,
) -> impl IntoResponse {
    let start = std::time::Instant::now();

    // Select best model
    let nodes = state.nodes.read().await;
    let selection = select_model(&req.task_type, &req.priority, &nodes);

    info!("Selected {} on {} for {:?}", selection.model, selection.node, req.task_type);

    // Get node address
    let node_addr = nodes.get(&selection.node)
        .map(|n| n.address.clone())
        .unwrap_or_else(|| "192.168.12.106".to_string());

    drop(nodes);

    // Execute on Ollama
    match ollama_generate(&node_addr, &selection.model, &req.content).await {
        Ok(result) => {
            let duration = start.elapsed().as_millis() as u64;

            let response = TaskResponse {
                id: uuid::Uuid::new_v4().to_string(),
                result: result.clone(),
                model_used: selection.model.clone(),
                node_used: selection.node.clone(),
                duration_ms: duration,
            };

            // Store in history
            let mut history = state.task_history.write().await;
            history.push(response.clone());

            info!("Task completed in {}ms using {}", duration, selection.model);

            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "response": response,
                    "selection_reason": selection.reason
                })),
            )
        }
        Err(e) => {
            error!("Task failed: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": e
                })),
            )
        }
    }
}

async fn refresh_nodes(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let mut nodes = state.nodes.write().await;

    for (name, addr) in NODES {
        info!("Checking node: {}", name);

        match check_node_models(addr).await {
            Ok(models) => {
                nodes.insert(name.to_string(), OllamaNode {
                    name: name.to_string(),
                    address: addr.to_string(),
                    available_models: models,
                    status: NodeStatus::Online,
                    load: 0.0,
                });
            }
            Err(e) => {
                warn!("Node {} offline: {}", name, e);
                nodes.insert(name.to_string(), OllamaNode {
                    name: name.to_string(),
                    address: addr.to_string(),
                    available_models: vec![],
                    status: NodeStatus::Offline,
                    load: 0.0,
                });
            }
        }
    }

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "nodes_checked": NODES.len()
        })),
    )
}

async fn task_history(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let history = state.task_history.read().await;

    Json(serde_json::json!({
        "success": true,
        "tasks": history.iter().rev().take(50).collect::<Vec<_>>()
    }))
}

// ============================================================================
// Background Node Monitor
// ============================================================================

async fn monitor_nodes(state: Arc<AppState>) {
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60));

    loop {
        interval.tick().await;

        let mut nodes = state.nodes.write().await;
        for (name, addr) in NODES {
            if let Ok(models) = check_node_models(addr).await {
                if let Some(node) = nodes.get_mut(*name) {
                    node.status = NodeStatus::Online;
                    node.available_models = models;
                }
            }
        }
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Code Assistant");
    info!("Distributed across 4 Ollama nodes");

    // Initialize nodes
    let mut initial_nodes = HashMap::new();
    for (name, addr) in NODES {
        info!("Discovering node: {}", name);
        match check_node_models(addr).await {
            Ok(models) => {
                info!("  {} online - {} models available", name, models.len());
                initial_nodes.insert(name.to_string(), OllamaNode {
                    name: name.to_string(),
                    address: addr.to_string(),
                    available_models: models,
                    status: NodeStatus::Online,
                    load: 0.0,
                });
            }
            Err(e) => {
                warn!("  {} offline: {}", name, e);
            }
        }
    }

    let state = Arc::new(AppState {
        nodes: Arc::new(RwLock::new(initial_nodes)),
        task_history: Arc::new(RwLock::new(Vec::new())),
    });

    // Start background monitor
    let monitor_state = Arc::clone(&state);
    tokio::spawn(async move {
        monitor_nodes(monitor_state).await;
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/nodes", get(node_status))
        .route("/nodes/refresh", post(refresh_nodes))
        .route("/execute", post(execute_task))
        .route("/history", get(task_history))
        .with_state(state);

    let addr = "127.0.0.1:9008";
    info!("Code Assistant listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
