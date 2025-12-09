use std::env;

use anyhow::{Context, Result};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

use crate::models::User;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub email: String,
    pub exp: usize,
}

pub fn encode_token(user: &User) -> Result<String> {
    let expiration = (Utc::now() + Duration::hours(24)).timestamp() as usize;
    let claims = Claims {
        sub: user.id.to_string(),
        email: user.email.clone(),
        exp: expiration,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret().as_bytes()),
    )
    .context("failed to encode JWT")
}

pub fn decode_token(token: &str) -> Result<Claims> {
    let validation = Validation::default();
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret().as_bytes()),
        &validation,
    )
    .context("failed to decode JWT")?;
    Ok(token_data.claims)
}

fn secret() -> String {
    env::var("JWT_SECRET").unwrap_or_else(|_| "hwy-tms-secret".to_string())
}
