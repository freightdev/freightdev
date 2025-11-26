use crate::{
    context::Context,
    core::Engine,
    error::{Error, Result},
    model::Model,
    token::TokenProcessor,
};
use std::sync::Arc;

pub mod auth;
pub mod database;
pub mod inference;
pub mod middleware;
pub mod model;
pub mod response;
pub mod route;
pub mod runtime;
pub mod token;
pub mod _utils;

pub use auth::{AuthHandler, AuthConfig, AuthToken};
pub use database::{DatabaseHandler, DatabaseConfig};
pub use inference::{InferenceHandler, InferenceRequest, InferenceResponse};
pub use middleware::{MiddlewareHandler, RequestMiddleware, ResponseMiddleware};
pub use model::{ModelHandler, ModelInfo, ModelStatus};
pub use response::{ResponseHandler, ResponseFormat, StreamingResponse};
pub use route::{RouteHandler, Route, HttpMethod};
pub use runtime::{RuntimeHandler, RuntimeConfig};
pub use token::{TokenHandler, TokenRequest, TokenResponse};

pub struct HandlerManager {
    auth_handler: Arc<AuthHandler>,
    database_handler: Arc<DatabaseHandler>,
    inference_handler: Arc<InferenceHandler>,
    model_handler: Arc<ModelHandler>,
    response_handler: Arc<ResponseHandler>,
    token_handler: Arc<TokenHandler>,
    runtime_handler: Arc<RuntimeHandler>,
}

impl HandlerManager {
    pub fn new(
        engine: Arc<Engine>,
        model: Arc<Model>,
        context: Arc<Context>,
        token_processor: Arc<TokenProcessor>,
    ) -> Result<Self> {
        let auth_handler = Arc::new(AuthHandler::new()?);
        let database_handler = Arc::new(DatabaseHandler::new()?);
        let model_handler = Arc::new(ModelHandler::new(model.clone())?);
        let token_handler = Arc::new(TokenHandler::new(token_processor.clone())?);
        let inference_handler = Arc::new(InferenceHandler::new(
            engine.clone(),
            model.clone(),
            context.clone(),
            token_processor.clone(),
        )?);
        let response_handler = Arc::new(ResponseHandler::new()?);
        let runtime_handler = Arc::new(RuntimeHandler::new(
            engine,
            model,
            context,
            token_processor,
        )?);

        Ok(Self {
            auth_handler,
            database_handler,
            inference_handler,
            model_handler,
            response_handler,
            token_handler,
            runtime_handler,
        })
    }

    pub fn auth(&self) -> Arc<AuthHandler> {
        Arc::clone(&self.auth_handler)
    }

    pub fn database(&self) -> Arc<DatabaseHandler> {
        Arc::clone(&self.database_handler)
    }

    pub fn inference(&self) -> Arc<InferenceHandler> {
        Arc::clone(&self.inference_handler)
    }

    pub fn model(&self) -> Arc<ModelHandler> {
        Arc::clone(&self.model_handler)
    }

    pub fn response(&self) -> Arc<ResponseHandler> {
        Arc::clone(&self.response_handler)
    }

    pub fn token(&self) -> Arc<TokenHandler> {
        Arc::clone(&self.token_handler)
    }

    pub fn runtime(&self) -> Arc<RuntimeHandler> {
        Arc::clone(&self.runtime_handler)
    }

    pub async fn handle_request(&self, request: HttpRequest) -> Result<HttpResponse> {
        // Authentication first
        let auth_result = self.auth_handler.authenticate(&request).await?;
        if !auth_result.is_valid {
            return Ok(HttpResponse::unauthorized("Invalid authentication"));
        }

        // Route the request
        match request.path.as_str() {
            "/v1/completions" => self.handle_completions(request).await,
            "/v1/chat/completions" => self.handle_chat_completions(request).await,
            "/v1/embeddings" => self.handle_embeddings(request).await,
            "/v1/models" => self.handle_models(request).await,
            "/v1/tokenize" => self.handle_tokenize(request).await,
            "/v1/detokenize" => self.handle_detokenize(request).await,
            "/health" => self.handle_health(request).await,
            "/metrics" => self.handle_metrics(request).await,
            _ => Ok(HttpResponse::not_found("Endpoint not found")),
        }
    }

