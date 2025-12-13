use crate::auth::AuthUser;
use crate::storage::{AppState, FileMetadata};
use axum::{
    extract::{Multipart, Path, State},
    http::{header, StatusCode},
    response::IntoResponse,
    Json,
};
use serde_json::json;
use tracing::{debug, error};

pub async fn upload_file(
    State(state): State<AppState>,
    auth: AuthUser,
    mut multipart: Multipart,
) -> Result<Json<FileMetadata>, (StatusCode, Json<serde_json::Value>)> {
    while let Some(field) = multipart.next_field().await.map_err(|e| {
        error!("Failed to read multipart field: {}", e);
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invalid multipart data"})),
        )
    })? {
        let filename = field
            .file_name()
            .ok_or_else(|| {
                (
                    StatusCode::BAD_REQUEST,
                    Json(json!({"error": "Missing filename"})),
                )
            })?
            .to_string();

        let content_type = field
            .content_type()
            .unwrap_or("application/octet-stream")
            .to_string();

        let data = field.bytes().await.map_err(|e| {
            error!("Failed to read file data: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Failed to read file data"})),
            )
        })?;

        debug!(
            "Uploading file: {} ({} bytes, type: {})",
            filename,
            data.len(),
            content_type
        );

        let metadata = state
            .save_file(&auth.user_id, &filename, &content_type, &data)
            .await
            .map_err(|e| {
                error!("Failed to save file: {}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(json!({"error": e.to_string()})),
                )
            })?;

        return Ok(Json(metadata));
    }

    Err((
        StatusCode::BAD_REQUEST,
        Json(json!({"error": "No file provided"})),
    ))
}

pub async fn get_file(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {
    let (metadata, data) = state.get_file(&file_id).await.map_err(|e| {
        error!("Failed to get file: {}", e);
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "File not found"})),
        )
    })?;

    Ok((
        [(header::CONTENT_TYPE, metadata.content_type)],
        data,
    ))
}

pub async fn get_file_metadata(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
) -> Result<Json<FileMetadata>, (StatusCode, Json<serde_json::Value>)> {
    let metadata = state.get_metadata(&file_id).await.map_err(|e| {
        error!("Failed to get metadata: {}", e);
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "File not found"})),
        )
    })?;

    Ok(Json(metadata))
}

pub async fn delete_file(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(file_id): Path<String>,
) -> Result<StatusCode, (StatusCode, Json<serde_json::Value>)> {
    state
        .delete_file(&file_id, &auth.user_id)
        .await
        .map_err(|e| {
            error!("Failed to delete file: {}", e);
            (
                StatusCode::FORBIDDEN,
                Json(json!({"error": e.to_string()})),
            )
        })?;

    Ok(StatusCode::NO_CONTENT)
}

pub async fn list_user_files(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<Vec<FileMetadata>>, (StatusCode, Json<serde_json::Value>)> {
    if auth.user_id != user_id {
        return Err((
            StatusCode::FORBIDDEN,
            Json(json!({"error": "Unauthorized"})),
        ));
    }

    let files = state.list_user_files(&user_id).await.map_err(|e| {
        error!("Failed to list files: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": e.to_string()})),
        )
    })?;

    Ok(Json(files))
}
