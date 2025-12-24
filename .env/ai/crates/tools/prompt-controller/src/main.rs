// Prompt Security Controller
// CRITICAL: Only answers to Coordinator
// Prevents rogue agents from modifying system prompts

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post, put},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, warn};

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Prompt {
    agent_name: String,
    version: String,
    content: String,
    hash: String,
    active: bool,
    created_at: String,
    created_by: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PromptRequest {
    agent_name: String,
    version: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PromptUpdate {
    agent_name: String,
    version: String,
    content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AuthToken {
    requester: String,
    timestamp: i64,
    signature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AuditLog {
    timestamp: String,
    requester: String,
    action: String,
    agent_name: Option<String>,
    version: Option<String>,
    allowed: bool,
    reason: Option<String>,
}

// ============================================================================
// State
// ============================================================================

struct AppState {
    coordinator_key: String,
    audit_logs: Arc<RwLock<Vec<AuditLog>>>,
}

// ============================================================================
// Security
// ============================================================================

/// Verify that the request is from the coordinator
fn verify_coordinator(auth: &AuthToken, coordinator_key: &str) -> bool {
    let message = format!("{}{}", auth.requester, auth.timestamp);
    let mut mac = hmac::Hmac::<Sha256>::new_from_slice(coordinator_key.as_bytes())
        .expect("HMAC key");

    use hmac::Mac;
    mac.update(message.as_bytes());

    let expected = hex::encode(mac.finalize().into_bytes());

    auth.requester == "coordinator" && auth.signature == expected
}

/// Calculate hash of prompt content
fn calculate_hash(content: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(content.as_bytes());
    hex::encode(hasher.finalize())
}

/// Log access attempt
async fn log_access(
    state: &AppState,
    requester: &str,
    action: &str,
    agent_name: Option<&str>,
    allowed: bool,
    reason: Option<&str>,
) {
    let log = AuditLog {
        timestamp: chrono::Utc::now().to_rfc3339(),
        requester: requester.to_string(),
        action: action.to_string(),
        agent_name: agent_name.map(|s| s.to_string()),
        version: None,
        allowed,
        reason: reason.map(|s| s.to_string()),
    };

    // Store in memory
    {
        let mut logs = state.audit_logs.write().await;
        logs.push(log.clone());
    }

    if !allowed {
        warn!(
            "SECURITY: Denied {} attempt by {} for agent {:?}",
            action, requester, agent_name
        );
    }
}

// ============================================================================
// Handlers
// ============================================================================

#[derive(Debug, Serialize)]
struct PromptResponse {
    prompt: Option<Prompt>,
    error: Option<String>,
}

/// Get a prompt (coordinator only) - SIMPLIFIED for now
async fn get_prompt(
    State(state): State<Arc<AppState>>,
    Path(agent_name): Path<String>,
    Json(auth): Json<AuthToken>,
) -> Response {
    // Verify coordinator
    if !verify_coordinator(&auth, &state.coordinator_key) {
        log_access(
            &state,
            &auth.requester,
            "get_prompt",
            Some(&agent_name),
            false,
            Some("Authentication failed"),
        )
        .await;

        return (
            StatusCode::UNAUTHORIZED,
            Json(PromptResponse {
                prompt: None,
                error: Some("Unauthorized: Only coordinator can access prompts".to_string()),
            }),
        )
            .into_response();
    }

    log_access(&state, &auth.requester, "get_prompt", Some(&agent_name), true, None).await;

    // For now, return a placeholder (will integrate with DB later)
    (
        StatusCode::OK,
        Json(PromptResponse {
            prompt: Some(Prompt {
                agent_name: agent_name.clone(),
                version: "1.0.0".to_string(),
                content: format!("Prompt for {}", agent_name),
                hash: calculate_hash(&format!("Prompt for {}", agent_name)),
                active: true,
                created_at: chrono::Utc::now().to_rfc3339(),
                created_by: "coordinator".to_string(),
            }),
            error: None,
        }),
    )
        .into_response()
}

#[derive(Debug, Deserialize)]
struct UpdateRequest {
    auth: AuthToken,
    update: PromptUpdate,
}

/// Update a prompt (coordinator only) - SIMPLIFIED for now
async fn update_prompt(
    State(state): State<Arc<AppState>>,
    Json(req): Json<UpdateRequest>,
) -> Response {
    let auth = req.auth;
    let update = req.update;

    // Verify coordinator
    if !verify_coordinator(&auth, &state.coordinator_key) {
        log_access(
            &state,
            &auth.requester,
            "update_prompt",
            Some(&update.agent_name),
            false,
            Some("Authentication failed"),
        )
        .await;

        return (
            StatusCode::UNAUTHORIZED,
            Json(serde_json::json!({
                "success": false,
                "error": "Unauthorized: Only coordinator can update prompts"
            })),
        )
            .into_response();
    }

    let prompt = Prompt {
        agent_name: update.agent_name.clone(),
        version: update.version.clone(),
        content: update.content.clone(),
        hash: calculate_hash(&update.content),
        active: true,
        created_at: chrono::Utc::now().to_rfc3339(),
        created_by: auth.requester.clone(),
    };

    log_access(
        &state,
        &auth.requester,
        "update_prompt",
        Some(&update.agent_name),
        true,
        Some(&format!("Updated to version {}", update.version)),
    )
    .await;

    info!(
        "Prompt updated: {} v{} by {}",
        update.agent_name, update.version, auth.requester
    );

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "prompt": prompt
        })),
    )
        .into_response()
}

/// Get audit logs (coordinator only)
async fn get_audit_logs(
    State(state): State<Arc<AppState>>,
    Json(auth): Json<AuthToken>,
) -> Response {
    if !verify_coordinator(&auth, &state.coordinator_key) {
        return (
            StatusCode::UNAUTHORIZED,
            Json(serde_json::json!({
                "error": "Unauthorized"
            })),
        )
            .into_response();
    }

    let logs = state.audit_logs.read().await;
    (StatusCode::OK, Json(logs.clone())).into_response()
}

/// Health check
async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Prompt Security Controller: ONLINE")
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    info!("Starting Prompt Security Controller");

    // Load coordinator key from environment
    let coordinator_key = std::env::var("COORDINATOR_KEY")
        .unwrap_or_else(|_| "changeme_in_production".to_string());

    info!("Coordinator key configured");

    // Create state
    let state = Arc::new(AppState {
        coordinator_key,
        audit_logs: Arc::new(RwLock::new(Vec::new())),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/prompt/:agent_name", post(get_prompt))
        .route("/prompt", put(update_prompt))
        .route("/audit", post(get_audit_logs))
        .with_state(state);

    // Start server
    let addr = "127.0.0.1:9001";
    info!("Prompt Security Controller listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
