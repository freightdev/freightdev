// Web Search Agent
// Search engines, web scraping, and content extraction for autonomous research
// Port: 9003

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use scraper::{Html, Selector};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::info;
use url::Url;
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SearchRequest {
    query: String,
    engine: Option<SearchEngine>,
    max_results: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum SearchEngine {
    DuckDuckGo,
    // Google, Bing can be added later with API keys
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SearchResult {
    id: String,
    query: String,
    results: Vec<SearchItem>,
    timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SearchItem {
    title: String,
    url: String,
    snippet: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapeRequest {
    url: String,
    extract_links: Option<bool>,
    extract_images: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapedContent {
    url: String,
    title: String,
    text_content: String,
    links: Vec<String>,
    images: Vec<String>,
    metadata: HashMap<String, String>,
    scraped_at: chrono::DateTime<chrono::Utc>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    search_cache: Arc<RwLock<HashMap<String, SearchResult>>>,
    scrape_cache: Arc<RwLock<HashMap<String, ScrapedContent>>>,
    client: reqwest::Client,
}

// ============================================================================
// Search Functions
// ============================================================================

async fn search_duckduckgo(
    client: &reqwest::Client,
    query: &str,
    max_results: usize,
) -> Result<Vec<SearchItem>, String> {
    let search_url = format!("https://html.duckduckgo.com/html/?q={}",
        urlencoding::encode(query));

    info!("Searching DuckDuckGo for: {}", query);

    let response = client
        .get(&search_url)
        .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36")
        .send()
        .await
        .map_err(|e| format!("Request failed: {}", e))?;

    let html = response
        .text()
        .await
        .map_err(|e| format!("Failed to get response text: {}", e))?;

    let document = Html::parse_document(&html);

    // DuckDuckGo result selectors
    let result_selector = Selector::parse(".result").unwrap();
    let title_selector = Selector::parse(".result__title").unwrap();
    let link_selector = Selector::parse(".result__url").unwrap();
    let snippet_selector = Selector::parse(".result__snippet").unwrap();

    let mut results = Vec::new();

    for element in document.select(&result_selector).take(max_results) {
        let title = element
            .select(&title_selector)
            .next()
            .map(|e| e.text().collect::<String>())
            .unwrap_or_default()
            .trim()
            .to_string();

        let url = element
            .select(&link_selector)
            .next()
            .map(|e| e.text().collect::<String>())
            .unwrap_or_default()
            .trim()
            .to_string();

        let snippet = element
            .select(&snippet_selector)
            .next()
            .map(|e| e.text().collect::<String>())
            .unwrap_or_default()
            .trim()
            .to_string();

        if !title.is_empty() && !url.is_empty() {
            results.push(SearchItem {
                title,
                url: if url.starts_with("http") {
                    url
                } else {
                    format!("https://{}", url)
                },
                snippet,
            });
        }
    }

    Ok(results)
}

// ============================================================================
// Scraping Functions
// ============================================================================

async fn scrape_webpage(
    client: &reqwest::Client,
    url: &str,
    extract_links: bool,
    extract_images: bool,
) -> Result<ScrapedContent, String> {
    info!("Scraping URL: {}", url);

    let response = client
        .get(url)
        .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36")
        .send()
        .await
        .map_err(|e| format!("Request failed: {}", e))?;

    let html = response
        .text()
        .await
        .map_err(|e| format!("Failed to get response text: {}", e))?;

    let document = Html::parse_document(&html);

    // Extract title
    let title_selector = Selector::parse("title").unwrap();
    let title = document
        .select(&title_selector)
        .next()
        .map(|e| e.text().collect::<String>())
        .unwrap_or_default()
        .trim()
        .to_string();

    // Extract text content (paragraphs)
    let p_selector = Selector::parse("p").unwrap();
    let text_content: String = document
        .select(&p_selector)
        .map(|e| e.text().collect::<String>())
        .collect::<Vec<_>>()
        .join(" ")
        .chars()
        .take(5000) // Limit to first 5000 chars
        .collect();

    // Extract links if requested
    let mut links = Vec::new();
    if extract_links {
        let link_selector = Selector::parse("a[href]").unwrap();
        let base_url = Url::parse(url).ok();

        for element in document.select(&link_selector) {
            if let Some(href) = element.value().attr("href") {
                if let Some(ref base) = base_url {
                    if let Ok(absolute_url) = base.join(href) {
                        links.push(absolute_url.to_string());
                    }
                } else if href.starts_with("http") {
                    links.push(href.to_string());
                }
            }
        }
    }

    // Extract images if requested
    let mut images = Vec::new();
    if extract_images {
        let img_selector = Selector::parse("img[src]").unwrap();
        let base_url = Url::parse(url).ok();

        for element in document.select(&img_selector) {
            if let Some(src) = element.value().attr("src") {
                if let Some(ref base) = base_url {
                    if let Ok(absolute_url) = base.join(src) {
                        images.push(absolute_url.to_string());
                    }
                } else if src.starts_with("http") {
                    images.push(src.to_string());
                }
            }
        }
    }

    // Extract metadata
    let mut metadata = HashMap::new();
    let meta_selector = Selector::parse("meta").unwrap();
    for element in document.select(&meta_selector) {
        if let Some(name) = element.value().attr("name").or(element.value().attr("property")) {
            if let Some(content) = element.value().attr("content") {
                metadata.insert(name.to_string(), content.to_string());
            }
        }
    }

    Ok(ScrapedContent {
        url: url.to_string(),
        title,
        text_content,
        links,
        images,
        metadata,
        scraped_at: chrono::Utc::now(),
    })
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Web Search Agent: ONLINE")
}

async fn search_web(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SearchRequest>,
) -> impl IntoResponse {
    let engine = req.engine.unwrap_or(SearchEngine::DuckDuckGo);
    let max_results = req.max_results.unwrap_or(10).min(50);

    // Check cache first
    let cache_key = format!("{:?}:{}", engine, req.query);
    {
        let cache = state.search_cache.read().await;
        if let Some(cached) = cache.get(&cache_key) {
            info!("Returning cached search results for: {}", req.query);
            return (StatusCode::OK, Json(serde_json::json!(cached)));
        }
    }

    // Perform search
    let results = match engine {
        SearchEngine::DuckDuckGo => {
            match search_duckduckgo(&state.client, &req.query, max_results).await {
                Ok(r) => r,
                Err(e) => {
                    return (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(serde_json::json!({"error": e})),
                    )
                }
            }
        }
    };

    let search_result = SearchResult {
        id: Uuid::new_v4().to_string(),
        query: req.query.clone(),
        results,
        timestamp: chrono::Utc::now(),
    };

    // Cache the results
    let mut cache = state.search_cache.write().await;
    cache.insert(cache_key, search_result.clone());

    info!("Search completed for: {}", req.query);

    (StatusCode::OK, Json(serde_json::json!(search_result)))
}

async fn scrape_url(
    State(state): State<Arc<AppState>>,
    Json(req): Json<ScrapeRequest>,
) -> impl IntoResponse {
    // Check cache first
    {
        let cache = state.scrape_cache.read().await;
        if let Some(cached) = cache.get(&req.url) {
            info!("Returning cached scrape for: {}", req.url);
            return (StatusCode::OK, Json(serde_json::json!(cached)));
        }
    }

    // Perform scrape
    let extract_links = req.extract_links.unwrap_or(true);
    let extract_images = req.extract_images.unwrap_or(false);

    match scrape_webpage(&state.client, &req.url, extract_links, extract_images).await {
        Ok(content) => {
            // Cache the results
            let mut cache = state.scrape_cache.write().await;
            cache.insert(req.url.clone(), content.clone());

            info!("Scraping completed for: {}", req.url);

            (StatusCode::OK, Json(serde_json::json!(content)))
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": e})),
        ),
    }
}

async fn clear_cache(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let mut search_cache = state.search_cache.write().await;
    let mut scrape_cache = state.scrape_cache.write().await;

    let search_count = search_cache.len();
    let scrape_count = scrape_cache.len();

    search_cache.clear();
    scrape_cache.clear();

    info!("Cache cleared: {} searches, {} scrapes", search_count, scrape_count);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "cleared": {
                "searches": search_count,
                "scrapes": scrape_count
            }
        })),
    )
}

async fn get_stats(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let search_cache = state.search_cache.read().await;
    let scrape_cache = state.scrape_cache.read().await;

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "cached_searches": search_cache.len(),
            "cached_scrapes": scrape_cache.len()
        })),
    )
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Web Search Agent");

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()?;

    let state = Arc::new(AppState {
        search_cache: Arc::new(RwLock::new(HashMap::new())),
        scrape_cache: Arc::new(RwLock::new(HashMap::new())),
        client,
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/search", post(search_web))
        .route("/scrape", post(scrape_url))
        .route("/cache/clear", post(clear_cache))
        .route("/stats", get(get_stats))
        .with_state(state);

    let addr = "127.0.0.1:9003";
    info!("Web Search Agent listening on {}", addr);
    info!("Supports: DuckDuckGo search, web scraping, content extraction");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
