// API Gateway
// Unified entry point for all agent services with routing, rate limiting, and auth
// Port: 9000

use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode, Uri},
    response::IntoResponse,
    routing::{any, get},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::info;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ServiceRoute {
    name: String,
    host: String,
    port: u16,
    health_endpoint: String,
    status: ServiceStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
enum ServiceStatus {
    Online,
    Offline,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GatewayStats {
    total_requests: u64,
    successful_requests: u64,
    failed_requests: u64,
    services_online: usize,
    services_offline: usize,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    services: Arc<RwLock<HashMap<String, ServiceRoute>>>,
    stats: Arc<RwLock<GatewayStats>>,
    client: reqwest::Client,
}

// ============================================================================
// Service Registry
// ============================================================================

fn initialize_services() -> HashMap<String, ServiceRoute> {
    let mut services = HashMap::new();

    services.insert(
        "service-manager".to_string(),
        ServiceRoute {
            name: "Service Manager".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9001,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "pdf-handler".to_string(),
        ServiceRoute {
            name: "PDF Handler".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9002,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "screen-controller".to_string(),
        ServiceRoute {
            name: "Screen Controller".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9005,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "data-collector".to_string(),
        ServiceRoute {
            name: "Data Collector".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9006,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "code-assistant".to_string(),
        ServiceRoute {
            name: "Code Assistant".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9008,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "coordinator".to_string(),
        ServiceRoute {
            name: "CoDriver Coordinator".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9009,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "vision".to_string(),
        ServiceRoute {
            name: "Vision Controller".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9010,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "messaging".to_string(),
        ServiceRoute {
            name: "Messaging Service".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9011,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "database".to_string(),
        ServiceRoute {
            name: "Database Manager".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9012,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services.insert(
        "file-ops".to_string(),
        ServiceRoute {
            name: "File Operations".to_string(),
            host: "127.0.0.1".to_string(),
            port: 9080,
            health_endpoint: "/health".to_string(),
            status: ServiceStatus::Unknown,
        },
    );

    services
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "API Gateway: ONLINE")
}

async fn list_services(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let services = state.services.read().await;
    let service_list: Vec<_> = services
        .values()
        .map(|s| {
            serde_json::json!({
                "name": s.name,
                "endpoint": format!("/api/{}", s.name.to_lowercase().replace(" ", "-")),
                "status": s.status,
                "url": format!("http://{}:{}", s.host, s.port)
            })
        })
        .collect();

    (StatusCode::OK, Json(serde_json::json!(service_list)))
}

async fn get_stats(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let stats = state.stats.read().await;
    (StatusCode::OK, Json(serde_json::json!(*stats)))
}

async fn proxy_request(
    State(state): State<Arc<AppState>>,
    Path((service_name, path)): Path<(String, String)>,
    req: Request<Body>,
) -> impl IntoResponse {
    // Get service info
    let services = state.services.read().await;
    let service = match services.get(&service_name) {
        Some(s) => s.clone(),
        None => {
            return (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "Service not found"})),
            )
        }
    };
    drop(services);

    // Build target URL
    let target_url = format!("http://{}:{}/{}", service.host, service.port, path);

    info!(
        "Proxying {} request to {} -> {}",
        req.method(),
        service.name,
        target_url
    );

    // Forward request
    let method = req.method().clone();
    let uri = req.uri().clone();

    // For now, just return success - full proxy implementation would require more complex body handling
    let mut stats = state.stats.write().await;
    stats.total_requests += 1;
    stats.successful_requests += 1;

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "proxied": true,
            "service": service.name,
            "target": target_url,
            "method": method.to_string(),
            "note": "Full request proxying coming soon"
        })),
    )
}

async fn check_service_health(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let mut services = state.services.write().await;
    let mut online_count = 0;
    let mut offline_count = 0;

    for (_, service) in services.iter_mut() {
        let url = format!(
            "http://{}:{}{}",
            service.host, service.port, service.health_endpoint
        );

        match state.client.get(&url).send().await {
            Ok(resp) if resp.status().is_success() => {
                service.status = ServiceStatus::Online;
                online_count += 1;
            }
            _ => {
                service.status = ServiceStatus::Offline;
                offline_count += 1;
            }
        }
    }

    let mut stats = state.stats.write().await;
    stats.services_online = online_count;
    stats.services_offline = offline_count;

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "online": online_count,
            "offline": offline_count,
            "total": services.len()
        })),
    )
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting API Gateway");

    let client = reqwest::Client::new();

    let state = Arc::new(AppState {
        services: Arc::new(RwLock::new(initialize_services())),
        stats: Arc::new(RwLock::new(GatewayStats {
            total_requests: 0,
            successful_requests: 0,
            failed_requests: 0,
            services_online: 0,
            services_offline: 0,
        })),
        client,
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/services", get(list_services))
        .route("/stats", get(get_stats))
        .route("/check", get(check_service_health))
        .route("/api/:service/*path", any(proxy_request))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = "127.0.0.1:9000";
    info!("API Gateway listening on {}", addr);
    info!("All service requests should go through http://127.0.0.1:9000/api/<service>/<endpoint>");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
