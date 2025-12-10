use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

// ============================================================================
// REQUEST/RESPONSE MODELS
// ============================================================================

#[derive(Debug, Deserialize)]
pub struct IssueCertRequest {
    pub user_id: String,
    pub role: String, // "dispatcher" or "driver"
    pub dispatcher_id: Option<String>, // Required if role=driver
}

#[derive(Debug, Serialize)]
pub struct IssueCertResponse {
    pub cert_pem: String,
    pub key_pem: String,
    pub nebula_ip: String,
    pub ca_cert: String,
    pub lighthouse_host: String,
    pub expires_at: String,
}

#[derive(Debug, Deserialize)]
pub struct RevokeCertRequest {
    pub user_id: String,
}

#[derive(Debug, Serialize)]
pub struct RevokeCertResponse {
    pub revoked: bool,
    pub revoked_at: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyCertRequest {
    pub cert_pem: String,
}

#[derive(Debug, Serialize)]
pub struct VerifyCertResponse {
    pub valid: bool,
    pub nebula_ip: Option<String>,
    pub issued_at: Option<String>,
    pub expires_at: Option<String>,
    pub revoked: bool,
}

// ============================================================================
// DATABASE MODELS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NebulaCert {
    pub id: Thing,
    pub user_id: Thing,
    pub nebula_ip: String,
    pub cert_pem: String,
    pub key_pem: String,
    pub issued_at: String,
    pub expires_at: String,
    pub revoked: bool,
    pub revoked_at: Option<String>,
}

// ============================================================================
// CA CONFIGURATION
// ============================================================================

#[derive(Debug, Clone)]
pub struct CAConfig {
    pub ca_cert_path: String,
    pub ca_key_path: String,
    pub lighthouse_host: String,
    pub subnet_base: String, // "10.42"
}

impl Default for CAConfig {
    fn default() -> Self {
        Self {
            ca_cert_path: std::env::var("CA_CERT_PATH")
                .unwrap_or_else(|_| "./ca.crt".to_string()),
            ca_key_path: std::env::var("CA_KEY_PATH")
                .unwrap_or_else(|_| "./ca.key".to_string()),
            lighthouse_host: std::env::var("LIGHTHOUSE_HOST")
                .unwrap_or_else(|_| "lighthouse.open-hwy.com:4242".to_string()),
            subnet_base: std::env::var("SUBNET_BASE")
                .unwrap_or_else(|_| "10.42".to_string()),
        }
    }
}
