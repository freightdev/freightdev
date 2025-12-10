use crate::{ca, db, ip_allocator, models::*};
use axum::{extract::State, http::StatusCode, Json};
use chrono::{Duration, Utc};
use serde_json::json;

/// POST /cert/issue
/// Issue a new Nebula certificate for a user
pub async fn issue_cert(
    State(database): State<db::Database>,
    Json(payload): Json<IssueCertRequest>,
) -> Result<Json<IssueCertResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Check if user already has a certificate
    if let Some(_existing) = db::get_cert_by_user(&database, &payload.user_id)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Database error"})),
            )
        })?
    {
        return Err((
            StatusCode::CONFLICT,
            Json(json!({"error": "Certificate already exists for this user"})),
        ));
    }

    // Allocate IP based on role
    let nebula_ip = match payload.role.as_str() {
        "dispatcher" => {
            // Count existing dispatchers
            let dispatcher_count = db::count_dispatchers(&database).await.map_err(|e| {
                tracing::error!("Database error: {}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(json!({"error": "Database error"})),
                )
            })?;

            ip_allocator::allocate_dispatcher_ip(dispatcher_count).map_err(|e| {
                tracing::error!("IP allocation error: {}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(json!({"error": "IP allocation failed"})),
                )
            })?
        }
        "driver" => {
            // Driver must have a dispatcher_id
            let dispatcher_id = payload.dispatcher_id.ok_or_else(|| {
                (
                    StatusCode::BAD_REQUEST,
                    Json(json!({"error": "dispatcher_id required for driver role"})),
                )
            })?;

            // Get dispatcher's certificate to find their IP
            let dispatcher_cert = db::get_cert_by_user(&database, &dispatcher_id)
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
                        StatusCode::BAD_REQUEST,
                        Json(json!({"error": "Dispatcher not found or has no certificate"})),
                    )
                })?;

            // Count existing drivers for this dispatcher
            let driver_count = db::count_drivers_for_dispatcher(&database, &dispatcher_cert.nebula_ip)
                .await
                .map_err(|e| {
                    tracing::error!("Database error: {}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(json!({"error": "Database error"})),
                    )
                })?;

            ip_allocator::allocate_driver_ip(&dispatcher_cert.nebula_ip, driver_count).map_err(
                |e| {
                    tracing::error!("IP allocation error: {}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(json!({"error": "IP allocation failed"})),
                    )
                },
            )?
        }
        _ => {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Invalid role, must be 'dispatcher' or 'driver'"})),
            ));
        }
    };

    // Generate certificate (1 year validity)
    let groups = vec![payload.role.clone()];
    let (cert_pem, key_pem) = ca::generate_cert(&nebula_ip, &payload.user_id, groups, 365).map_err(|e| {
        tracing::error!("Certificate generation error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Certificate generation failed"})),
        )
    })?;

    let expires_at = (Utc::now() + Duration::days(365)).to_rfc3339();

    // Store certificate in database
    db::create_cert(
        &database,
        &payload.user_id,
        &nebula_ip,
        &cert_pem,
        &key_pem,
        &expires_at,
    )
    .await
    .map_err(|e| {
        tracing::error!("Database error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to store certificate"})),
        )
    })?;

    // Get CA certificate
    let ca_cert = ca::get_ca_cert().map_err(|e| {
        tracing::error!("CA cert error: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to get CA certificate"})),
        )
    })?;

    let config = CAConfig::default();

    tracing::info!("✅ Issued certificate for {} with IP {}", payload.user_id, nebula_ip);

    Ok(Json(IssueCertResponse {
        cert_pem,
        key_pem,
        nebula_ip,
        ca_cert,
        lighthouse_host: config.lighthouse_host,
        expires_at,
    }))
}

/// POST /cert/revoke
/// Revoke a user's certificate
pub async fn revoke_cert(
    State(database): State<db::Database>,
    Json(payload): Json<RevokeCertRequest>,
) -> Result<Json<RevokeCertResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Check if certificate exists
    db::get_cert_by_user(&database, &payload.user_id)
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
                Json(json!({"error": "Certificate not found"})),
            )
        })?;

    // Revoke certificate
    db::revoke_cert(&database, &payload.user_id)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Failed to revoke certificate"})),
            )
        })?;

    let revoked_at = Utc::now().to_rfc3339();

    tracing::info!("✅ Revoked certificate for {}", payload.user_id);

    Ok(Json(RevokeCertResponse {
        revoked: true,
        revoked_at,
    }))
}

/// POST /cert/verify
/// Verify a certificate
pub async fn verify_cert(
    State(database): State<db::Database>,
    Json(payload): Json<VerifyCertRequest>,
) -> Result<Json<VerifyCertResponse>, (StatusCode, Json<serde_json::Value>)> {
    // Basic certificate format verification
    let valid = ca::verify_cert(&payload.cert_pem).unwrap_or(false);

    if !valid {
        return Ok(Json(VerifyCertResponse {
            valid: false,
            nebula_ip: None,
            issued_at: None,
            expires_at: None,
            revoked: false,
        }));
    }

    // Try to extract IP from cert (simplified - in production parse actual cert)
    // For now, just return valid=true
    Ok(Json(VerifyCertResponse {
        valid: true,
        nebula_ip: None,
        issued_at: None,
        expires_at: None,
        revoked: false,
    }))
}
