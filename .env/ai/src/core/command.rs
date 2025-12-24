// Command Coordinator
// Main interface for routing user commands to AI agents
// Uses Ollama cluster for intent recognition and planning
// HTTP Port: 9015
// gRPC Port: 9115

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tower_http::cors::CorsLayer;
use tracing::{error, info, warn};

mod grpc_service;

// ============================================================================
// Configuration
// ============================================================================

const API_GATEWAY: &str = "http://127.0.0.1:9013";
const OLLAMA_NODES: &[&str] = &[
    "http://192.168.12.106:11434", // granite4:1b, nexusraven:13b, qwen2.5:14b, gemma3:12b
    "http://192.168.12.66:11434",  // deepcoder:14b, codestral:22b, deepseek-coder-v2:16b, codellama:13b
    "http://192.168.12.9:11434",   // smallthinker:3b, nuextract:3.8b, phi4-mini:3.8b
    "http://192.168.12.136:11434", // shieldgemma:9b, mistrallite:7b, duckdb-nsql:7b, llava-phi3:3.8b, llava-llama3:8b
];

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Deserialize)]
struct CommandRequest {
    /// Natural language command or structured command
    command: String,
    /// Optional context for the command
    context: Option<serde_json::Value>,
    /// Preferred ollama model (optional)
    model: Option<String>,
}

#[derive(Debug, Serialize)]
struct CommandResponse {
    success: bool,
    result: Option<serde_json::Value>,
    actions_taken: Vec<String>,
    error: Option<String>,
    execution_time_ms: u64,
}

#[derive(Debug, Serialize, Deserialize)]
struct AgentAction {
    agent: String,
    endpoint: String,
    payload: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
struct OllamaRequest {
    model: String,
    prompt: String,
    stream: bool,
    format: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OllamaResponse {
    response: String,
}

pub struct AppState {
    pub client: reqwest::Client,
}

// ============================================================================
// Ollama Integration
// ============================================================================

impl AppState {
    async fn ask_ollama(&self, prompt: &str, model: &str) -> Result<String, String> {
        // Try each node in sequence until one works
        for node in OLLAMA_NODES {
            let url = format!("{}/api/generate", node);

            let payload = OllamaRequest {
                model: model.to_string(),
                prompt: prompt.to_string(),
                stream: false,
                format: Some("json".to_string()),
            };

            match self
                .client
                .post(&url)
                .json(&payload)
                .timeout(Duration::from_secs(60))
                .send()
                .await
            {
                Ok(resp) => {
                    if let Ok(ollama_resp) = resp.json::<OllamaResponse>().await {
                        info!("Got response from ollama at {}", node);
                        return Ok(ollama_resp.response);
                    }
                }
                Err(e) => {
                    warn!("Ollama node {} failed: {}", node, e);
                    continue;
                }
            }
        }

        Err("All ollama nodes unavailable".to_string())
    }

    async fn parse_command(&self, command: &str, model: &str) -> Result<Vec<AgentAction>, String> {
        let prompt = format!(
            r#"You are a command parser for an AI agent system. Parse this command and output JSON.

Available agents:
- file-ops: read, write, list, execute files/commands
- service-manager: start, stop, restart services
- data-collector: collect trucking data
- web-scraper: scrape websites
- code-assistant: code generation and analysis
- database: database operations
- messaging: send emails/messages
- pdf-service: PDF operations
- screen-controller: screen capture/control
- vision: image analysis

Command: "{}"

Output a JSON array of actions in this exact format:
{{
  "actions": [
    {{
      "agent": "agent-name",
      "endpoint": "/endpoint",
      "payload": {{"key": "value"}}
    }}
  ]
}}

Be precise and only include necessary actions. If unclear, ask via a comment field."#,
            command
        );

        let response = self.ask_ollama(&prompt, model).await?;

        // Parse JSON response
        let parsed: serde_json::Value = serde_json::from_str(&response)
            .map_err(|e| format!("Failed to parse ollama JSON: {}", e))?;

        let actions_json = parsed
            .get("actions")
            .ok_or("No 'actions' field in response")?;

        let actions: Vec<AgentAction> = serde_json::from_value(actions_json.clone())
            .map_err(|e| format!("Failed to deserialize actions: {}", e))?;

        Ok(actions)
    }

