use crate::models::Invite;
use anyhow::Result;
use chrono::Utc;
use surrealdb::{
    engine::remote::ws::{Client, Ws},
    opt::auth::Root,
    Surreal,
};

pub type Database = Surreal<Client>;

pub async fn init_db() -> Result<Database> {
    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "127.0.0.1:8000".to_string());
    let db = Surreal::new::<Ws>(db_url).await?;
    db.signin(Root {
        username: "root",
        password: "root",
    })
    .await?;
    db.use_ns("hwytms").use_db("production").await?;
    Ok(db)
}

pub async fn create_invite(
    db: &Database,
    dispatcher_id: &str,
    driver_name: Option<String>,
    contact: Option<String>,
    driver_cert_pem: String,
    driver_key_pem: String,
    driver_nebula_ip: String,
    expires_at: &str,
) -> Result<Invite> {
    let now = Utc::now().to_rfc3339();

    let created: Vec<Invite> = db
        .create("invites")
        .content(serde_json::json!({
            "dispatcher_id": dispatcher_id,
            "driver_name": driver_name,
            "contact": contact,
            "driver_cert_pem": driver_cert_pem,
            "driver_key_pem": driver_key_pem,
            "driver_nebula_ip": driver_nebula_ip,
            "created_at": now,
            "expires_at": expires_at,
            "used": false,
        }))
        .await?;

    created
        .into_iter()
        .next()
        .ok_or_else(|| anyhow::anyhow!("Failed to create invite"))
}

pub async fn get_invite(db: &Database, invite_id: &str) -> Result<Option<Invite>> {
    let mut result = db
        .query("SELECT * FROM $invite_id")
        .bind(("invite_id", invite_id))
        .await?;

    let invites: Vec<Invite> = result.take(0)?;
    Ok(invites.into_iter().next())
}

pub async fn mark_invite_used(db: &Database, invite_id: &str) -> Result<()> {
    let now = Utc::now().to_rfc3339();

    db.query("UPDATE $invite_id SET used = true, used_at = $now")
        .bind(("invite_id", invite_id))
        .bind(("now", now))
        .await?;

    Ok(())
}
