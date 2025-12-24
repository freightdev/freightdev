// Service Manager Agent
// Manages all running services in the agency

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::process::{Child, Command};
use std::sync::Arc;
// use sysinfo::{ProcessRefreshKind, RefreshKind, System};
use tokio::sync::RwLock;
use tracing::{error, info, warn};

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ServiceConfig {
    name: String,
    command: String,
    args: Vec<String>,
    working_dir: Option<String>,
    auto_restart: bool,
    max_restarts: u32,
    health_check_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ServiceStatus {
    name: String,
    status: String, // running, stopped, failed
    pid: Option<u32>,
    uptime_seconds: Option<u64>,
    restarts: u32,
    last_started: Option<String>,
    last_error: Option<String>,
}

#[derive(Debug)]
struct ManagedService {
    config: ServiceConfig,
    child: Option<Child>,
    status: ServiceStatus,
    started_at: Option<std::time::Instant>,
}

struct AppState {
    services: Arc<RwLock<HashMap<String, ManagedService>>>,
}

// ============================================================================
// Service Management
// ============================================================================

impl AppState {
    async fn start_service(&self, name: &str) -> Result<(), String> {
        let mut services = self.services.write().await;

        let service = services
            .get_mut(name)
            .ok_or_else(|| format!("Service {} not found", name))?;

        if service.child.is_some() {
            return Err(format!("Service {} is already running", name));
        }

        info!("Starting service: {}", name);

        let mut cmd = Command::new(&service.config.command);
        cmd.args(&service.config.args);

        if let Some(dir) = &service.config.working_dir {
            cmd.current_dir(dir);
        }

        match cmd.spawn() {
            Ok(child) => {
                let pid = child.id();
                service.child = Some(child);
                service.status.status = "running".to_string();
                service.status.pid = Some(pid);
                service.status.last_started = Some(chrono::Utc::now().to_rfc3339());
                service.started_at = Some(std::time::Instant::now());

                info!("Service {} started with PID {}", name, pid);
                Ok(())
            }
            Err(e) => {
                let error_msg = format!("Failed to start {}: {}", name, e);
                error!("{}", error_msg);
                service.status.status = "failed".to_string();
                service.status.last_error = Some(error_msg.clone());
                Err(error_msg)
            }
        }
    }

    async fn stop_service(&self, name: &str) -> Result<(), String> {
        let mut services = self.services.write().await;

        let service = services
            .get_mut(name)
            .ok_or_else(|| format!("Service {} not found", name))?;

        if let Some(mut child) = service.child.take() {
            info!("Stopping service: {}", name);

            match child.kill() {
                Ok(_) => {
                    service.status.status = "stopped".to_string();
                    service.status.pid = None;
                    service.started_at = None;
                    info!("Service {} stopped", name);
                    Ok(())
                }
                Err(e) => {
                    let error_msg = format!("Failed to stop {}: {}", name, e);
                    error!("{}", error_msg);
                    Err(error_msg)
                }
            }
        } else {
            Err(format!("Service {} is not running", name))
        }
    }

    async fn restart_service(&self, name: &str) -> Result<(), String> {
        self.stop_service(name).await.ok(); // Ignore error if not running
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        self.start_service(name).await
    }

    async fn check_services(&self) {
        let mut services = self.services.write().await;

        for (name, service) in services.iter_mut() {
            if let Some(ref mut child) = service.child {
                match child.try_wait() {
                    Ok(Some(_status)) => {
                        // Process exited
                        warn!("Service {} exited unexpectedly", name);
                        service.status.status = "stopped".to_string();
                        service.child = None;
                        service.status.pid = None;

                        // Auto-restart if enabled
                        if service.config.auto_restart
                            && service.status.restarts < service.config.max_restarts
                        {
                            service.status.restarts += 1;
                            info!(
                                "Auto-restarting {} (attempt {}/{})",
                                name, service.status.restarts, service.config.max_restarts
                            );
                            // Will restart on next check
                        }
                    }
                    Ok(None) => {
                        // Still running - update uptime
                        if let Some(started) = service.started_at {
                            service.status.uptime_seconds =
                                Some(started.elapsed().as_secs());
                        }
                    }
                    Err(e) => {
                        error!("Error checking service {}: {}", name, e);
                    }
                }
            } else if service.config.auto_restart
                && service.status.restarts < service.config.max_restarts
                && service.status.status == "stopped"
            {
                // Try to restart
                info!("Attempting to restart {}", name);
                service.status.restarts += 1;
            }
        }
    }
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Service Manager: ONLINE")
}

async fn list_services(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let services = state.services.read().await;
    let statuses: Vec<ServiceStatus> = services
        .values()
        .map(|s| s.status.clone())
        .collect();

    Json(statuses)
}

#[derive(Deserialize)]
struct ServiceAction {
    name: String,
}

async fn start_service_handler(
    State(state): State<Arc<AppState>>,
    Json(action): Json<ServiceAction>,
) -> impl IntoResponse {
    match state.start_service(&action.name).await {
        Ok(_) => (
            StatusCode::OK,
            Json(serde_json::json!({"success": true})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"success": false, "error": e})),
        ),
    }
}

async fn stop_service_handler(
    State(state): State<Arc<AppState>>,
    Json(action): Json<ServiceAction>,
) -> impl IntoResponse {
    match state.stop_service(&action.name).await {
        Ok(_) => (
            StatusCode::OK,
            Json(serde_json::json!({"success": true})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"success": false, "error": e})),
        ),
    }
}

async fn restart_service_handler(
    State(state): State<Arc<AppState>>,
    Json(action): Json<ServiceAction>,
) -> impl IntoResponse {
    match state.restart_service(&action.name).await {
        Ok(_) => (
            StatusCode::OK,
            Json(serde_json::json!({"success": true})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"success": false, "error": e})),
        ),
    }
}

// ============================================================================
// Background Tasks
// ============================================================================

async fn monitor_services(state: Arc<AppState>) {
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(10));

    loop {
        interval.tick().await;
        state.check_services().await;
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Service Manager");


    // Initialize services (from config file later)
    let mut services = HashMap::new();

    // Example: Prompt Security Controller
    services.insert(
        "prompt-security".to_string(),
        ManagedService {
            config: ServiceConfig {
                name: "prompt-security".to_string(),
                command: "/home/admin/WORKSPACE/projects/ACTIVE/codriver/src/controller/prompt-controller/target/release/prompt-security-controller".to_string(),
                args: vec![],
                working_dir: None,
                auto_restart: true,
                max_restarts: 5,
                health_check_url: Some("http://127.0.0.1:9001/health".to_string()),
            },
            child: None,
            status: ServiceStatus {
                name: "prompt-security".to_string(),
                status: "stopped".to_string(),
                pid: None,
                uptime_seconds: None,
                restarts: 0,
                last_started: None,
                last_error: None,
            },
            started_at: None,
        },
    );

    let state = Arc::new(AppState {
        services: Arc::new(RwLock::new(services)),
    });

    // Start monitoring task
    let monitor_state = Arc::clone(&state);
    tokio::spawn(async move {
        monitor_services(monitor_state).await;
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/services", get(list_services))
        .route("/services/start", post(start_service_handler))
        .route("/services/stop", post(stop_service_handler))
        .route("/services/restart", post(restart_service_handler))
        .with_state(state);

    let addr = "127.0.0.1:9000";
    info!("Service Manager listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
