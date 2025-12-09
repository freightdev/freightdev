use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "driver_status", rename_all = "snake_case")]
pub enum DriverStatus {
    Online,
    Away,
    Offline,
    OnBreak,
    Driving,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Driver {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: Option<String>,
    pub status: DriverStatus,
    pub current_location: Option<String>,
    pub current_lat: Option<f64>,
    pub current_lng: Option<f64>,
    pub active_loads: i32,
    pub total_loads: i32,
    pub cdl_number: Option<String>,
    pub cdl_expiry: Option<DateTime<Utc>>,
    pub vehicle_id: Option<String>,
    pub vehicle_plate: Option<String>,
    pub rating: Option<f64>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateDriverRequest {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: Option<String>,
    pub cdl_number: Option<String>,
    pub cdl_expiry: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateDriverRequest {
    pub phone: Option<String>,
    pub status: Option<DriverStatus>,
    pub cdl_number: Option<String>,
    pub cdl_expiry: Option<DateTime<Utc>>,
}
