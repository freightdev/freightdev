mod auth;
mod routes;
mod storage;

use anyhow::Result;
use axum::{
    http::{header, Method, StatusCode},
    routing::{delete, get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<()> {
    dotenv::dotenv().ok();

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "upload_service=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    let upload_dir = std::env::var("UPLOAD_DIR").unwrap_or_else(|_| "./uploads".to_string());
    let max_file_size: usize = std::env::var("MAX_FILE_SIZE")
        .unwrap_or_else(|_| "52428800".to_string()) // 50MB default
        .parse()?;

    let state = storage::AppState::new(upload_dir, max_file_size).await?;

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::DELETE, Method::OPTIONS])
        .allow_headers([header::AUTHORIZATION, header::CONTENT_TYPE]);

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/upload", post(routes::upload_file))
        .route("/files/:file_id", get(routes::get_file))
        .route("/files/:file_id", delete(routes::delete_file))
        .route("/files/:file_id/metadata", get(routes::get_file_metadata))
        .route("/files/user/:user_id", get(routes::list_user_files))
        .with_state(state)
        .layer(cors);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8006));
    info!("Upload service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> StatusCode {
    StatusCode::OK
}
