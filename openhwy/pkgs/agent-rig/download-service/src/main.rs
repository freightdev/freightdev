use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use serde::Deserialize;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Clone)]
struct AppState {
    binaries_path: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "download_service=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    dotenvy::dotenv().ok();

    let binaries_path = std::env::var("BINARIES_PATH")
        .unwrap_or_else(|_| "./binaries".to_string());

    let state = AppState { binaries_path };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/download/:app", get(download_app))
        .layer(cors)
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8005));
    tracing::info!("🚀 Download Service listening on {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "Download Service - Healthy ✅"
}

#[derive(Deserialize)]
struct DownloadQuery {
    platform: Option<String>,
}

async fn download_app(
    State(state): State<AppState>,
    Path(app): Path<String>,
    Query(params): Query<DownloadQuery>,
    headers: HeaderMap,
) -> Result<Response, StatusCode> {
    // Validate app name
    if app != "dispatcher" && app != "driver" {
        return Err(StatusCode::NOT_FOUND);
    }

    // Determine platform
    let platform = params.platform.unwrap_or_else(|| {
        // Try to detect from User-Agent
        if let Some(ua) = headers.get("user-agent") {
            let ua_str = ua.to_str().unwrap_or("");
            if ua_str.contains("Windows") {
                "windows".to_string()
            } else if ua_str.contains("Mac") {
                "macos".to_string()
            } else if ua_str.contains("Linux") {
                "linux".to_string()
            } else if ua_str.contains("Android") {
                "android".to_string()
            } else if ua_str.contains("iPhone") || ua_str.contains("iPad") {
                "ios".to_string()
            } else {
                "unknown".to_string()
            }
        } else {
            "unknown".to_string()
        }
    });

    // Determine file extension and name
    let (filename, content_type) = match (app.as_str(), platform.as_str()) {
        ("dispatcher", "windows") => ("hwy-tms-dispatcher-windows.exe", "application/octet-stream"),
        ("dispatcher", "macos") => ("hwy-tms-dispatcher-macos.dmg", "application/x-apple-diskimage"),
        ("dispatcher", "linux") => ("hwy-tms-dispatcher-linux.AppImage", "application/octet-stream"),
        ("driver", "android") => ("hwy-tms-driver.apk", "application/vnd.android.package-archive"),
        ("driver", "ios") => ("hwy-tms-driver.ipa", "application/octet-stream"),
        _ => return Err(StatusCode::BAD_REQUEST),
    };

    let file_path = format!("{}/{}", state.binaries_path, filename);

    // Check if file exists
    if !std::path::Path::new(&file_path).exists() {
        tracing::warn!("File not found: {}", file_path);
        return Err(StatusCode::NOT_FOUND);
    }

    // Read file
    let file_data = tokio::fs::read(&file_path)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    tracing::info!("📦 Serving {} for {}", filename, platform);

    // Return file with appropriate headers
    Ok((
        StatusCode::OK,
        [
            ("Content-Type", content_type),
            ("Content-Disposition", &format!("attachment; filename=\"{}\"", filename)),
        ],
        file_data,
    )
        .into_response())
}