    async fn handle_completions(&self, request: HttpRequest) -> Result<HttpResponse> {
        let inference_request: InferenceRequest = serde_json::from_str(&request.body)
            .map_err(|e| Error::RequestError(format!("Invalid request body: {}", e)))?;

        let response = self.inference_handler.generate_completion(inference_request).await?;
        let json_response = serde_json::to_string(&response)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_chat_completions(&self, request: HttpRequest) -> Result<HttpResponse> {
        let chat_request: ChatCompletionRequest = serde_json::from_str(&request.body)
            .map_err(|e| Error::RequestError(format!("Invalid request body: {}", e)))?;

        let response = self.inference_handler.generate_chat_completion(chat_request).await?;
        let json_response = serde_json::to_string(&response)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_embeddings(&self, request: HttpRequest) -> Result<HttpResponse> {
        let embedding_request: EmbeddingRequest = serde_json::from_str(&request.body)
            .map_err(|e| Error::RequestError(format!("Invalid request body: {}", e)))?;

        let response = self.inference_handler.generate_embeddings(embedding_request).await?;
        let json_response = serde_json::to_string(&response)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_models(&self, request: HttpRequest) -> Result<HttpResponse> {
        let models = self.model_handler.list_models().await?;
        let json_response = serde_json::to_string(&models)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_tokenize(&self, request: HttpRequest) -> Result<HttpResponse> {
        let token_request: TokenRequest = serde_json::from_str(&request.body)
            .map_err(|e| Error::RequestError(format!("Invalid request body: {}", e)))?;

        let response = self.token_handler.tokenize(token_request).await?;
        let json_response = serde_json::to_string(&response)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_detokenize(&self, request: HttpRequest) -> Result<HttpResponse> {
        let detokenize_request: DetokenizeRequest = serde_json::from_str(&request.body)
            .map_err(|e| Error::RequestError(format!("Invalid request body: {}", e)))?;

        let response = self.token_handler.detokenize(detokenize_request).await?;
        let json_response = serde_json::to_string(&response)
            .map_err(|e| Error::RequestError(format!("Failed to serialize response: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_health(&self, _request: HttpRequest) -> Result<HttpResponse> {
        let health_status = HealthStatus {
            status: "healthy".to_string(),
            model_loaded: self.model_handler.is_loaded().await,
            memory_usage: self.runtime_handler.get_memory_usage().await?,
            uptime: self.runtime_handler.get_uptime().await,
        };

        let json_response = serde_json::to_string(&health_status)
            .map_err(|e| Error::RequestError(format!("Failed to serialize health status: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }

    async fn handle_metrics(&self, _request: HttpRequest) -> Result<HttpResponse> {
        let metrics = self.runtime_handler.get_metrics().await?;
        let json_response = serde_json::to_string(&metrics)
            .map_err(|e| Error::RequestError(format!("Failed to serialize metrics: {}", e)))?;

        Ok(HttpResponse::ok(json_response))
    }
}

// HTTP types
#[derive(Debug, Clone)]
pub struct HttpRequest {
    pub method: String,
    pub path: String,
    pub headers: std::collections::HashMap<String, String>,
    pub body: String,
}

#[derive(Debug, Clone)]
pub struct HttpResponse {
    pub status: u16,
    pub headers: std::collections::HashMap<String, String>,
    pub body: String,
}

impl HttpResponse {
    pub fn ok(body: String) -> Self {
        let mut headers = std::collections::HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        
        Self {
            status: 200,
            headers,
            body,
        }
    }

    pub fn unauthorized(message: &str) -> Self {
        let body = format!(r#"{{"error": "{}"}}"#, message);
        let mut headers = std::collections::HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());

        Self {
            status: 401,
            headers,
            body,
        }
    }

    pub fn not_found(message: &str) -> Self {
        let body = format!(r#"{{"error": "{}"}}"#, message);
        let mut headers = std::collections::HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());

        Self {
            status: 404,
            headers,
            body,
        }
    }

    pub fn internal_error(message: &str) -> Self {
        let body = format!(r#"{{"error": "{}"}}"#, message);
        let mut headers = std::collections::HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());

        Self {
            status: 500,
            headers,
            body,
        }
    }
}

// Request/Response types
#[derive(Debug, serde::Deserialize)]
pub struct ChatCompletionRequest {
    pub model: String,
    pub messages: Vec<ChatMessage>,
    pub temperature: Option<f32>,
    pub max_tokens: Option<i32>,
    pub stream: Option<bool>,
}

#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, serde::Deserialize)]
pub struct EmbeddingRequest {
    pub input: String,
    pub model: String,
}

#[derive(Debug, serde::Deserialize)]
pub struct DetokenizeRequest {
    pub tokens: Vec<i32>,
}

#[derive(Debug, serde::Serialize)]
pub struct HealthStatus {
    pub status: String,
    pub model_loaded: bool,
    pub memory_usage: f32,
    pub uptime: u64,
}

pub trait Handler {
    type Request;
    type Response;
    
    async fn handle(&self, request: Self::Request) -> Result<Self::Response>;
}

pub trait AsyncHandler {
    async fn initialize(&self) -> Result<()>;
    async fn shutdown(&self) -> Result<()>;
    fn is_healthy(&self) -> bool;
}