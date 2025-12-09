use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "load_status", rename_all = "snake_case")]
pub enum LoadStatus {
    Pending,
    Booked,
    InTransit,
    Delivered,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Load {
    pub id: Uuid,
    pub reference: String,
    pub origin: String,
    pub destination: String,
    pub origin_lat: Option<f64>,
    pub origin_lng: Option<f64>,
    pub destination_lat: Option<f64>,
    pub destination_lng: Option<f64>,
    pub status: LoadStatus,
    pub rate: f64,
    pub distance: Option<i32>,
    pub driver_id: Option<Uuid>,
    pub driver_name: Option<String>,
    pub eta: Option<String>,
    pub progress: Option<i32>,
    pub pickup_date: Option<DateTime<Utc>>,
    pub delivery_date: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateLoadRequest {
    pub reference: String,
    pub origin: String,
    pub destination: String,
    pub rate: f64,
    pub distance: Option<i32>,
    pub pickup_date: Option<DateTime<Utc>>,
    pub delivery_date: Option<DateTime<Utc>>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateLoadRequest {
    pub origin: Option<String>,
    pub destination: Option<String>,
    pub rate: Option<f64>,
    pub distance: Option<i32>,
    pub status: Option<LoadStatus>,
    pub notes: Option<String>,
}
