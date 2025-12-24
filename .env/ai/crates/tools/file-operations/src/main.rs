// File Operations Agent
// Handles read, write, execute, and filesystem operations for the AI agency
// Port: 9014

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::process::Command as StdCommand;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::{error, info, warn};
use walkdir::WalkDir;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Deserialize)]
struct ReadRequest {
    path: String,
    max_lines: Option<usize>,
}

#[derive(Debug, Serialize)]
struct ReadResponse {
    success: bool,
    content: Option<String>,
    error: Option<String>,
    lines: Option<usize>,
}

#[derive(Debug, Deserialize)]
struct WriteRequest {
    path: String,
    content: String,
    append: Option<bool>,
}

#[derive(Debug, Serialize)]
struct WriteResponse {
    success: bool,
    bytes_written: Option<usize>,
    error: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ExecuteRequest {
    command: String,
    args: Option<Vec<String>>,
    working_dir: Option<String>,
    timeout_seconds: Option<u64>,
}

#[derive(Debug, Serialize)]
struct ExecuteResponse {
    success: bool,
    stdout: Option<String>,
    stderr: Option<String>,
    exit_code: Option<i32>,
    error: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ListRequest {
    path: String,
    recursive: Option<bool>,
    max_depth: Option<usize>,
}

#[derive(Debug, Serialize)]
struct ListResponse {
    success: bool,
    entries: Option<Vec<FileEntry>>,
    error: Option<String>,
}

#[derive(Debug, Serialize)]
struct FileEntry {
    path: String,
    is_dir: bool,
    size: Option<u64>,
}

struct AppState {}

// ============================================================================
// File Operations
// ============================================================================

async fn read_file(path: &str, max_lines: Option<usize>) -> Result<String, String> {
    let path = Path::new(path);

    if !path.exists() {
        return Err(format!("File not found: {}", path.display()));
    }

    match tokio::fs::read_to_string(path).await {
        Ok(content) => {
            if let Some(max) = max_lines {
                let lines: Vec<&str> = content.lines().take(max).collect();
                Ok(lines.join("\n"))
            } else {
                Ok(content)
            }
        }
        Err(e) => Err(format!("Failed to read file: {}", e)),
    }
}

async fn write_file(path: &str, content: &str, append: bool) -> Result<usize, String> {
    let path = Path::new(path);

    // Create parent directories if they don't exist
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            tokio::fs::create_dir_all(parent)
                .await
                .map_err(|e| format!("Failed to create directories: {}", e))?;
        }
    }

    if append {
        let mut existing = tokio::fs::read_to_string(path)
            .await
            .unwrap_or_default();
        existing.push_str(content);

        tokio::fs::write(path, &existing)
            .await
            .map_err(|e| format!("Failed to write file: {}", e))?;

        Ok(existing.len())
    } else {
        tokio::fs::write(path, content)
            .await
            .map_err(|e| format!("Failed to write file: {}", e))?;

        Ok(content.len())
    }
}

async fn execute_command(
    command: &str,
    args: Option<Vec<String>>,
    working_dir: Option<String>,
    timeout_seconds: Option<u64>,
) -> Result<(String, String, i32), String> {
    info!("Executing command: {} {:?}", command, args);

    let mut cmd = StdCommand::new(command);

    if let Some(args_vec) = args {
        cmd.args(args_vec);
    }

    if let Some(dir) = working_dir {
        cmd.current_dir(dir);
    }

    let timeout = std::time::Duration::from_secs(timeout_seconds.unwrap_or(60));

    match tokio::time::timeout(
        timeout,
        tokio::task::spawn_blocking(move || cmd.output()),
    )
    .await
    {
        Ok(Ok(Ok(output))) => {
            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            let exit_code = output.status.code().unwrap_or(-1);

            Ok((stdout, stderr, exit_code))
        }
        Ok(Ok(Err(e))) => Err(format!("Failed to execute command: {}", e)),
        Ok(Err(e)) => Err(format!("Task join error: {}", e)),
        Err(_) => Err("Command execution timed out".to_string()),
    }
}

