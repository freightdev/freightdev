// Web Scraper Framework
// Configurable data scraping on schedule
// Trucking rates, crypto prices, stock data, news, trends

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use scraper::{Html, Selector};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info};

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScraperConfig {
    id: String,
    name: String,
    url: String,
    selectors: HashMap<String, String>, // field_name -> CSS selector
    schedule_seconds: u64,
    enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapedData {
    scraper_id: String,
    timestamp: String,
    url: String,
    data: HashMap<String, String>,
    success: bool,
    error: Option<String>,
}

struct AppState {
    scrapers: Arc<RwLock<Vec<ScraperConfig>>>,
    recent_data: Arc<RwLock<Vec<ScrapedData>>>,
    client: reqwest::Client,
}

// ============================================================================
// Scraping Functions
// ============================================================================

async fn scrape_url(
    client: &reqwest::Client,
    config: &ScraperConfig,
) -> Result<HashMap<String, String>, String> {
    // Fetch HTML
    let response = client
        .get(&config.url)
        .send()
        .await
        .map_err(|e| format!("Request failed: {}", e))?;

    let html_content = response
        .text()
        .await
        .map_err(|e| format!("Failed to read response: {}", e))?;

    // Parse HTML
    let document = Html::parse_document(&html_content);
    let mut data = HashMap::new();

    // Extract data using selectors
    for (field, selector_str) in &config.selectors {
        let selector = Selector::parse(selector_str)
            .map_err(|e| format!("Invalid selector '{}': {}", selector_str, e))?;

        if let Some(element) = document.select(&selector).next() {
            let value = element.text().collect::<Vec<_>>().join(" ").trim().to_string();
            data.insert(field.clone(), value);
        } else {
            data.insert(field.clone(), String::new());
        }
    }

    Ok(data)
}

async fn run_scraper(client: &reqwest::Client, config: &ScraperConfig) -> ScrapedData {
    info!("Running scraper: {}", config.name);

    match scrape_url(client, config).await {
        Ok(data) => ScrapedData {
            scraper_id: config.id.clone(),
            timestamp: Utc::now().to_rfc3339(),
            url: config.url.clone(),
            data,
            success: true,
            error: None,
        },
        Err(e) => {
            error!("Scraper {} failed: {}", config.name, e);
            ScrapedData {
                scraper_id: config.id.clone(),
                timestamp: Utc::now().to_rfc3339(),
                url: config.url.clone(),
                data: HashMap::new(),
                success: false,
                error: Some(e),
            }
        }
    }
}

// ============================================================================
// Background Scraping Task
// ============================================================================

async fn scraping_task(state: Arc<AppState>) {
    loop {
        let scrapers = state.scrapers.read().await.clone();

        for config in scrapers {
            if !config.enabled {
                continue;
            }

            let result = run_scraper(&state.client, &config).await;

            // Store result
            {
                let mut recent = state.recent_data.write().await;
                recent.push(result.clone());

                // Keep last 1000 results
                if recent.len() > 1000 {
                    recent.remove(0);
                }
            }

            // TODO: Store in database

            // Wait before next scraper
            tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        }

        // Wait before next round
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Web Scraper: ONLINE")
}

async fn list_scrapers(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let scrapers = state.scrapers.read().await;
    Json(scrapers.clone())
}

async fn get_recent_data(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let data = state.recent_data.read().await;
    Json(data.clone())
}

#[derive(Deserialize)]
struct AddScraperRequest {
    config: ScraperConfig,
}

async fn add_scraper(
    State(state): State<Arc<AppState>>,
    Json(req): Json<AddScraperRequest>,
) -> impl IntoResponse {
    let mut scrapers = state.scrapers.write().await;
    scrapers.push(req.config.clone());

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "scraper_id": req.config.id
        })),
    )
}

// ============================================================================
// Pre-configured Scrapers
// ============================================================================

fn create_default_scrapers() -> Vec<ScraperConfig> {
    vec![
        // Example: Crypto prices from CoinGecko API
        ScraperConfig {
            id: "crypto-prices".to_string(),
            name: "Crypto Prices".to_string(),
            url: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd".to_string(),
            selectors: HashMap::new(), // API returns JSON, not HTML
            schedule_seconds: 300, // Every 5 minutes
            enabled: false, // Disabled until needed
        },
        // Add more pre-configured scrapers here
    ]
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Web Scraper");

    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (compatible; CoDriverAgency/1.0)")
        .build()?;

    let scrapers = create_default_scrapers();
    info!("Initialized with {} scrapers", scrapers.len());

    let state = Arc::new(AppState {
        scrapers: Arc::new(RwLock::new(scrapers)),
        recent_data: Arc::new(RwLock::new(Vec::new())),
        client,
    });

    // Start scraping task
    let scraping_state = Arc::clone(&state);
    tokio::spawn(async move {
        scraping_task(scraping_state).await;
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/scrapers", get(list_scrapers))
        .route("/scrapers", post(add_scraper))
        .route("/data", get(get_recent_data))
        .with_state(state);

    let addr = "127.0.0.1:9003";
    info!("Web Scraper listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
