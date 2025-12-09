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
pub struct ConversationQuery {
    pub search: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router {
    Router::new()
        .route("/", get(get_conversations).post(create_conversation))
        .route("/:id", get(get_conversation).delete(delete_conversation))
        .route("/:id/messages", get(get_messages).post(send_message))
        .route(
            "/:conversation_id/messages/:message_id/read",
            patch(mark_as_read),
        )
        .route("/:id/read", patch(mark_conversation_as_read))
        .route("/unread-count", get(get_unread_count))
}

async fn get_conversations(
    Query(_params): Query<ConversationQuery>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [], "total": 0 })))
}

async fn get_conversation(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "name": "Conversation", "type": "direct" }),
    ))
}

async fn create_conversation(
    Json(_payload): Json<Value>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    Ok((
        StatusCode::CREATED,
        Json(json!({ "id": Uuid::new_v4(), "name": "New Conversation" })),
    ))
}

async fn delete_conversation(Path(id): Path<Uuid>) -> StatusCode {
    tracing::info!("Delete conversation: {}", id);
    StatusCode::NO_CONTENT
}

async fn get_messages(Path(_conversation_id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [] })))
}

async fn send_message(
    Path(_conversation_id): Path<Uuid>,
    Json(_payload): Json<Value>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    Ok((
        StatusCode::CREATED,
        Json(json!({ "id": Uuid::new_v4(), "content": "Message sent" })),
    ))
}

async fn mark_as_read(Path((_conversation_id, _message_id)): Path<(Uuid, Uuid)>) -> StatusCode {
    StatusCode::OK
}

async fn mark_conversation_as_read(Path(_id): Path<Uuid>) -> StatusCode {
    StatusCode::OK
}

async fn get_unread_count() -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "count": 3 })))
}