fn list_directory(
    path: &str,
    recursive: bool,
    max_depth: Option<usize>,
) -> Result<Vec<FileEntry>, String> {
    let path = Path::new(path);

    if !path.exists() {
        return Err(format!("Path not found: {}", path.display()));
    }

    let mut entries = Vec::new();

    if recursive {
        let walker = if let Some(depth) = max_depth {
            WalkDir::new(path).max_depth(depth)
        } else {
            WalkDir::new(path)
        };

        for entry in walker.into_iter().filter_map(|e| e.ok()) {
            let metadata = entry.metadata().ok();
            entries.push(FileEntry {
                path: entry.path().display().to_string(),
                is_dir: entry.file_type().is_dir(),
                size: metadata.map(|m| m.len()),
            });
        }
    } else {
        let read_dir = std::fs::read_dir(path)
            .map_err(|e| format!("Failed to read directory: {}", e))?;

        for entry in read_dir.filter_map(|e| e.ok()) {
            let metadata = entry.metadata().ok();
            let is_dir = metadata.as_ref().map(|m| m.is_dir()).unwrap_or(false);
            entries.push(FileEntry {
                path: entry.path().display().to_string(),
                is_dir,
                size: metadata.map(|m| m.len()),
            });
        }
    }

    Ok(entries)
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "File Operations Agent: ONLINE")
}

async fn read_handler(
    State(_state): State<Arc<AppState>>,
    Json(req): Json<ReadRequest>,
) -> impl IntoResponse {
    info!("Read request: {}", req.path);

    match read_file(&req.path, req.max_lines).await {
        Ok(content) => {
            let lines = content.lines().count();
            Json(ReadResponse {
                success: true,
                content: Some(content),
                error: None,
                lines: Some(lines),
            })
        }
        Err(e) => {
            error!("Read failed: {}", e);
            Json(ReadResponse {
                success: false,
                content: None,
                error: Some(e),
                lines: None,
            })
        }
    }
}

async fn write_handler(
    State(_state): State<Arc<AppState>>,
    Json(req): Json<WriteRequest>,
) -> impl IntoResponse {
    info!("Write request: {} ({} bytes)", req.path, req.content.len());

    match write_file(&req.path, &req.content, req.append.unwrap_or(false)).await {
        Ok(bytes) => Json(WriteResponse {
            success: true,
            bytes_written: Some(bytes),
            error: None,
        }),
        Err(e) => {
            error!("Write failed: {}", e);
            Json(WriteResponse {
                success: true,
                bytes_written: None,
                error: Some(e),
            })
        }
    }
}

async fn execute_handler(
    State(_state): State<Arc<AppState>>,
    Json(req): Json<ExecuteRequest>,
) -> impl IntoResponse {
    warn!("Execute request: {} {:?}", req.command, req.args);

    match execute_command(&req.command, req.args, req.working_dir, req.timeout_seconds).await {
        Ok((stdout, stderr, exit_code)) => Json(ExecuteResponse {
            success: exit_code == 0,
            stdout: Some(stdout),
            stderr: Some(stderr),
            exit_code: Some(exit_code),
            error: None,
        }),
        Err(e) => {
            error!("Execute failed: {}", e);
            Json(ExecuteResponse {
                success: false,
                stdout: None,
                stderr: None,
                exit_code: None,
                error: Some(e),
            })
        }
    }
}

async fn list_handler(
    State(_state): State<Arc<AppState>>,
    Json(req): Json<ListRequest>,
) -> impl IntoResponse {
    info!("List request: {}", req.path);

    match list_directory(&req.path, req.recursive.unwrap_or(false), req.max_depth) {
        Ok(entries) => Json(ListResponse {
            success: true,
            entries: Some(entries),
            error: None,
        }),
        Err(e) => {
            error!("List failed: {}", e);
            Json(ListResponse {
                success: false,
                entries: None,
                error: Some(e),
            })
        }
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting File Operations Agent");

    let state = Arc::new(AppState {});

    let app = Router::new()
        .route("/health", get(health))
        .route("/read", post(read_handler))
        .route("/write", post(write_handler))
        .route("/execute", post(execute_handler))
        .route("/list", post(list_handler))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = "127.0.0.1:9014";
    info!("File Operations Agent listening on {}", addr);
    info!("Endpoints:");
    info!("  POST /read - Read file contents");
    info!("  POST /write - Write file contents");
    info!("  POST /execute - Execute commands");
    info!("  POST /list - List directory contents");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
