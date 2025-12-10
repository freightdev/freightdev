use crate::models::Claims;
use anyhow::Result;
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use uuid::Uuid;

/// Generate JWT access token (7 days)
pub fn generate_access_token(
    user_id: &str,
    email: &str,
    role: &str,
    tier: &str,
) -> Result<String> {
    let secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "dev-secret-change-in-production".to_string());

    let iat = Utc::now();
    let exp = iat + Duration::days(7);

    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        tier: tier.to_string(),
        iat: iat.timestamp() as usize,
        exp: exp.timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )?;

    Ok(token)
}

/// Generate refresh token (90 days) - just a UUID
pub fn generate_refresh_token() -> (String, String) {
    let token = Uuid::new_v4().to_string();
    let expires_at = (Utc::now() + Duration::days(90)).to_rfc3339();
    (token, expires_at)
}

/// Validate and decode JWT token
pub fn validate_token(token: &str) -> Result<Claims> {
    let secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "dev-secret-change-in-production".to_string());

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )?;

    Ok(token_data.claims)
}
