use crate::{db, models::*, stripe_verify};
use axum::{
    body::Bytes,
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use chrono::{Duration, Utc};
use serde_json::json;

/// POST /webhook/stripe
/// Handle Stripe webhook events
pub async fn stripe_webhook(
    State(db): State<db::Database>,
    headers: HeaderMap,
    body: Bytes,
) -> impl IntoResponse {
    // Get signature header
    let signature = match headers.get("stripe-signature") {
        Some(sig) => match sig.to_str() {
            Ok(s) => s,
            Err(_) => {
                tracing::error!("Invalid signature header");
                return (
                    StatusCode::BAD_REQUEST,
                    Json(json!({"error": "Invalid signature"})),
                );
            }
        },
        None => {
            tracing::error!("Missing stripe-signature header");
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Missing signature"})),
            );
        }
    };

    // Convert body to string
    let payload = match String::from_utf8(body.to_vec()) {
        Ok(p) => p,
        Err(_) => {
            tracing::error!("Invalid UTF-8 in body");
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Invalid payload"})),
            );
        }
    };

    // Verify signature
    let webhook_secret =
        std::env::var("STRIPE_WEBHOOK_SECRET").unwrap_or_else(|_| "whsec_test".to_string());

    match stripe_verify::verify_signature(&payload, signature, &webhook_secret) {
        Ok(true) => {
            tracing::debug!("✅ Webhook signature verified");
        }
        Ok(false) => {
            tracing::error!("❌ Invalid webhook signature");
            return (
                StatusCode::UNAUTHORIZED,
                Json(json!({"error": "Invalid signature"})),
            );
        }
        Err(e) => {
            tracing::error!("Error verifying signature: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Verification failed"})),
            );
        }
    }

    // Parse event
    let event: StripeEvent = match serde_json::from_str(&payload) {
        Ok(e) => e,
        Err(e) => {
            tracing::error!("Failed to parse event: {}", e);
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Invalid event format"})),
            );
        }
    };

    tracing::info!("📨 Received event: {}", event.event_type);

    // Handle different event types
    match event.event_type.as_str() {
        "customer.subscription.created" => handle_subscription_created(&db, event).await,
        "customer.subscription.updated" => handle_subscription_updated(&db, event).await,
        "customer.subscription.deleted" => handle_subscription_deleted(&db, event).await,
        "invoice.payment_succeeded" => handle_payment_succeeded(&db, event).await,
        "invoice.payment_failed" => handle_payment_failed(&db, event).await,
        _ => {
            tracing::debug!("Unhandled event type: {}", event.event_type);
            (StatusCode::OK, Json(json!({"received": true})))
        }
    }
}

async fn handle_subscription_created(
    db: &db::Database,
    event: StripeEvent,
) -> (StatusCode, Json<serde_json::Value>) {
    tracing::info!("🆕 Subscription created");

    let obj = &event.data.object;
    let customer_id = obj["customer"].as_str().unwrap_or("");
    let subscription_id = obj["id"].as_str().unwrap_or("");
    let status = obj["status"].as_str().unwrap_or("active");

    // Determine tier from plan metadata or amount
    let tier = determine_tier_from_stripe(&obj);

    let current_period_end = obj["current_period_end"].as_i64().unwrap_or(0);
    let period_end = chrono::DateTime::from_timestamp(current_period_end, 0)
        .unwrap_or_else(|| Utc::now())
        .to_rfc3339();

    let update = SubscriptionUpdate {
        user_id: None,
        tier: Some(tier),
        status: Some(status.to_string()),
        stripe_customer_id: Some(customer_id.to_string()),
        stripe_subscription_id: Some(subscription_id.to_string()),
        payment_method: None,
        current_period_start: None,
        current_period_end: Some(period_end),
        grace_period_ends: None,
        cancel_at_period_end: Some(false),
    };

    match db::update_subscription_by_customer(db, customer_id, update).await {
        Ok(_) => {
            tracing::info!("✅ Subscription updated in database");
            (StatusCode::OK, Json(json!({"received": true})))
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        }
    }
}

