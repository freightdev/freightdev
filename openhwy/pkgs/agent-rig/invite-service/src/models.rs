use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

#[derive(Debug, Deserialize)]
pub struct CreateInviteRequest {
    pub dispatcher_id: String,
    pub driver_name: Option<String>,
    pub contact: Option<String>, // email or phone
}

#[derive(Debug, Serialize)]
pub struct CreateInviteResponse {
    pub invite_token: String,
    pub magic_link: String,
    pub expires_at: String,
}

#[derive(Debug, Deserialize)]
pub struct AcceptInviteRequest {
    pub invite_token: String,
    pub device_id: String,
}

#[derive(Debug, Serialize)]
pub struct AcceptInviteResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub driver_id: String,
    pub dispatcher: DispatcherInfo,
    pub nebula_config: NebulaConfig,
}

#[derive(Debug, Serialize)]
pub struct DispatcherInfo {
    pub id: String,
    pub nebula_ip: String,
}

#[derive(Debug, Serialize)]
pub struct NebulaConfig {
    pub ca_cert: String,
    pub cert: String,
    pub key: String,
    pub nebula_ip: String,
    pub lighthouse: String,
}

#[derive(Debug, Serialize)]
pub struct VerifyInviteResponse {
    pub valid: bool,
    pub dispatcher_name: Option<String>,
    pub expires_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Invite {
    pub id: Thing,
    pub dispatcher_id: Thing,
    pub driver_name: Option<String>,
    pub contact: Option<String>,
    pub driver_cert_pem: Option<String>,
    pub driver_key_pem: Option<String>,
    pub driver_nebula_ip: Option<String>,
    pub created_at: String,
    pub expires_at: String,
    pub used: bool,
    pub used_at: Option<String>,
}
