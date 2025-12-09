use axum::{
    async_trait,
    extract::{FromRequestParts, Json},
    http::{header::AUTHORIZATION, request::Parts, StatusCode},
    routing::{get, post},
    Router,
};
use serde_json::Value;
use uuid::Uuid;

use crate::{
    models::{AuthResponse, CreateUserRequest, LoginRequest, User, UserRole},
    services::surreal_service::SurrealService,
    utils::jwt,
};

pub fn router() -> Router {
    Router::new()
        .route("/login", post(login))
        .route("/register", post(register))
        .route("/me", get(get_current_user))
        .route("/logout", post(logout))
        .route("/reset-password", post(reset_password))
}

async fn login(Json(payload): Json<LoginRequest>) -> Result<Json<AuthResponse>, StatusCode> {
    let service = SurrealService::get();
    let user = service
        .find_user_by_email(&payload.email)
        .await
        .map_err(|err| {
            tracing::error!(?err, "Failed to fetch user during login");
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let valid_password = bcrypt::verify(&payload.password, &user.password_hash).map_err(|err| {
        tracing::error!(?err, "Failed to verify password");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !valid_password {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let token = jwt::encode_token(&user).map_err(|err| {
        tracing::error!(?err, "Failed to generate JWT");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    Ok(Json(AuthResponse { token, user }))
}

async fn register(
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let service = SurrealService::get();
    let user = service.register_user(&payload).await.map_err(|err| {
        tracing::error!(?err, "Failed to register user");
        if err.to_string().contains("already registered") {
            StatusCode::CONFLICT
        } else {
            StatusCode::INTERNAL_SERVER_ERROR
        }
    })?;

    let token = jwt::encode_token(&user).map_err(|err| {
        tracing::error!(?err, "Failed to generate JWT");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    Ok(Json(AuthResponse { token, user }))
}

async fn get_current_user(BearerToken(token): BearerToken) -> Result<Json<User>, StatusCode> {
    let claims = jwt::decode_token(&token).map_err(|err| {
        tracing::error!(?err, "Invalid JWT when fetching current user");
        StatusCode::UNAUTHORIZED
    })?;

    let user_id = Uuid::parse_str(&claims.sub).map_err(|err| {
        tracing::error!(?err, "Invalid user id in JWT");
        StatusCode::UNAUTHORIZED
    })?;

    let user = SurrealService::get()
        .find_user_by_id(&user_id)
        .await
        .map_err(|err| {
            tracing::error!(?err, "Failed to load current user");
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::NOT_FOUND)?;

    Ok(Json(user))
}

async fn logout() -> StatusCode {
    StatusCode::OK
}

async fn reset_password(Json(payload): Json<Value>) -> StatusCode {
    tracing::info!("Password reset requested for: {:?}", payload.get("email"));
    StatusCode::OK
}

struct BearerToken(String);

#[async_trait]
impl<S> FromRequestParts<S> for BearerToken
where
    S: Send + Sync,
{
    type Rejection = StatusCode;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get(AUTHORIZATION)
            .ok_or(StatusCode::UNAUTHORIZED)?;
        let value = header.to_str().map_err(|_| StatusCode::UNAUTHORIZED)?;
        let token = value
            .strip_prefix("Bearer ")
            .ok_or(StatusCode::UNAUTHORIZED)?;
        Ok(BearerToken(token.to_string()))
    }
}
