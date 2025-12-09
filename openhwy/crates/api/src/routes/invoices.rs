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
pub struct InvoiceQuery {
    pub search: Option<String>,
    pub status: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router {
    Router::new()
        .route("/", get(get_invoices).post(create_invoice))
        .route(
            "/:id",
            get(get_invoice)
                .patch(update_invoice)
                .delete(delete_invoice),
        )
        .route("/:id/payments", post(record_payment))
        .route("/:id/status", patch(update_status))
        .route("/stats", get(get_stats))
        .route("/:id/pdf", get(generate_pdf))
}

async fn get_invoices(Query(params): Query<InvoiceQuery>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "data": [], "total": 0 })))
}

async fn get_invoice(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "number": "INV-001", "amount": 1250.00, "status": "pending" }),
    ))
}

async fn create_invoice(
    Json(_payload): Json<Value>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    Ok((
        StatusCode::CREATED,
        Json(json!({ "id": Uuid::new_v4(), "number": "INV-001", "status": "draft" })),
    ))
}

async fn update_invoice(
    Path(id): Path<Uuid>,
    Json(_payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({ "id": id, "updated_at": chrono::Utc::now() })))
}

async fn delete_invoice(Path(id): Path<Uuid>) -> StatusCode {
    tracing::info!("Delete invoice: {}", id);
    StatusCode::NO_CONTENT
}

async fn record_payment(
    Path(id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "invoice_id": id, "amount": payload.get("amount"), "updated_at": chrono::Utc::now() }),
    ))
}

async fn update_status(
    Path(id): Path<Uuid>,
    Json(payload): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "id": id, "status": payload.get("status"), "updated_at": chrono::Utc::now() }),
    ))
}

async fn get_stats() -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "total_amount": 47250.00, "paid": 38350.00, "outstanding": 8900.00, "paid_today": 8900.00 }),
    ))
}

async fn generate_pdf(Path(id): Path<Uuid>) -> Result<Json<Value>, StatusCode> {
    Ok(Json(
        json!({ "pdf_url": format!("/invoices/{}/invoice.pdf", id) }),
    ))
}
