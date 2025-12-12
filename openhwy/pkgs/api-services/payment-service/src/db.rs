use crate::models::*;
use anyhow::Result;
use chrono::Utc;
use surrealdb::{
    engine::remote::ws::{Client, Ws},
    opt::auth::Root,
    Surreal,
};

pub type Database = Surreal<Client>;

/// Initialize connection to SurrealDB
pub async fn init_db() -> Result<Database> {
    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "127.0.0.1:8000".to_string());

    // Connect to SurrealDB
    let db = Surreal::new::<Ws>(db_url).await?;

    // Sign in as root
    db.signin(Root {
        username: "root",
        password: "root",
    })
    .await?;

    // Use namespace and database
    db.use_ns("hwytms").use_db("production").await?;

    Ok(db)
}

/// Update subscription by Stripe customer ID
pub async fn update_subscription_by_customer(
    db: &Database,
    stripe_customer_id: &str,
    update: SubscriptionUpdate,
) -> Result<()> {
    let now = Utc::now().to_rfc3339();

    let mut query = String::from("UPDATE subscriptions SET updated_at = $now");

    // Build dynamic update query
    if let Some(tier) = &update.tier {
        query.push_str(", tier = $tier");
    }
    if let Some(status) = &update.status {
        query.push_str(", status = $status");
    }
    if let Some(sub_id) = &update.stripe_subscription_id {
        query.push_str(", stripe_subscription_id = $stripe_subscription_id");
    }
    if let Some(payment) = &update.payment_method {
        query.push_str(", payment_method = $payment_method");
    }
    if let Some(start) = &update.current_period_start {
        query.push_str(", current_period_start = $current_period_start");
    }
    if let Some(end) = &update.current_period_end {
        query.push_str(", current_period_end = $current_period_end");
    }
    if let Some(grace) = &update.grace_period_ends {
        query.push_str(", grace_period_ends = $grace_period_ends");
    }
    if let Some(cancel) = update.cancel_at_period_end {
        query.push_str(", cancel_at_period_end = $cancel_at_period_end");
    }

    query.push_str(" WHERE stripe_customer_id = $stripe_customer_id");

    let mut q = db.query(&query).bind(("now", now)).bind(("stripe_customer_id", stripe_customer_id));

    if let Some(tier) = &update.tier {
        q = q.bind(("tier", tier));
    }
    if let Some(status) = &update.status {
        q = q.bind(("status", status));
    }
    if let Some(sub_id) = &update.stripe_subscription_id {
        q = q.bind(("stripe_subscription_id", sub_id));
    }
    if let Some(payment) = &update.payment_method {
        q = q.bind(("payment_method", payment));
    }
    if let Some(start) = &update.current_period_start {
        q = q.bind(("current_period_start", start));
    }
    if let Some(end) = &update.current_period_end {
        q = q.bind(("current_period_end", end));
    }
    if let Some(grace) = &update.grace_period_ends {
        q = q.bind(("grace_period_ends", grace));
    }
    if let Some(cancel) = update.cancel_at_period_end {
        q = q.bind(("cancel_at_period_end", cancel));
    }

    q.await?;

    Ok(())
}

/// Create payment record
pub async fn create_payment_record(db: &Database, payment: PaymentRecord) -> Result<()> {
    let now = Utc::now().to_rfc3339();

    db.create("payments")
        .content(serde_json::json!({
            "user_id": payment.user_id,
            "amount": payment.amount,
            "currency": payment.currency,
            "payment_method": payment.payment_method,
            "stripe_payment_id": payment.stripe_payment_id,
            "status": payment.status,
            "created_at": now,
        }))
        .await?;

    Ok(())
}
