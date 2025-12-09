use axum::{
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::services::surreal_service::SurrealService;

pub fn router() -> Router {
    Router::new()
        .route("/", get(list_payments))
        .route("/", post(create_payment))
}

#[derive(Debug, Deserialize)]
pub struct CreatePaymentRequest {
    pub user_id: String,
    pub amount: f64,
    pub status: Option<String>,
    pub method: Option<String>,
    pub metadata: Option<Value>,
}

#[derive(Debug, Serialize)]
struct PaymentList {
    data: Vec<Value>,
}

async fn list_payments() -> Result<Json<PaymentList>, StatusCode> {
    let service = SurrealService::get();
    let records = service
        .execute("SELECT * FROM payment ORDER BY updated_at DESC LIMIT 100;")
        .await
        .map_err(|err| {
            tracing::error!(?err, "Failed to list payments");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let data = records
        .into_iter()
        .map(|mut record| {
            SurrealService::strip_record_id(&mut record);
            record
        })
        .collect::<Vec<Value>>();

    Ok(Json(PaymentList { data }))
}

async fn create_payment(
    Json(payload): Json<CreatePaymentRequest>,
) -> Result<Json<Value>, StatusCode> {
    let user_id = Uuid::parse_str(&payload.user_id).map_err(|err| {
        tracing::error!(?err, "Invalid user_id for payment");
        StatusCode::BAD_REQUEST
    })?;

    let record = SurrealService::get()
        .create_payment(
            user_id,
            payload.amount,
            payload.status,
            payload.method,
            payload.metadata,
        )
        .await
        .map_err(|err| {
            tracing::error!(?err, "Failed to create payment");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(Json(record))
}
