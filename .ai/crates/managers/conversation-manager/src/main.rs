mod models;
mod parser;
mod analyzer;
mod entities;
mod patterns;
mod storage;

use anyhow::Result;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use models::*;
use parser::ConversationParser;
use analyzer::ConversationAnalyzer;
use storage::ConversationStorage;
use std::sync::Arc;
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;
use tracing::{info, error};
use tracing_subscriber;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    storage: Arc<ConversationStorage>,
    parser: Arc<ConversationParser>,
    analyzer: Arc<ConversationAnalyzer>,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter("conversation_intelligence=debug,tower_http=debug")
        .init();

    info!("Starting Conversation Intelligence Agent");

    // Load configuration
    let config = load_config()?;

    // Initialize storage
    let storage = ConversationStorage::new(
        &config.database_url,
        &config.namespace,
        &config.database,
        &config.username,
        &config.password,
    )
    .await?;

    info!("Connected to SurrealDB");

    // Create shared state
    let state = AppState {
        storage: Arc::new(storage),
        parser: Arc::new(ConversationParser::new()),
        analyzer: Arc::new(ConversationAnalyzer::new()),
    };

    // Build router
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/parse", post(parse_conversations))
        .route("/analyze", post(analyze_conversations))
        .route("/query", post(query_conversations))
        .route("/search/:text", get(search_conversations))
        .route("/stats", get(get_stats))
        .route("/conversation/:id", get(get_conversation))
        .route("/entities/:type", get(get_entities))
        .route("/export/json", post(export_to_json))
        .route("/export/yaml", post(export_to_yaml))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start server
    let addr = format!("{}:{}", config.host, config.port);
    info!("Listening on {}", addr);

    let listener = TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

// Health check endpoint
async fn health_check() -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "ok",
        "service": "conversation-intelligence",
        "version": "0.1.0"
    }))
}

// Parse conversations from export files
async fn parse_conversations(
    State(state): State<AppState>,
    Json(request): Json<ParseRequest>,
) -> Result<Json<ParseResponse>, AppError> {
    info!("Parsing conversations from {:?}", request.source);

    let response = state.parser.parse(request).await?;

    // Store parsed conversations
    state.storage.store_conversations(&response.conversations).await?;

    info!("Parsed and stored {} conversations", response.total_parsed);

    Ok(Json(response))
}

// Analyze conversations
async fn analyze_conversations(
    State(state): State<AppState>,
    Json(request): Json<AnalyzeRequest>,
) -> Result<Json<AnalyzeResponse>, AppError> {
    info!("Analyzing conversations with {:?} passes", request.passes);

    // Get conversations to analyze
    let mut conversations = if let Some(ref ids) = request.conversation_ids {
        let mut convs = Vec::new();
        for id in ids {
            if let Some(conv) = state.storage.get_conversation(*id).await? {
                convs.push(conv);
            }
        }
        convs
    } else {
        // Analyze all conversations (in production, you'd want pagination)
        let query = QueryRequest {
            query: String::new(),
            filters: None,
            limit: Some(1000),
        };
        state.storage.query_conversations(&query).await?.conversations
    };

    // Run analysis
    let response = state.analyzer.analyze(&mut conversations, &request).await?;

    // Update stored conversations with analysis results
    for conv in conversations {
        state.storage.store_conversation(&conv).await?;
    }

    info!("Analysis complete: {}", response.summary);

    Ok(Json(response))
}

// Query conversations
async fn query_conversations(
    State(state): State<AppState>,
    Json(request): Json<QueryRequest>,
) -> Result<Json<QueryResponse>, AppError> {
    info!("Querying conversations: {}", request.query);

    let response = state.storage.query_conversations(&request).await?;

    Ok(Json(response))
}

// Search conversations by text
async fn search_conversations(
    State(state): State<AppState>,
    Path(text): Path<String>,
) -> Result<Json<Vec<Conversation>>, AppError> {
    info!("Searching for: {}", text);

    let conversations = state.storage.search_by_text(&text, 50).await?;

    Ok(Json(conversations))
}

// Get statistics
async fn get_stats(
    State(state): State<AppState>,
) -> Result<Json<StatsResponse>, AppError> {
    let stats = state.storage.get_stats().await?;
    Ok(Json(stats))
}

// Get single conversation
async fn get_conversation(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Conversation>, AppError> {
    let conversation = state.storage.get_conversation(id).await?
        .ok_or_else(|| anyhow::anyhow!("Conversation not found"))?;

    Ok(Json(conversation))
}

// Get entities by type
async fn get_entities(
    State(state): State<AppState>,
    Path(entity_type): Path<String>,
) -> Result<Json<Vec<Entity>>, AppError> {
    let entity_type = match entity_type.to_lowercase().as_str() {
        "project" => EntityType::Project,
        "technology" => EntityType::Technology,
        "person" => EntityType::Person,
        "concept" => EntityType::Concept,
        "filepath" => EntityType::FilePath,
        "command" => EntityType::Command,
        "url" => EntityType::URL,
        "code" => EntityType::Code,
        other => EntityType::Other(other.to_string()),
    };

    let entities = state.storage.get_entities_by_type(entity_type).await?;
    Ok(Json(entities))
}

// Export to JSON
async fn export_to_json(
    State(state): State<AppState>,
    Json(request): Json<QueryRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    let response = state.storage.query_conversations(&request).await?;
    let json = serde_json::to_value(&response.conversations)?;
    Ok(Json(json))
}

// Export to YAML
async fn export_to_yaml(
    State(state): State<AppState>,
    Json(request): Json<QueryRequest>,
) -> Result<String, AppError> {
    let response = state.storage.query_conversations(&request).await?;
    let yaml = serde_yaml::to_string(&response.conversations)?;
    Ok(yaml)
}

// Configuration
#[derive(Debug, serde::Deserialize)]
struct Config {
    host: String,
    port: u16,
    database_url: String,
    namespace: String,
    database: String,
    username: String,
    password: String,
}

fn load_config() -> Result<Config> {
    // Try to load from config file, fallback to defaults
    let config = Config {
        host: std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
        port: std::env::var("PORT")
            .unwrap_or_else(|_| "9020".to_string())
            .parse()?,
        database_url: std::env::var("DATABASE_URL")
            .unwrap_or_else(|_| "ws://127.0.0.1:8000".to_string()),
        namespace: std::env::var("DB_NAMESPACE").unwrap_or_else(|_| "agency".to_string()),
        database: std::env::var("DB_DATABASE").unwrap_or_else(|_| "conversations".to_string()),
        username: std::env::var("DB_USERNAME").unwrap_or_else(|_| "root".to_string()),
        password: std::env::var("DB_PASSWORD").unwrap_or_else(|_| "root".to_string()),
    };

    Ok(config)
}

// Error handling
struct AppError(anyhow::Error);

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        error!("Request error: {:?}", self.0);

        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": self.0.to_string()
            })),
        )
            .into_response()
    }
}

impl<E> From<E> for AppError
where
    E: Into<anyhow::Error>,
{
    fn from(err: E) -> Self {
        Self(err.into())
    }
}
