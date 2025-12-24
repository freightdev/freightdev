use anyhow::{anyhow, Result};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub exp: usize,
    pub tier: Option<String>,
}

pub struct JwtMiddleware {
    secret: String,
    header_name: String,
}

impl JwtMiddleware {
    pub fn new(secret: String, header_name: String) -> Self {
        Self {
            secret,
            header_name,
        }
    }

    pub fn validate(&self, token: &str) -> Result<Claims> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &Validation::new(Algorithm::HS256),
        )?;

        Ok(token_data.claims)
    }

    pub fn extract_token<'a>(&self, header_value: &'a str) -> Option<&'a str> {
        header_value.strip_prefix("Bearer ")
    }
}
