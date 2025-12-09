use axum::{
    extract::{Path, Query},
    http::StatusCode,
    routing::{delete, get, patch, post},
    Json, Router,
};
use serde::Deserialize;
use serde_json::{json, Value};
use uuid::Uuid;

use crate::models::{CreateDriverRequest, UpdateDriverRequest};

#[derive(Debug, Deserialize)]
pub struct DriverQuery {
    pub search: Option<String>,
    pub status: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router {
    Router::new()
        .route("/", get(get_drivers).post(create_driver))
        .route(
            "/:id",
            get(get_driver).patch(update_driver).delete(delete_driver),
        )
        .route("/:id/status", patch(update_status))
        .route("/:id/location", patch(update_location))
        .route("/available", get(get_available_drivers))
        .route("/:id/stats", get(get_driver_stats))
}

async fn get_drivers(Query(params): Query<DriverQuery>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({
        "data": [
            {
                "id": Uuid::new_v4(),
                "first_name": "John",
                "last_name": "Smith",
                "email": "john.smith@example.com",
                "phone": "+1234567890",
                "status": "online",
                "active_loads": 2,
                "total_loads": 145,
                "rating": 4.8,
                "created_at": chrono::Utc::now(),
                "updated_at": chrono::Utc::now(),
            }
        ],
        "total": 1,
    })))
}

async fn get_driver(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({
        "id": id,
        "first_name": "John",
        "last_name": "Smith",
        "email": "john.smith@example.com",
        "status": "online",
        "active_loads": 2,
        "total_loads": 145,
        "rating": 4.8,
    })))
}

async fn create_driver(
    Json(payload): Json<CreateDriverRequest>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    Ok((
        StatusCode::CREATED,
        Json(json!({
            "id": Uuid::new_v4(),
            "first_name": payload.first_name,
            "last_name": payload.last_name,
            "email": payload.email,
            "phone": payload.phone,
            "status": "offline",
            "active_loads": 0,
            "total_loads": 0,
            "created_at": chrono::Utc::now(),
            "updated_at": chrono::Utc::now(),
        })),
    ))
}

async fn update_driver(
    Path(id): Path<Uuid>,
    Json(_payload): Json<UpdateDriverRequest>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "id": id, "updated_at": chrono::Utc::now() })))
}

async fn delete_driver(Path(id): Path<Uuid>) -> StatusCode {
    tracing::info!("Delete driver: {}", id);
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

async fn update_location(
    Path(id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "latitude": payload.get("latitude"), "longitude": payload.get("longitude"), "updated_at": chrono::Utc::now() }),
    ))
}

async fn get_available_drivers() -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [] })))
}

async fn get_driver_stats(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "driver_id": id, "total_loads": 145, "completed_loads": 142, "on_time_rate": 0.98 }),
    ))
}
