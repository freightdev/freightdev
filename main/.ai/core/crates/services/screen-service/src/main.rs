// Screen Controller Agent
// Controls Hyprland windows, workspaces, and captures screenshots

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::process::Command;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info};
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WindowInfo {
    address: String,
    class: String,
    title: String,
    workspace: i32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WorkspaceInfo {
    id: i32,
    name: String,
    monitor: String,
    windows: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScreenshotRequest {
    output_path: Option<String>,
    format: Option<String>, // png, jpg
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScreenshotResult {
    id: String,
    path: String,
    width: u32,
    height: u32,
    format: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WindowCommand {
    command: String, // move, resize, close, focus, fullscreen
    target: Option<String>, // window address or class
    params: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LaunchRequest {
    app: String,
    args: Vec<String>,
    workspace: Option<i32>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    screenshots: Arc<RwLock<Vec<ScreenshotResult>>>,
}

// ============================================================================
// Hyprland Control Functions
// ============================================================================

async fn get_windows() -> Result<Vec<WindowInfo>, String> {
    let output = Command::new("hyprctl")
        .args(&["clients", "-j"])
        .output()
        .map_err(|e| format!("Failed to execute hyprctl: {}", e))?;

    if !output.status.success() {
        return Err(format!("hyprctl failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    let windows: Vec<WindowInfo> = serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("Failed to parse window info: {}", e))?;

    Ok(windows)
}

async fn get_workspaces() -> Result<Vec<WorkspaceInfo>, String> {
    let output = Command::new("hyprctl")
        .args(&["workspaces", "-j"])
        .output()
        .map_err(|e| format!("Failed to execute hyprctl: {}", e))?;

    if !output.status.success() {
        return Err(format!("hyprctl failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    let workspaces: Vec<WorkspaceInfo> = serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("Failed to parse workspace info: {}", e))?;

    Ok(workspaces)
}

async fn switch_workspace(workspace_id: i32) -> Result<(), String> {
    let output = Command::new("hyprctl")
        .args(&["dispatch", "workspace", &workspace_id.to_string()])
        .output()
        .map_err(|e| format!("Failed to execute hyprctl: {}", e))?;

    if !output.status.success() {
        return Err(format!("Failed to switch workspace: {}", String::from_utf8_lossy(&output.stderr)));
    }

    Ok(())
}

async fn execute_window_command(cmd: &WindowCommand) -> Result<String, String> {
    let mut command = Command::new("hyprctl");
    command.arg("dispatch");

    match cmd.command.as_str() {
        "close" => {
            command.arg("killactive");
        }
        "fullscreen" => {
            command.arg("fullscreen");
        }
        "move" => {
            if let Some(params) = &cmd.params {
                if let Some(workspace) = params.get("workspace") {
                    command.arg("movetoworkspace");
                    command.arg(workspace.as_i64().unwrap_or(1).to_string());
                }
            }
        }
        "resize" => {
            command.arg("resizeactive");
            if let Some(params) = &cmd.params {
                let width = params.get("width").and_then(|v| v.as_i64()).unwrap_or(0);
                let height = params.get("height").and_then(|v| v.as_i64()).unwrap_or(0);
                command.arg(width.to_string());
                command.arg(height.to_string());
            }
        }
        "focus" => {
            if let Some(target) = &cmd.target {
                command.arg("focuswindow");
                command.arg(target);
            }
        }
        _ => {
            return Err(format!("Unknown command: {}", cmd.command));
        }
    }

    let output = command.output()
        .map_err(|e| format!("Failed to execute command: {}", e))?;

    if !output.status.success() {
        return Err(format!("Command failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

async fn launch_application(req: &LaunchRequest) -> Result<String, String> {
    // Build launch command
    let mut cmd = Command::new(&req.app);
    cmd.args(&req.args);

    // Spawn the process
    let child = cmd.spawn()
        .map_err(|e| format!("Failed to launch app: {}", e))?;

    let pid = child.id();

    // Optionally move to workspace
    if let Some(workspace) = req.workspace {
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
        switch_workspace(workspace).await.ok();
    }

    Ok(format!("Launched {} with PID {}", req.app, pid))
}

async fn capture_screenshot(req: &ScreenshotRequest) -> Result<ScreenshotResult, String> {
    let format = req.format.as_deref().unwrap_or("png");
    let filename = format!("screenshot-{}.{}", Uuid::new_v4(), format);
    let path = req.output_path.as_ref()
        .map(|p| format!("{}/{}", p, filename))
        .unwrap_or_else(|| format!("/tmp/{}", filename));

    // Use grim for Wayland screenshots
    let output = Command::new("grim")
        .arg(&path)
        .output()
        .map_err(|e| format!("Failed to capture screenshot: {}", e))?;

    if !output.status.success() {
        return Err(format!("Screenshot failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    // Get image dimensions (simplified - would use actual image reading)
    let result = ScreenshotResult {
        id: Uuid::new_v4().to_string(),
        path: path.clone(),
        width: 1920, // Would read from actual image
        height: 1080,
        format: format.to_string(),
    };

    info!("Screenshot saved: {}", path);

    Ok(result)
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Screen Controller: ONLINE")
}

async fn list_windows() -> impl IntoResponse {
    match get_windows().await {
        Ok(windows) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "windows": windows
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

async fn list_workspaces() -> impl IntoResponse {
    match get_workspaces().await {
        Ok(workspaces) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "workspaces": workspaces
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

#[derive(Deserialize)]
struct WorkspaceRequest {
    id: i32,
}

async fn switch_workspace_handler(Json(req): Json<WorkspaceRequest>) -> impl IntoResponse {
    match switch_workspace(req.id).await {
        Ok(_) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

async fn window_command_handler(Json(cmd): Json<WindowCommand>) -> impl IntoResponse {
    match execute_window_command(&cmd).await {
        Ok(result) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "result": result
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

async fn launch_handler(Json(req): Json<LaunchRequest>) -> impl IntoResponse {
    match launch_application(&req).await {
        Ok(result) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "result": result
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

async fn screenshot_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<ScreenshotRequest>,
) -> impl IntoResponse {
    match capture_screenshot(&req).await {
        Ok(result) => {
            let mut screenshots = state.screenshots.write().await;
            screenshots.push(result.clone());

            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "screenshot": result
                })),
            )
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": e
            })),
        ),
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Screen Controller");

    let state = Arc::new(AppState {
        screenshots: Arc::new(RwLock::new(Vec::new())),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/windows", get(list_windows))
        .route("/workspaces", get(list_workspaces))
        .route("/workspace/switch", post(switch_workspace_handler))
        .route("/window/command", post(window_command_handler))
        .route("/launch", post(launch_handler))
        .route("/screenshot", post(screenshot_handler))
        .with_state(state);

    let addr = "127.0.0.1:9005";
    info!("Screen Controller listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
