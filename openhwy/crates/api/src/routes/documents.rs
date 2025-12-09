use axum::{
    extract::{Path, Query},
    http::StatusCode,
    routing::{delete, get, patch, post},
    Json, Router,
};
use serde::Deserialize;
use serde_json::{json, Value};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct DocumentQuery {
    pub search: Option<String>,
    pub document_type: Option<String>,
    pub status: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router {
    Router::new()
        .route("/", get(get_documents).post(upload_document))
        .route(
            "/:id",
            get(get_document)
                .patch(update_document)
                .delete(delete_document),
        )
        .route("/:id/status", patch(update_status))
        .route("/expiring", get(get_expiring_documents))
        .route("/:id/download", get(download_document))
        .route("/stats", get(get_stats))
}

async fn get_documents(Query(_params): Query<DocumentQuery>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [] })))
}

async fn get_document(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "name": "Document", "type": "license", "status": "verified" }),
    ))
}

async fn upload_document(
    Json(_payload): Json<Value>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    Ok((
        StatusCode::CREATED,
        Json(json!({ "id": Uuid::new_v4(), "name": "Uploaded Document" })),
    ))
}

async fn update_document(
    Path(id): Path<Uuid>,
    Json(_payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "id": id, "updated_at": chrono::Utc::now() })))
}

async fn delete_document(Path(id): Path<Uuid>) -> StatusCode {
    tracing::info!("Delete document: {}", id);
    StatusCode::NO_CONTENT
}

async fn update_status(
    Path(id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "status": payload.get("status"), "updated_at": chrono::Utc::now() }),
    ))
}

async fn get_expiring_documents(Query(_params): Query<Value>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [] })))
}

async fn download_document(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "download_url": format!("/downloads/{}", id) }),
    ))
}

async fn get_stats() -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "total": 347, "verified": 289, "pending": 42, "expired": 16 }),
    ))
}
