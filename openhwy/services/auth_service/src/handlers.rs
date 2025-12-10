use crate::{db, errors::AuthError, jwt, models::*};
use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use surrealdb::sql::Thing;

/// POST /auth/signup
/// Create a new user account
pub async fn signup(
    State(db): State<db::Database>,
    Json(payload): Json<SignupRequest>,
) -> Result<Json<AuthResponse>, AuthError> {
    // Validate role
    if payload.role != "dispatcher" && payload.role != "driver" {
        return Err(AuthError::InvalidCredentials);
    }

    // Check if user already exists
    if let Some(_) = db::find_user_by_email(&db, &payload.email)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
    {
        return Err(AuthError::UserAlreadyExists);
    }

    // Create user with free subscription
    let user_with_sub = db::create_user(&db, &payload.email, &payload.password, &payload.role)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    // Generate tokens
    let user_id = user_with_sub.user.id.to_string();
    let access_token = jwt::generate_access_token(
        &user_id,
        &user_with_sub.user.email,
        &user_with_sub.user.role,
        &user_with_sub.subscription.tier,
    )
    .map_err(|_| AuthError::InternalServerError)?;

    let (refresh_token, refresh_expires_at) = jwt::generate_refresh_token();

    // Store refresh token
    db::create_refresh_token(&db, &user_id, &refresh_token, &refresh_expires_at)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: UserPublic {
            id: user_id,
            email: user_with_sub.user.email,
            role: user_with_sub.user.role,
            tier: user_with_sub.subscription.tier,
        },
    }))
}

/// POST /auth/login
/// Authenticate user and return tokens
pub async fn login(
    State(db): State<db::Database>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, AuthError> {
    // Find user
    let user = db::find_user_by_email(&db, &payload.email)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
        .ok_or(AuthError::InvalidCredentials)?;

    // Verify password
    if !db::verify_password(&payload.password, &user.password_hash)
        .map_err(|_| AuthError::InternalServerError)?
    {
        return Err(AuthError::InvalidCredentials);
    }

    // Get subscription
    let user_id = user.id.to_string();
    let user_with_sub = db::get_user_with_subscription(&db, &user_id)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
        .ok_or(AuthError::InternalServerError)?;

    // Generate tokens
    let access_token = jwt::generate_access_token(
        &user_id,
        &user.email,
        &user.role,
        &user_with_sub.subscription.tier,
    )
    .map_err(|_| AuthError::InternalServerError)?;

    let (refresh_token, refresh_expires_at) = jwt::generate_refresh_token();

    // Store refresh token
    db::create_refresh_token(&db, &user_id, &refresh_token, &refresh_expires_at)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token,
        user: UserPublic {
            id: user_id,
            email: user.email,
            role: user.role,
            tier: user_with_sub.subscription.tier,
        },
    }))
}

/// GET /auth/validate
/// Validate JWT token and return subscription status
pub async fn validate(
    State(db): State<db::Database>,
    headers: HeaderMap,
) -> Result<Json<ValidateResponse>, AuthError> {
    // Extract token from Authorization header
    let auth_header = headers
        .get("authorization")
        .ok_or(AuthError::Unauthorized)?
        .to_str()
        .map_err(|_| AuthError::Unauthorized)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(AuthError::Unauthorized)?;

    // Validate token
    let claims = jwt::validate_token(token).map_err(|_| AuthError::InvalidToken)?;

    // Get user with subscription
    let user_with_sub = db::get_user_with_subscription(&db, &claims.sub)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
        .ok_or(AuthError::InvalidToken)?;

    // Get tier features
    let features = db::get_tier_features(&db, &user_with_sub.subscription.tier)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    Ok(Json(ValidateResponse {
        valid: true,
        user_id: Some(claims.sub),
        tier: Some(user_with_sub.subscription.tier.clone()),
        status: Some(user_with_sub.subscription.status.clone()),
        expires_at: user_with_sub
            .subscription
            .current_period_end
            .clone(),
        features,
    }))
}

/// POST /auth/refresh
/// Refresh access token using refresh token
pub async fn refresh(
    State(db): State<db::Database>,
    Json(payload): Json<RefreshRequest>,
) -> Result<Json<AuthResponse>, AuthError> {
    // Validate refresh token
    let refresh_token = db::validate_refresh_token(&db, &payload.refresh_token)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
        .ok_or(AuthError::InvalidToken)?;

    // Revoke old refresh token
    db::revoke_refresh_token(&db, &payload.refresh_token)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    // Get user with subscription
    let user_id = refresh_token.user_id.to_string();
    let user_with_sub = db::get_user_with_subscription(&db, &user_id)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?
        .ok_or(AuthError::InvalidToken)?;

    // Generate new tokens
    let access_token = jwt::generate_access_token(
        &user_id,
        &user_with_sub.user.email,
        &user_with_sub.user.role,
        &user_with_sub.subscription.tier,
    )
    .map_err(|_| AuthError::InternalServerError)?;

    let (new_refresh_token, refresh_expires_at) = jwt::generate_refresh_token();

    // Store new refresh token
    db::create_refresh_token(&db, &user_id, &new_refresh_token, &refresh_expires_at)
        .await
        .map_err(|e| AuthError::DatabaseError(e.to_string()))?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token: new_refresh_token,
        user: UserPublic {
            id: user_id,
            email: user_with_sub.user.email,
            role: user_with_sub.user.role,
            tier: user_with_sub.subscription.tier,
        },
    }))
}
