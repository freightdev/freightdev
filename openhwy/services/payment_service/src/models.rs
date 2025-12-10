use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

// ============================================================================
// STRIPE WEBHOOK EVENT
// ============================================================================

#[derive(Debug, Deserialize)]
pub struct StripeEvent {
    pub id: String,
    #[serde(rename = "type")]
    pub event_type: String,
    pub data: StripeEventData,
}

#[derive(Debug, Deserialize)]
pub struct StripeEventData {
    pub object: serde_json::Value,
}

// ============================================================================
// SUBSCRIPTION UPDATE MODELS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubscriptionUpdate {
    pub user_id: Option<Thing>,
    pub tier: Option<String>,
    pub status: Option<String>,
    pub stripe_customer_id: Option<String>,
    pub stripe_subscription_id: Option<String>,
    pub payment_method: Option<String>,
    pub current_period_start: Option<String>,
    pub current_period_end: Option<String>,
    pub grace_period_ends: Option<String>,
    pub cancel_at_period_end: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentRecord {
    pub user_id: Thing,
    pub amount: i64,
    pub currency: String,
    pub payment_method: String,
    pub stripe_payment_id: String,
    pub status: String,
}

// ============================================================================
// DATABASE MODELS
// ============================================================================

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
