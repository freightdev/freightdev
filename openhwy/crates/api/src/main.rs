use axum::{routing::get, Router};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod middleware;
mod models;
mod routes;
mod services;
mod utils;

use services::surreal_service::SurrealService;

use routes::{auth, documents, drivers, invoices, loads, messages, payments};

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "hwy_tms_api=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();

    // Build CORS layer
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    if let Err(err) = SurrealService::initialize().await {
        tracing::error!(?err, "SurrealDB metadata store initialization failed");
    }

    // Build application routes
    let app = Router::new()
        .route("/", get(health_check))
        .route("/health", get(health_check))
        // Auth routes
        .nest("/api/auth", auth::router())
        // Resource routes
        .nest("/api/loads", loads::router())
        .nest("/api/drivers", drivers::router())
        .nest("/api/invoices", invoices::router())
        .nest("/api/payments", payments::router())
        .nest("/api/conversations", messages::router())
        .nest("/api/documents", documents::router())
        // Add CORS
        .layer(cors);

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("HWY-TMS API listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> &'static str {
    "HWY-TMS API is running"
}
