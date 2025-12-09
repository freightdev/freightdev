use axum::{
    extract::{Path, Query},
    http::StatusCode,
    routing::{delete, get, patch, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use uuid::Uuid;

use crate::models::{CreateLoadRequest, LoadStatus, UpdateLoadRequest};

#[derive(Debug, Deserialize)]
pub struct LoadQuery {
    pub search: Option<String>,
    pub status: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router {
    Router::new()
        .route("/", get(get_loads).post(create_load))
        .route("/:id", get(get_load).patch(update_load).delete(delete_load))
        .route("/:id/assign", post(assign_driver))
        .route("/:id/status", patch(update_status))
        .route("/stats", get(get_stats))
}

async fn get_loads(Query(params): Query<LoadQuery>) -> Result<Json<Value>, StatusCode> {
    // TODO: Implement actual database query
    tracing::info!("Get loads with params: {:?}", params);

    Ok(Json(json!({
        "data": [
            {
                "id": Uuid::new_v4(),
                "reference": "LOAD-001",
                "origin": "New York, NY",
                "destination": "Boston, MA",
                "status": "in_transit",
                "rate": 1250.00,
                "distance": 215,
                "driver_name": "John Smith",
                "eta": "2 hours",
                "progress": 65,
                "created_at": chrono::Utc::now(),
                "updated_at": chrono::Utc::now(),
            }
        ],
        "total": 1,
        "page": params.page.unwrap_or(1),
        "limit": params.limit.unwrap_or(50),
    })))
}

async fn get_load(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    // TODO: Implement database query
    Ok(Json(json!({
        "id": id,
        "reference": "LOAD-001",
        "origin": "New York, NY",
        "destination": "Boston, MA",
        "status": "in_transit",
        "rate": 1250.00,
        "distance": 215,
        "driver_name": "John Smith",
        "created_at": chrono::Utc::now(),
        "updated_at": chrono::Utc::now(),
    })))
}

async fn create_load(
    Json(payload): Json<CreateLoadRequest>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    // TODO: Implement database insert
    Ok((
        StatusCode::CREATED,
        Json(json!({
            "id": Uuid::new_v4(),
            "reference": payload.reference,
            "origin": payload.origin,
            "destination": payload.destination,
            "status": "pending",
            "rate": payload.rate,
            "distance": payload.distance,
            "created_at": chrono::Utc::now(),
            "updated_at": chrono::Utc::now(),
        })),
    ))
}

async fn update_load(
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateLoadRequest>,
) -> Result<Json<Value>, StatusCode> {
    // TODO: Implement database update
    Ok(Json(json!({
        "id": id,
        "reference": "LOAD-001",
        "status": payload.status,
        "updated_at": chrono::Utc::now(),
    })))
}

async fn delete_load(Path(id): Path<Uuid>) -> StatusCode {
    // TODO: Implement database delete
    tracing::info!("Delete load: {}", id);
    StatusCode::NO_CONTENT
}

async fn assign_driver(
    Path(load_id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    // TODO: Implement driver assignment
    let driver_id = payload.get("driver_id").and_then(|v| v.as_str());
    tracing::info!("Assigning driver {:?} to load {}", driver_id, load_id);

    Ok(Json(json!({
        "id": load_id,
        "driver_id": driver_id,
        "status": "booked",
        "updated_at": chrono::Utc::now(),
    })))
}

async fn update_status(
    Path(load_id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    let status = payload.get("status").and_then(|v| v.as_str());

    Ok(Json(json!({
        "id": load_id,
        "status": status,
        "updated_at": chrono::Utc::now(),
    })))
}

async fn get_stats() -> Result<Json<Value>, StatusCode> {
    // TODO: Implement actual stats calculation
    Ok(Json(json!({
        "active_loads": 12,
        "available_drivers": 8,
        "pending_invoices": 15,
        "in_transit": 7,
    })))
}
