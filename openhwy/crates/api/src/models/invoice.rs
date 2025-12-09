use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "invoice_status", rename_all = "snake_case")]
pub enum InvoiceStatus {
    Draft,
    Pending,
    Paid,
    Partial,
    Cancelled,
    Overdue,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Invoice {
    pub id: Uuid,
    pub number: String,
    pub load_id: Option<Uuid>,
    pub driver_id: Option<Uuid>,
    pub driver_name: Option<String>,
    pub amount: f64,
    pub paid_amount: f64,
    pub remaining_amount: f64,
    pub status: InvoiceStatus,
    pub due_date: DateTime<Utc>,
    pub issued_date: DateTime<Utc>,
    pub paid_date: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateInvoiceRequest {
    pub load_id: Uuid,
    pub amount: f64,
    pub due_date: DateTime<Utc>,
    pub notes: Option<String>,
}