    async fn execute_action(&self, action: &AgentAction) -> Result<serde_json::Value, String> {
        let url = format!("{}/api/{}{}", API_GATEWAY, action.agent, action.endpoint);

        info!("Executing action: {} -> {}", action.agent, action.endpoint);

        let response = self
            .client
            .post(&url)
            .json(&action.payload)
            .timeout(Duration::from_secs(120))
            .send()
            .await
            .map_err(|e| format!("Request failed: {}", e))?;

        let result: serde_json::Value = response
            .json()
            .await
            .map_err(|e| format!("Failed to parse response: {}", e))?;

        Ok(result)
    }
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Command Coordinator: ONLINE")
}

async fn execute_command(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CommandRequest>,
) -> impl IntoResponse {
    let start_time = std::time::Instant::now();

    info!("Received command: {}", req.command);

    let model = req.model.unwrap_or_else(|| "mistral:latest".to_string());

    // Parse command using ollama
    let actions = match state.parse_command(&req.command, &model).await {
        Ok(actions) => actions,
        Err(e) => {
            error!("Failed to parse command: {}", e);
            return Json(CommandResponse {
                success: false,
                result: None,
                actions_taken: vec![],
                error: Some(e),
                execution_time_ms: start_time.elapsed().as_millis() as u64,
            });
        }
    };

    info!("Parsed {} actions from command", actions.len());

    // Execute each action
    let mut results = Vec::new();
    let mut action_descriptions = Vec::new();

    for action in actions {
        action_descriptions.push(format!(
            "{} -> {}",
            action.agent, action.endpoint
        ));

        match state.execute_action(&action).await {
            Ok(result) => results.push(result),
            Err(e) => {
                error!("Action failed: {}", e);
                return Json(CommandResponse {
                    success: false,
                    result: None,
                    actions_taken: action_descriptions,
                    error: Some(e),
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                });
            }
        }
    }

    let execution_time = start_time.elapsed().as_millis() as u64;

    info!(
        "Command executed successfully in {}ms",
        execution_time
    );

    Json(CommandResponse {
        success: true,
        result: Some(serde_json::json!({ "results": results })),
        actions_taken: action_descriptions,
        error: None,
        execution_time_ms: execution_time,
    })
}

#[derive(Debug, Deserialize)]
struct DirectActionRequest {
    actions: Vec<AgentAction>,
}

async fn execute_direct(
    State(state): State<Arc<AppState>>,
    Json(req): Json<DirectActionRequest>,
) -> impl IntoResponse {
    let start_time = std::time::Instant::now();

    info!("Executing {} direct actions", req.actions.len());

    let mut results = Vec::new();
    let mut action_descriptions = Vec::new();

    for action in req.actions {
        action_descriptions.push(format!("{} -> {}", action.agent, action.endpoint));

        match state.execute_action(&action).await {
            Ok(result) => results.push(result),
            Err(e) => {
                error!("Action failed: {}", e);
                return Json(CommandResponse {
                    success: false,
                    result: None,
                    actions_taken: action_descriptions,
                    error: Some(e),
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                });
            }
        }
    }

    Json(CommandResponse {
        success: true,
        result: Some(serde_json::json!({ "results": results })),
        actions_taken: action_descriptions,
        error: None,
        execution_time_ms: start_time.elapsed().as_millis() as u64,
    })
}

#[derive(Debug, Serialize)]
struct StatusResponse {
    coordinator: &'static str,
    api_gateway: String,
    ollama_nodes: Vec<OllamaNodeStatus>,
}

#[derive(Debug, Serialize)]
struct OllamaNodeStatus {
    url: String,
    available: bool,
}

async fn get_status(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let mut ollama_statuses = Vec::new();

    for node in OLLAMA_NODES {
        let available = state
            .client
            .get(format!("{}/api/tags", node))
            .timeout(Duration::from_secs(2))
            .send()
            .await
            .is_ok();

        ollama_statuses.push(OllamaNodeStatus {
            url: node.to_string(),
            available,
        });
    }

    let gateway_status = state
        .client
        .get(format!("{}/health", API_GATEWAY))
        .timeout(Duration::from_secs(2))
        .send()
        .await
        .map(|r| r.status().to_string())
        .unwrap_or_else(|_| "Offline".to_string());

    Json(StatusResponse {
        coordinator: "ONLINE",
        api_gateway: gateway_status,
        ollama_nodes: ollama_statuses,
    })
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Command Coordinator (Hybrid Mode)");
    info!("  HTTP Server: 127.0.0.1:9015");
    info!("  gRPC Server: 127.0.0.1:9115");

    let state = Arc::new(AppState {
        client: reqwest::Client::new(),
    });

    // Clone state for gRPC server
    let grpc_state = Arc::clone(&state);

    // Build HTTP app
    let app = Router::new()
        .route("/health", get(health))
        .route("/status", get(get_status))
        .route("/command", post(execute_command))
        .route("/execute", post(execute_direct))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start HTTP server
    let http_server = async {
        let addr = "127.0.0.1:9015";
        info!("HTTP Server listening on {}", addr);
        info!("HTTP Endpoints:");
        info!("  POST /command - Execute natural language command");
        info!("  POST /execute - Execute direct agent actions");
        info!("  GET /status - Get system status");
        info!("  GET /health - Health check");

        let listener = tokio::net::TcpListener::bind(addr).await?;
        axum::serve(listener, app).await.map_err(Into::into)
    };

    // Start gRPC server
    let grpc_server = async {
        grpc_service::start_grpc_server(grpc_state).await
    };

    // Run both servers concurrently
    tokio::select! {
        result = http_server => {
            error!("HTTP server stopped: {:?}", result);
            result
        }
        result = grpc_server => {
            error!("gRPC server stopped: {:?}", result);
            result
        }
    }
}