async fn handle_subscription_updated(
    db: &db::Database,
    event: StripeEvent,
) -> (StatusCode, Json<serde_json::Value>) {
    tracing::info!("🔄 Subscription updated");

    let obj = &event.data.object;
    let customer_id = obj["customer"].as_str().unwrap_or("");
    let subscription_id = obj["id"].as_str().unwrap_or("");
    let status = obj["status"].as_str().unwrap_or("active");
    let cancel_at_period_end = obj["cancel_at_period_end"].as_bool().unwrap_or(false);

    let tier = determine_tier_from_stripe(&obj);

    let current_period_end = obj["current_period_end"].as_i64().unwrap_or(0);
    let period_end = chrono::DateTime::from_timestamp(current_period_end, 0)
        .unwrap_or_else(|| Utc::now())
        .to_rfc3339();

    let update = SubscriptionUpdate {
        user_id: None,
        tier: Some(tier),
        status: Some(status.to_string()),
        stripe_customer_id: Some(customer_id.to_string()),
        stripe_subscription_id: Some(subscription_id.to_string()),
        payment_method: None,
        current_period_start: None,
        current_period_end: Some(period_end),
        grace_period_ends: None,
        cancel_at_period_end: Some(cancel_at_period_end),
    };

    match db::update_subscription_by_customer(db, customer_id, update).await {
        Ok(_) => {
            tracing::info!("✅ Subscription updated in database");
            (StatusCode::OK, Json(json!({"received": true})))
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        }
    }
}

async fn handle_subscription_deleted(
    db: &db::Database,
    event: StripeEvent,
) -> (StatusCode, Json<serde_json::Value>) {
    tracing::info!("❌ Subscription deleted/cancelled");

    let obj = &event.data.object;
    let customer_id = obj["customer"].as_str().unwrap_or("");

    let update = SubscriptionUpdate {
        user_id: None,
        tier: Some("free".to_string()),
        status: Some("cancelled".to_string()),
        stripe_customer_id: None,
        stripe_subscription_id: None,
        payment_method: None,
        current_period_start: None,
        current_period_end: None,
        grace_period_ends: None,
        cancel_at_period_end: Some(false),
    };

    match db::update_subscription_by_customer(db, customer_id, update).await {
        Ok(_) => {
            tracing::info!("✅ Subscription downgraded to free");
            (StatusCode::OK, Json(json!({"received": true})))
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        }
    }
}

async fn handle_payment_succeeded(
    db: &db::Database,
    event: StripeEvent,
) -> (StatusCode, Json<serde_json::Value>) {
    tracing::info!("✅ Payment succeeded");

    let obj = &event.data.object;
    let customer_id = obj["customer"].as_str().unwrap_or("");

    // Update subscription status to active
    let update = SubscriptionUpdate {
        user_id: None,
        tier: None,
        status: Some("active".to_string()),
        stripe_customer_id: None,
        stripe_subscription_id: None,
        payment_method: None,
        current_period_start: None,
        current_period_end: None,
        grace_period_ends: None,
        cancel_at_period_end: None,
    };

    match db::update_subscription_by_customer(db, customer_id, update).await {
        Ok(_) => {
            tracing::info!("✅ Subscription status updated to active");
            (StatusCode::OK, Json(json!({"received": true})))
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        }
    }
}

async fn handle_payment_failed(
    db: &db::Database,
    event: StripeEvent,
) -> (StatusCode, Json<serde_json::Value>) {
    tracing::info!("❌ Payment failed");

    let obj = &event.data.object;
    let customer_id = obj["customer"].as_str().unwrap_or("");

    // Update subscription status to past_due with 7-day grace period
    let grace_period_ends = (Utc::now() + Duration::days(7)).to_rfc3339();

    let update = SubscriptionUpdate {
        user_id: None,
        tier: None,
        status: Some("past_due".to_string()),
        stripe_customer_id: None,
        stripe_subscription_id: None,
        payment_method: None,
        current_period_start: None,
        current_period_end: None,
        grace_period_ends: Some(grace_period_ends),
        cancel_at_period_end: None,
    };

    match db::update_subscription_by_customer(db, customer_id, update).await {
        Ok(_) => {
            tracing::info!("✅ Subscription marked as past_due with grace period");
            (StatusCode::OK, Json(json!({"received": true})))
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        }
    }
}

/// Determine tier from Stripe subscription object
fn determine_tier_from_stripe(obj: &serde_json::Value) -> String {
    // Check metadata first
    if let Some(metadata) = obj["metadata"].as_object() {
        if let Some(tier) = metadata.get("tier") {
            if let Some(tier_str) = tier.as_str() {
                return tier_str.to_string();
            }
        }
    }

    // Otherwise determine from amount
    if let Some(items) = obj["items"]["data"].as_array() {
        if let Some(first_item) = items.first() {
            if let Some(amount) = first_item["price"]["unit_amount"].as_i64() {
                return match amount {
                    ..=0 => "free".to_string(),
                    1..=10000 => "pro".to_string(), // $100 or less
                    _ => "enterprise".to_string(),
                };
            }
        }
    }

    // Default to free
    "free".to_string()
}
