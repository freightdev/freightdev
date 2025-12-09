use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "document_type", rename_all = "snake_case")]
pub enum DocumentType {
    License,
    Insurance,
    Bill,
    Inspection,
    Hazmat,
    Delivery,
    RateConfirmation,
    Pod,
    Bol,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "document_status", rename_all = "snake_case")]
pub enum DocumentStatus {
    Verified,
    Pending,
    Expired,
    Rejected,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Document {
    pub id: Uuid,
    pub name: String,
    pub document_type: DocumentType,
    pub category: String,
    pub status: DocumentStatus,
    pub driver_id: Option<Uuid>,
    pub driver_name: Option<String>,
    pub load_id: Option<Uuid>,
    pub file_url: String,
    pub file_size: i64,
    pub uploaded_at: DateTime<Utc>,
    pub expires_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateDocumentRequest {
    pub name: String,
    pub document_type: DocumentType,
    pub category: String,
    pub driver_id: Option<Uuid>,
    pub load_id: Option<Uuid>,
    pub file_url: String,
    pub file_size: i64,
    pub expires_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
}
