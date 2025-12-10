use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

// ============================================================================
// REQUEST/RESPONSE MODELS
// ============================================================================

#[derive(Debug, Deserialize)]
pub struct SignupRequest {
    pub email: String,
    pub password: String,
    pub role: String, // "dispatcher" or "driver"
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user: UserPublic,
}

#[derive(Debug, Serialize)]
pub struct ValidateResponse {
    pub valid: bool,
    pub user_id: Option<String>,
    pub tier: Option<String>,
    pub status: Option<String>,
    pub expires_at: Option<String>,
    pub features: Option<TierFeatures>,
}

// ============================================================================
// DATABASE MODELS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Thing,
    pub email: String,
    pub password_hash: String,
    pub role: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserPublic {
    pub id: String,
    pub email: String,
    pub role: String,
    pub tier: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subscription {
    pub id: Thing,
    pub user_id: Thing,
    pub tier: String,
    pub status: String,
    pub stripe_customer_id: Option<String>,
    pub stripe_subscription_id: Option<String>,
    pub payment_method: Option<String>,
    pub current_period_start: Option<String>,
    pub current_period_end: Option<String>,
    pub grace_period_ends: Option<String>,
    pub cancel_at_period_end: bool,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TierFeatures {
    pub tier: String,
    pub max_drivers: i32,
    pub max_loads: i32,
    pub ai_agents_enabled: bool,
    pub custom_branding: bool,
    pub priority_support: bool,
    pub dedicated_support: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RefreshToken {
    pub id: Thing,
    pub user_id: Thing,
    pub token: String,
    pub expires_at: String,
    pub created_at: String,
    pub revoked: bool,
}

// ============================================================================
// JWT CLAIMS
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,        // user_id
    pub email: String,
    pub role: String,
    pub tier: String,
    pub iat: usize,         // issued at
    pub exp: usize,         // expiration
}

// ============================================================================
// INTERNAL MODELS
// ============================================================================

#[derive(Debug)]
pub struct UserWithSubscription {
    pub user: User,
    pub subscription: Subscription,
}
