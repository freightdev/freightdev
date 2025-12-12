use crate::{db, models::*};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use chrono::{Duration, Utc};
use serde_json::json;

/// POST /invite/create
/// Create a new driver invite with pre-generated Nebula certificate
pub async fn create_invite(
    State(database): State<db::Database>,
    Json(payload): Json<CreateInviteRequest>,
) -> Result<Json<CreateInviteResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Call Nebula CA service to generate certificate for driver
    let ca_url = std::env::var("NEBULA_CA_URL").unwrap_or_else(|_| "http://localhost:8003".to_string());

    let client = reqwest::Client::new();
    let cert_response = client
        .post(format!("{}/cert/issue", ca_url))
        .json(&json!({
            "user_id": format!("driver_pending_{}", uuid::Uuid::new_v4()),
            "role": "driver",
            "dispatcher_id": payload.dispatcher_id,
        }))
        .send()
        .await
        .map_err(|e| {
            tracing::error!("Failed to call CA service: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Failed to generate certificate"})),
            )
        })?;

    if !cert_response.status().is_success() {
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Certificate generation failed"})),
        ));
    }

    let cert_data: serde_json::Value = cert_response.json().await.map_err(|e| {
        tracing::error!("Failed to parse certificate response: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Invalid certificate response"})),
        )
    })?;

    let driver_cert_pem = cert_data["cert_pem"]
        .as_str()
        .ok_or_else(|| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Missing cert_pem in response"})),
            )
        })?
        .to_string();

    let driver_key_pem = cert_data["key_pem"]
        .as_str()
        .ok_or_else(|| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Missing key_pem in response"})),
            )
        })?
        .to_string();

    let driver_nebula_ip = cert_data["nebula_ip"]
        .as_str()
        .ok_or_else(|| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Missing nebula_ip in response"})),
            )
        })?
        .to_string();

    // Create invite (expires in 7 days)
    let expires_at = (Utc::now() + Duration::days(7)).to_rfc3339();

    let invite = db::create_invite(
        &database,
        &payload.dispatcher_id,
        payload.driver_name,
        payload.contact,
        driver_cert_pem,
        driver_key_pem,
        driver_nebula_ip,
        &expires_at,
    )
    .await
    .map_err(|e| {
        tracing::error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to create invite"})),
        )
    })?;

    let invite_token = invite.id.to_string().replace("invites:", "");
    let base_url = std::env::var("BASE_URL").unwrap_or_else(|_| "https://open-hwy.com".to_string());
    let magic_link = format!("{}/driver/join?token={}", base_url, invite_token);

    tracing::info!("✅ Created invite {} for dispatcher {}", invite_token, payload.dispatcher_id);

    Ok(Json(CreateInviteResponse {
        invite_token,
        magic_link,
        expires_at,
    }))
}

/// POST /invite/accept
/// Accept an invite and complete driver onboarding
pub async fn accept_invite(
    State(database): State<db::Database>,
    Json(payload): Json<AcceptInviteRequest>,
) -> Result<Json<AcceptInviteResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Get invite
    let invite_id = format!("invites:{}", payload.invite_token);
    let invite = db::get_invite(&database, &invite_id)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(json!({"error": "Invite not found"})),
            )
        })?;

    // Check if invite is valid
    if invite.used {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invite already used"})),
        ));
    }

    // Check if invite is expired
    let now = Utc::now();
    let expires_at = chrono::DateTime::parse_from_rfc3339(&invite.expires_at)
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Invalid expiration date"})),
            )
        })?
        .with_timezone(&Utc);

    if now > expires_at {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Invite expired"})),
        ));
    }

    // Create driver user account
    let auth_url = std::env::var("AUTH_URL").unwrap_or_else(|_| "http://localhost:8001".to_string());

    // Generate random password for driver (they'll use device_id to auth)
    let auto_password = uuid::Uuid::new_v4().to_string();

    let client = reqwest::Client::new();
    let signup_response = client
        .post(format!("{}/auth/signup", auth_url))
        .json(&json!({
            "email": format!("driver_{}@open-hwy.com", uuid::Uuid::new_v4()),
            "password": auto_password,
            "role": "driver",
        }))
        .send()
        .await
        .map_err(|e| {
            tracing::error!("Failed to create driver account: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Failed to create driver account"})),
            )
        })?;

    if !signup_response.status().is_success() {
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Driver account creation failed"})),
        ));
    }

    let auth_data: serde_json::Value = signup_response.json().await.map_err(|e| {
        tracing::error!("Failed to parse auth response: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Invalid auth response"})),
        )
    })?;

    // Mark invite as used
    db::mark_invite_used(&database, &invite_id)
        .await
        .map_err(|e| {
            tracing::error!("Failed to mark invite as used: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        })?;

    tracing::info!("✅ Driver accepted invite {}", payload.invite_token);

    Ok(Json(AcceptInviteResponse {
        access_token: auth_data["access_token"].as_str().unwrap_or("").to_string(),
        refresh_token: auth_data["refresh_token"].as_str().unwrap_or("").to_string(),
        driver_id: auth_data["user"]["id"].as_str().unwrap_or("").to_string(),
        dispatcher: DispatcherInfo {
            id: invite.dispatcher_id.to_string(),
            nebula_ip: "10.42.1.1".to_string(), // TODO: Fetch from dispatcher's cert
        },
        nebula_config: NebulaConfig {
            ca_cert: "".to_string(),           // TODO: Fetch from CA service
            cert: invite.driver_cert_pem.unwrap_or_default(),
            key: invite.driver_key_pem.unwrap_or_default(),
            nebula_ip: invite.driver_nebula_ip.unwrap_or_default(),
            lighthouse: "lighthouse.open-hwy.com:4242".to_string(),
        },
    }))
}

/// GET /invite/verify/:token
/// Verify an invite without accepting it
pub async fn verify_invite(
    State(database): State<db::Database>,
    Path(token): Path<String>,
) -> Result<Json<VerifyInviteResponse>, (StatusCode, Json<serde_json::Value>)> {
    let invite_id = format!("invites:{}", token);
    let invite = db::get_invite(&database, &invite_id)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        })?;

    match invite {
        Some(inv) => {
            let now = Utc::now();
            let expires_at = chrono::DateTime::parse_from_rfc3339(&inv.expires_at)
                .map_err(|_| {
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(json!({"error": "Invalid expiration date"})),
                    )
                })?
                .with_timezone(&Utc);

            let valid = !inv.used && now <= expires_at;

            Ok(Json(VerifyInviteResponse {
                valid,
                dispatcher_name: inv.driver_name,
                expires_at: Some(inv.expires_at),
            }))
        }
        None => Ok(Json(VerifyInviteResponse {
            valid: false,
            dispatcher_name: None,
            expires_at: None,
        })),
    }
}
