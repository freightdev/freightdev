// Lead Manager
// CRUD operations and orchestration for the lead generation system

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
use tracing::{error, info};

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapeAndAnalyzeRequest {
    source: String,
    keywords: Option<Vec<String>>,
    limit: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DailyDigestResponse {
    date: String,
    total_leads: usize,
    top_leads: Vec<DigestLead>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DigestLead {
    title: String,
    source: String,
    fit_score: f32,
    category: String,
    pricing: String,
    url: String,
}

#[derive(Debug, Clone, Deserialize)]
struct HealthQuery {
    detailed: Option<bool>,
}

#[derive(Debug, Clone, Deserialize)]
struct DigestQuery {
    min_score: Option<f32>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    http_client: Client,
    scraper_url: String,
    analyzer_url: String,
    database_manager_url: String,
}

// ============================================================================
// API Handlers
// ============================================================================

async fn health_handler(Query(params): Query<HealthQuery>) -> impl IntoResponse {
    if params.detailed.unwrap_or(false) {
        Json(serde_json::json!({
            "status": "ok",
            "service": "lead-manager",
            "version": "0.1.0",
            "timestamp": Utc::now().to_rfc3339()
        }))
    } else {
        Json(serde_json::json!({ "status": "ok" }))
    }
}

async fn scrape_and_analyze_handler(
    State(state): State<Arc<AppState>>,
    Json(request): Json<ScrapeAndAnalyzeRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    info!("Starting scrape and analyze pipeline for source: {}", request.source);

    // Step 1: Scrape leads
    let scrape_response = state
        .http_client
        .post(&format!("{}/scrape", state.scraper_url))
        .json(&request)
        .send()
        .await
        .map_err(|e| {
            error!("Failed to scrape: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let scrape_result: serde_json::Value = scrape_response.json().await.map_err(|e| {
        error!("Failed to parse scrape response: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let leads = scrape_result["leads"].as_array().ok_or_else(|| {
        error!("No leads array in response");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    info!("Scraped {} leads, starting analysis", leads.len());

    // Step 2: Analyze each lead
    let mut analyzed_count = 0;
    for lead in leads {
        let analyze_req = serde_json::json!({
            "lead_id": lead["id"],
            "lead_title": lead["title"],
            "lead_description": lead["description"]
        });

        if let Ok(_) = state
            .http_client
            .post(&format!("{}/analyze", state.analyzer_url))
            .json(&analyze_req)
            .send()
            .await
        {
            analyzed_count += 1;
        }

        // Rate limiting
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    }

    info!("Analyzed {} leads", analyzed_count);

    Ok(Json(serde_json::json!({
        "success": true,
        "leads_scraped": leads.len(),
        "leads_analyzed": analyzed_count
    })))
}

async fn daily_digest_handler(
    State(state): State<Arc<AppState>>,
    Query(params): Query<DigestQuery>,
) -> Result<Json<DailyDigestResponse>, StatusCode> {
    let min_score = params.min_score.unwrap_or(0.6);

    // Query database for top leads
    let query = format!(
        "SELECT * FROM leads WHERE fit_score >= {} ORDER BY fit_score DESC LIMIT 20",
        min_score
    );

    let db_request = serde_json::json!({ "query": query });

    let response = state
        .http_client
        .post(&format!("{}/query", state.database_manager_url))
        .json(&db_request)
        .send()
        .await
        .map_err(|e| {
            error!("Database query failed: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let db_result: serde_json::Value = response.json().await.map_err(|e| {
        error!("Failed to parse database response: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let leads = db_result["result"]
        .as_array()
        .map(|arr| arr.to_vec())
        .unwrap_or_default();

    let top_leads: Vec<DigestLead> = leads
        .iter()
        .filter_map(|lead| {
            Some(DigestLead {
                title: lead["title"].as_str()?.to_string(),
                source: lead["source"].as_str()?.to_string(),
                fit_score: lead["fit_score"].as_f64()? as f32,
                category: lead["category"].as_str()?.to_string(),
                pricing: lead["pricing_estimate"].as_str()?.to_string(),
                url: lead["source_url"].as_str()?.to_string(),
            })
        })
        .collect();

    Ok(Json(DailyDigestResponse {
        date: Utc::now().format("%Y-%m-%d").to_string(),
        total_leads: top_leads.len(),
        top_leads,
    }))
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter("lead_manager=info")
        .init();

    info!("Starting lead-manager");

    // Create HTTP client
    let http_client = Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()?;

    // Create application state
    let state = Arc::new(AppState {
        http_client,
        scraper_url: std::env::var("SCRAPER_URL")
            .unwrap_or_else(|_| "http://localhost:9013".to_string()),
        analyzer_url: std::env::var("ANALYZER_URL")
            .unwrap_or_else(|_| "http://localhost:9014".to_string()),
        database_manager_url: std::env::var("DATABASE_MANAGER_URL")
            .unwrap_or_else(|_| "http://localhost:9012".to_string()),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health_handler))
        .route("/scrape-and-analyze", post(scrape_and_analyze_handler))
        .route("/daily-digest", get(daily_digest_handler))
        .with_state(state);

    // Start server
    let addr = "0.0.0.0:9015";
    info!("Lead manager listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
