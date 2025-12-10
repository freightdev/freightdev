use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod ca;
mod db;
mod handlers;
mod ip_allocator;
mod models;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "connection_service=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();

    // Initialize database connection
    let db = db::init_db().await?;
    tracing::info!("✅ Connected to SurrealDB");

    // Initialize or load CA keys
    ca::init_ca().await?;
    tracing::info!("✅ CA initialized");

    // Setup CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Build router
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/cert/issue", post(handlers::issue_cert))
        .route("/cert/revoke", post(handlers::revoke_cert))
        .route("/cert/verify", post(handlers::verify_cert))
        .layer(cors)
        .with_state(db);

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8003));
    tracing::info!("🚀 Nebula CA Service listening on {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "Nebula CA Service - Healthy ✅"
}
