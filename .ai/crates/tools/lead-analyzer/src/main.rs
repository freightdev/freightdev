// Lead Analyzer Agent
// Analyzes leads using LLM to score fit, categorize, and estimate pricing

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{error, info, warn};
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Lead {
    id: String,
    source: String,
    title: String,
    description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalyzeRequest {
    lead_id: String,
    lead_title: String,
    lead_description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalysisResult {
    lead_id: String,
    fit_score: f32,
    category: String,
    pricing_estimate: String,
    reasoning: String,
    tags: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LLMRequest {
    model: String,
    prompt: String,
    stream: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LLMResponse {
    response: String,
}

#[derive(Debug, Clone, Deserialize)]
struct HealthQuery {
    detailed: Option<bool>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    http_client: Client,
    llm_server_url: String,
    database_manager_url: String,
}

// ============================================================================
// LLM Analysis
// ============================================================================

async fn analyze_with_llm(
    state: &AppState,
    title: &str,
    description: Option<&str>,
) -> anyhow::Result<AnalysisResult> {
    let prompt = format!(
        r#"Analyze this potential client lead for an agency that builds websites and applications.

Title: {}
Description: {}

Provide analysis in this exact format:
FIT_SCORE: [0.0-1.0]
CATEGORY: [startup/enterprise/small-business/solopreneur]
PRICING: [$5k-10k/$10k-25k/$25k-50k/$50k+]
TAGS: [comma,separated,tags]
REASONING: [brief explanation]

Be concise and actionable."#,
        title,
        description.unwrap_or("N/A")
    );

    info!("Sending analysis request to LLM");

    let llm_req = serde_json::json!({
        "prompt": prompt,
        "temperature": 0.3,
        "max_tokens": 300,
        "stream": false
    });

    let response = state
        .http_client
        .post(&format!("{}/completion", state.llm_server_url))
        .json(&llm_req)
        .send()
        .await?;

    let llm_response: serde_json::Value = response.json().await?;
    let text = llm_response["content"]
        .as_str()
        .unwrap_or("")
        .to_string();

    // Parse LLM response
    let fit_score = extract_field(&text, "FIT_SCORE:")
        .and_then(|s| s.parse::<f32>().ok())
        .unwrap_or(0.5);

    let category = extract_field(&text, "CATEGORY:")
        .unwrap_or("unknown")
        .to_string();

    let pricing_estimate = extract_field(&text, "PRICING:")
        .unwrap_or("$10k-25k")
        .to_string();

    let tags_str = extract_field(&text, "TAGS:").unwrap_or("");
    let tags: Vec<String> = tags_str
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let reasoning = extract_field(&text, "REASONING:")
        .unwrap_or("Analysis pending")
        .to_string();

    Ok(AnalysisResult {
        lead_id: Uuid::new_v4().to_string(),
        fit_score,
        category,
        pricing_estimate,
        reasoning,
        tags,
    })
}

fn extract_field<'a>(text: &'a str, field: &str) -> Option<&'a str> {
    text.lines()
        .find(|line| line.starts_with(field))
        .and_then(|line| line.strip_prefix(field))
        .map(|s| s.trim())
}

// ============================================================================
// API Handlers
// ============================================================================

async fn health_handler(Query(params): Query<HealthQuery>) -> impl IntoResponse {
    if params.detailed.unwrap_or(false) {
        Json(serde_json::json!({
            "status": "ok",
            "service": "lead-analyzer",
            "version": "0.1.0",
            "timestamp": Utc::now().to_rfc3339()
        }))
    } else {
        Json(serde_json::json!({ "status": "ok" }))
    }
}

async fn analyze_handler(
    State(state): State<Arc<AppState>>,
    Json(request): Json<AnalyzeRequest>,
) -> Result<Json<AnalysisResult>, StatusCode> {
    info!("Analyzing lead: {}", request.lead_id);

    let result = analyze_with_llm(
        &state,
        &request.lead_title,
        request.lead_description.as_deref(),
    )
    .await
    .map_err(|e| {
        error!("Analysis failed: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // Store analysis result in database
    if let Err(e) = store_analysis(&state, &request.lead_id, &result).await {
        warn!("Failed to store analysis: {}", e);
    }

    // Update lead with analysis
    if let Err(e) = update_lead(&state, &request.lead_id, &result).await {
        warn!("Failed to update lead: {}", e);
    }

    Ok(Json(result))
}

async fn store_analysis(
    state: &AppState,
    lead_id: &str,
    result: &AnalysisResult,
) -> anyhow::Result<()> {
    let tags_json = serde_json::to_string(&result.tags)?;

    let query = format!(
        "CREATE lead_analysis SET lead_id = '{}', fit_score = {}, category = '{}', pricing_estimate = '{}', reasoning = '{}', tags = {}, model_used = 'tinyllama', created_at = time::now()",
        lead_id,
        result.fit_score,
        result.category,
        result.pricing_estimate,
        result.reasoning.replace('\'', "\\'"),
        tags_json
    );

    let db_request = serde_json::json!({ "query": query });

    state
        .http_client
        .post(&format!("{}/query", state.database_manager_url))
        .json(&db_request)
        .send()
        .await?;

    Ok(())
}

async fn update_lead(
    state: &AppState,
    lead_id: &str,
    result: &AnalysisResult,
) -> anyhow::Result<()> {
    let query = format!(
        "UPDATE leads SET fit_score = {}, category = '{}', pricing_estimate = '{}', status = 'analyzed', analyzed_at = time::now() WHERE id = '{}'",
        result.fit_score,
        result.category,
        result.pricing_estimate,
        lead_id
    );

    let db_request = serde_json::json!({ "query": query });

    state
        .http_client
        .post(&format!("{}/query", state.database_manager_url))
        .json(&db_request)
        .send()
        .await?;

    Ok(())
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter("lead_analyzer=info")
        .init();

    info!("Starting lead-analyzer agent");

    // Create HTTP client
    let http_client = Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()?;

    // Create application state
    let state = Arc::new(AppState {
        http_client,
        llm_server_url: std::env::var("LLM_SERVER_URL")
            .unwrap_or_else(|_| "http://localhost:11435".to_string()),
        database_manager_url: std::env::var("DATABASE_MANAGER_URL")
            .unwrap_or_else(|_| "http://localhost:9012".to_string()),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health_handler))
        .route("/analyze", post(analyze_handler))
        .with_state(state);

    // Start server
    let addr = "0.0.0.0:9014";
    info!("Lead analyzer listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
