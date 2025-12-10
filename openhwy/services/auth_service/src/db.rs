use crate::models::*;
use anyhow::Result;
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
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

    // Sign in as root (for now - can use namespace/database auth later)
    db.signin(Root {
        username: "root",
        password: "root",
    })
    .await?;

    // Use namespace and database
    db.use_ns("hwytms").use_db("production").await?;

    Ok(db)
}

/// Create a new user and default free subscription
pub async fn create_user(
    db: &Database,
    email: &str,
    password: &str,
    role: &str,
) -> Result<UserWithSubscription> {
    // Hash password
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2
        .hash_password(password.as_bytes(), &salt)?
        .to_string();

    let now = Utc::now().to_rfc3339();

    // Create user
    let created: Vec<User> = db
        .create("users")
        .content(serde_json::json!({
            "email": email,
            "password_hash": password_hash,
            "role": role,
            "created_at": now,
            "updated_at": now,
        }))
        .await?;

    let user = created
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("Failed to create user"))?;

    // Create default free subscription
    let subscription: Vec<Subscription> = db
        .create("subscriptions")
        .content(serde_json::json!({
            "user_id": user.id.clone(),
            "tier": "free",
            "status": "active",
            "cancel_at_period_end": false,
            "created_at": now,
            "updated_at": now,
        }))
        .await?;

    let subscription = subscription
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("Failed to create subscription"))?;

    Ok(UserWithSubscription { user, subscription })
}

/// Find user by email
pub async fn find_user_by_email(db: &Database, email: &str) -> Result<Option<User>> {
    let mut result = db
        .query("SELECT * FROM users WHERE email = $email LIMIT 1")
        .bind(("email", email))
        .await?;

    let users: Vec<User> = result.take(0)?;
    Ok(users.into_iter().next())
}

/// Verify user password
pub fn verify_password(password: &str, password_hash: &str) -> Result<bool> {
    let parsed_hash = PasswordHash::new(password_hash)?;
    let argon2 = Argon2::default();
    Ok(argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

/// Get user with subscription
pub async fn get_user_with_subscription(
    db: &Database,
    user_id: &str,
) -> Result<Option<UserWithSubscription>> {
    let mut result = db
        .query("SELECT * FROM users WHERE id = $user_id LIMIT 1")
        .bind(("user_id", user_id))
        .await?;

    let users: Vec<User> = result.take(0)?;
    let user = match users.into_iter().next() {
        Some(u) => u,
        None => return Ok(None),
    };

    // Get subscription
    let mut sub_result = db
        .query("SELECT * FROM subscriptions WHERE user_id = $user_id LIMIT 1")
        .bind(("user_id", user.id.clone()))
        .await?;

    let subscriptions: Vec<Subscription> = sub_result.take(0)?;
    let subscription = subscriptions
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("No subscription found for user"))?;

    Ok(Some(UserWithSubscription { user, subscription }))
}

/// Get tier features
pub async fn get_tier_features(db: &Database, tier: &str) -> Result<Option<TierFeatures>> {
    let mut result = db
        .query("SELECT * FROM tier_features WHERE tier = $tier LIMIT 1")
        .bind(("tier", tier))
        .await?;

    let features: Vec<TierFeatures> = result.take(0)?;
    Ok(features.into_iter().next())
}

/// Create refresh token
pub async fn create_refresh_token(
    db: &Database,
    user_id: &str,
    token: &str,
    expires_at: &str,
) -> Result<RefreshToken> {
    let now = Utc::now().to_rfc3339();

    let created: Vec<RefreshToken> = db
        .create("refresh_tokens")
        .content(serde_json::json!({
            "user_id": user_id,
            "token": token,
            "expires_at": expires_at,
            "created_at": now,
            "revoked": false,
        }))
        .await?;

    created
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("Failed to create refresh token"))
}

/// Validate refresh token
pub async fn validate_refresh_token(
    db: &Database,
    token: &str,
) -> Result<Option<RefreshToken>> {
    let mut result = db
        .query("SELECT * FROM refresh_tokens WHERE token = $token AND revoked = false LIMIT 1")
        .bind(("token", token))
        .await?;

    let tokens: Vec<RefreshToken> = result.take(0)?;
    Ok(tokens.into_iter().next())
}

/// Revoke refresh token
pub async fn revoke_refresh_token(db: &Database, token: &str) -> Result<()> {
    db.query("UPDATE refresh_tokens SET revoked = true WHERE token = $token")
        .bind(("token", token))
        .await?;

    Ok(())
}
