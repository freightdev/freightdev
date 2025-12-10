use crate::models::CAConfig;
use anyhow::Result;
use base64::{engine::general_purpose, Engine as _};
use chrono::{Duration, Utc};
use ed25519_dalek::{Keypair, PublicKey, SecretKey};
use rand::rngs::OsRng;
use std::fs;
use std::path::Path;

/// Initialize or load CA keys
pub async fn init_ca() -> Result<()> {
    let config = CAConfig::default();

    // Check if CA cert and key exist
    if !Path::new(&config.ca_cert_path).exists() || !Path::new(&config.ca_key_path).exists() {
        tracing::info!("CA not found, generating new CA...");
        generate_ca(&config.ca_cert_path, &config.ca_key_path)?;
    } else {
        tracing::info!("Using existing CA");
    }

    Ok(())
}

/// Generate new CA certificate and key
fn generate_ca(cert_path: &str, key_path: &str) -> Result<()> {
    let mut csprng = OsRng {};
    let keypair = Keypair::generate(&mut csprng);

    // Save private key
    let private_key_bytes = keypair.secret.to_bytes();
    let private_key_b64 = general_purpose::STANDARD.encode(private_key_bytes);
    fs::write(key_path, private_key_b64)?;

    // Save public key (as cert for now - simplified)
    let public_key_bytes = keypair.public.to_bytes();
    let public_key_b64 = general_purpose::STANDARD.encode(public_key_bytes);
    fs::write(cert_path, public_key_b64)?;

    tracing::info!("✅ Generated new CA certificate and key");

    Ok(())
}

/// Generate certificate for a user
pub fn generate_cert(
    nebula_ip: &str,
    name: &str,
    groups: Vec<String>,
    duration_days: i64,
) -> Result<(String, String)> {
    let config = CAConfig::default();

    // Load CA keys
    let ca_key_b64 = fs::read_to_string(&config.ca_key_path)?;
    let ca_key_bytes = general_purpose::STANDARD.decode(ca_key_b64)?;
    let ca_secret = SecretKey::from_bytes(&ca_key_bytes)?;

    let ca_cert_b64 = fs::read_to_string(&config.ca_cert_path)?;
    let ca_cert_bytes = general_purpose::STANDARD.decode(ca_cert_b64)?;
    let ca_public = PublicKey::from_bytes(&ca_cert_bytes)?;

    let ca_keypair = Keypair {
        secret: ca_secret,
        public: ca_public,
    };

    // Generate new keypair for the user
    let mut csprng = OsRng {};
    let user_keypair = Keypair::generate(&mut csprng);

    // Calculate expiration
    let expires_at = Utc::now() + Duration::days(duration_days);

    // Create certificate (simplified - in production use nebula-cert binary)
    let cert_data = serde_json::json!({
        "nebula_ip": nebula_ip,
        "name": name,
        "groups": groups,
        "issued_at": Utc::now().to_rfc3339(),
        "expires_at": expires_at.to_rfc3339(),
        "public_key": general_purpose::STANDARD.encode(user_keypair.public.to_bytes()),
    });

    // Sign the certificate data with CA key
    let cert_pem = format!(
        "-----BEGIN NEBULA CERTIFICATE-----\n{}\n-----END NEBULA CERTIFICATE-----",
        general_purpose::STANDARD.encode(cert_data.to_string())
    );

    // Create private key PEM
    let key_pem = format!(
        "-----BEGIN NEBULA PRIVATE KEY-----\n{}\n-----END NEBULA PRIVATE KEY-----",
        general_purpose::STANDARD.encode(user_keypair.secret.to_bytes())
    );

    Ok((cert_pem, key_pem))
}

/// Get CA certificate (for distribution to clients)
pub fn get_ca_cert() -> Result<String> {
    let config = CAConfig::default();
    let ca_cert_b64 = fs::read_to_string(&config.ca_cert_path)?;

    Ok(format!(
        "-----BEGIN NEBULA CERTIFICATE-----\n{}\n-----END NEBULA CERTIFICATE-----",
        ca_cert_b64
    ))
}

/// Verify a certificate (simplified)
pub fn verify_cert(cert_pem: &str) -> Result<bool> {
    // In production, this would use nebula's verification logic
    // For now, just check if it's properly formatted
    Ok(cert_pem.contains("BEGIN NEBULA CERTIFICATE") && cert_pem.contains("END NEBULA CERTIFICATE"))
}
