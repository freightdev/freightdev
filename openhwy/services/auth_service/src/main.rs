use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod db;
mod errors;
mod handlers;
mod jwt;
mod models;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "auth_service=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();

    // Initialize database connection
    let db = db::init_db().await?;
    tracing::info!("✅ Connected to SurrealDB");

    // Setup CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Build router
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/auth/signup", post(handlers::signup))
        .route("/auth/login", post(handlers::login))
        .route("/auth/validate", get(handlers::validate))
        .route("/auth/refresh", post(handlers::refresh))
        .layer(cors)
        .with_state(db);

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8001));
    tracing::info!("🚀 Torii Auth Service listening on {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "Torii Auth Service - Healthy ✅"
}
