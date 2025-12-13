use crate::models::NebulaCert;
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

/// Create a new Nebula certificate record
pub async fn create_cert(
    db: &Database,
    user_id: &str,
    nebula_ip: &str,
    cert_pem: &str,
    key_pem: &str,
    expires_at: &str,
) -> Result<NebulaCert> {
    let now = Utc::now().to_rfc3339();

    let created: Vec<NebulaCert> = db
        .create("nebula_certs")
        .content(serde_json::json!({
            "user_id": user_id,
            "nebula_ip": nebula_ip,
            "cert_pem": cert_pem,
            "key_pem": key_pem,
            "issued_at": now,
            "expires_at": expires_at,
            "revoked": false,
        }))
        .await?;

    created
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("Failed to create certificate"))
}

/// Get certificate by user ID
pub async fn get_cert_by_user(db: &Database, user_id: &str) -> Result<Option<NebulaCert>> {
    let mut result = db
        .query("SELECT * FROM nebula_certs WHERE user_id = $user_id AND revoked = false LIMIT 1")
        .bind(("user_id", user_id))
        .await?;

    let certs: Vec<NebulaCert> = result.take(0)?;
    Ok(certs.into_iter().next())
}

/// Get certificate by Nebula IP
pub async fn get_cert_by_ip(db: &Database, nebula_ip: &str) -> Result<Option<NebulaCert>> {
    let mut result = db
        .query("SELECT * FROM nebula_certs WHERE nebula_ip = $nebula_ip LIMIT 1")
        .bind(("nebula_ip", nebula_ip))
        .await?;

    let certs: Vec<NebulaCert> = result.take(0)?;
    Ok(certs.into_iter().next())
}

/// Count dispatcher certificates (for IP allocation)
pub async fn count_dispatchers(db: &Database) -> Result<usize> {
    // Dispatchers have IPs ending in .1
    let mut result = db
        .query("SELECT count() FROM nebula_certs WHERE string::ends_with(nebula_ip, '.1') AND revoked = false GROUP ALL")
        .await?;

    let counts: Vec<serde_json::Value> = result.take(0)?;
    if let Some(first) = counts.first() {
        if let Some(count) = first.get("count") {
            if let Some(num) = count.as_u64() {
                return Ok(num as usize);
            }
        }
    }

    Ok(0)
}

/// Count driver certificates for a specific dispatcher (for IP allocation)
pub async fn count_drivers_for_dispatcher(db: &Database, dispatcher_ip: &str) -> Result<usize> {
    // Extract subnet from dispatcher IP (e.g., "10.42.1" from "10.42.1.1")
    let parts: Vec<&str> = dispatcher_ip.split('.').collect();
    if parts.len() != 4 {
        return Ok(0);
    }
    let subnet = format!("{}.{}.{}", parts[0], parts[1], parts[2]);

    let mut result = db
        .query("SELECT count() FROM nebula_certs WHERE string::starts_with(nebula_ip, $subnet) AND nebula_ip != $dispatcher_ip AND revoked = false GROUP ALL")
        .bind(("subnet", format!("{}.", subnet)))
        .bind(("dispatcher_ip", dispatcher_ip))
        .await?;

    let counts: Vec<serde_json::Value> = result.take(0)?;
    if let Some(first) = counts.first() {
        if let Some(count) = first.get("count") {
            if let Some(num) = count.as_u64() {
                return Ok(num as usize);
            }
        }
    }

    Ok(0)
}

/// Revoke a certificate
pub async fn revoke_cert(db: &Database, user_id: &str) -> Result<()> {
    let now = Utc::now().to_rfc3339();

    db.query("UPDATE nebula_certs SET revoked = true, revoked_at = $now WHERE user_id = $user_id")
        .bind(("now", now))
        .bind(("user_id", user_id))
        .await?;

    Ok(())
}

/// Get all active certificates (for distribution to lighthouse)
pub async fn get_all_active_certs(db: &Database) -> Result<Vec<NebulaCert>> {
    let mut result = db
        .query("SELECT * FROM nebula_certs WHERE revoked = false")
        .await?;

    let certs: Vec<NebulaCert> = result.take(0)?;
    Ok(certs)
}
