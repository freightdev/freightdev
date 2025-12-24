// Lead Scraper Agent
// Scrapes Reddit, HackerNews, and other sources for potential agency clients

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use reqwest::Client;
use scraper::{Html, Selector};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, warn};
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Lead {
    id: String,
    source: String,
    source_url: String,
    title: String,
    description: Option<String>,
    author: Option<String>,
    status: String,
    created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapeRequest {
    source: String,
    keywords: Option<Vec<String>>,
    limit: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ScrapeResponse {
    success: bool,
    leads_found: usize,
    leads: Vec<Lead>,
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
    database_manager_url: String,
    leads: Arc<RwLock<Vec<Lead>>>,
}

// ============================================================================
// Reddit Scraper
// ============================================================================

async fn scrape_reddit(client: &Client, keywords: &[String], limit: usize) -> anyhow::Result<Vec<Lead>> {
    let mut leads = Vec::new();

    // Search relevant subreddits
    let subreddits = vec![
        "startups",
        "entrepreneur",
        "SaaS",
        "webdev",
        "programming",
        "smallbusiness",
        "forhire",
    ];

    for subreddit in subreddits {
        info!("Scraping r/{}", subreddit);

        let url = format!("https://www.reddit.com/r/{}/new.json?limit={}", subreddit, limit);

        match client.get(&url)
            .header("User-Agent", "LeadScraperBot/1.0")
            .send()
            .await {
            Ok(response) => {
                if let Ok(json) = response.json::<serde_json::Value>().await {
                    if let Some(posts) = json["data"]["children"].as_array() {
                        for post in posts {
                            let post_data = &post["data"];
                            let title = post_data["title"].as_str().unwrap_or("").to_string();

                            // Filter by keywords if provided
                            if !keywords.is_empty() {
                                let title_lower = title.to_lowercase();
                                if !keywords.iter().any(|kw| title_lower.contains(&kw.to_lowercase())) {
                                    continue;
                                }
                            }

                            let lead = Lead {
                                id: Uuid::new_v4().to_string(),
                                source: format!("reddit-r/{}", subreddit),
                                source_url: format!("https://reddit.com{}", post_data["permalink"].as_str().unwrap_or("")),
                                title,
                                description: post_data["selftext"].as_str().map(|s| s.to_string()),
                                author: post_data["author"].as_str().map(|s| s.to_string()),
                                status: "new".to_string(),
                                created_at: Utc::now(),
                            };

                            leads.push(lead);
                        }
                    }
                }
            }
            Err(e) => {
                warn!("Failed to scrape r/{}: {}", subreddit, e);
            }
        }

        // Rate limiting
        tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
    }

    Ok(leads)
}

// ============================================================================
// HackerNews Scraper
// ============================================================================

async fn scrape_hackernews(client: &Client, keywords: &[String], limit: usize) -> anyhow::Result<Vec<Lead>> {
    let mut leads = Vec::new();

    info!("Scraping HackerNews");

    // Get latest stories
    let url = "https://hacker-news.firebaseio.com/v0/newstories.json";

    match client.get(url).send().await {
        Ok(response) => {
            if let Ok(story_ids) = response.json::<Vec<u64>>().await {
                for story_id in story_ids.iter().take(limit) {
                    let story_url = format!("https://hacker-news.firebaseio.com/v0/item/{}.json", story_id);

                    if let Ok(story_response) = client.get(&story_url).send().await {
                        if let Ok(story) = story_response.json::<serde_json::Value>().await {
                            let title = story["title"].as_str().unwrap_or("").to_string();

                            // Filter by keywords
                            if !keywords.is_empty() {
                                let title_lower = title.to_lowercase();
                                let text = story["text"].as_str().unwrap_or("");
                                let text_lower = text.to_lowercase();

                                if !keywords.iter().any(|kw| {
                                    let kw_lower = kw.to_lowercase();
                                    title_lower.contains(&kw_lower) || text_lower.contains(&kw_lower)
                                }) {
                                    continue;
                                }
                            }

                            let lead = Lead {
                                id: Uuid::new_v4().to_string(),
                                source: "hackernews".to_string(),
                                source_url: format!("https://news.ycombinator.com/item?id={}", story_id),
                                title,
                                description: story["text"].as_str().map(|s| s.to_string()),
                                author: story["by"].as_str().map(|s| s.to_string()),
                                status: "new".to_string(),
                                created_at: Utc::now(),
                            };

                            leads.push(lead);
                        }
                    }

                    // Rate limiting
                    tokio::time::sleep(tokio::time::Duration::from_millis(200)).await;
                }
            }
        }
        Err(e) => {
            error!("Failed to scrape HackerNews: {}", e);
        }
    }

    Ok(leads)
}

// ============================================================================
// API Handlers
// ============================================================================

async fn health_handler(
    Query(params): Query<HealthQuery>,
) -> impl IntoResponse {
    if params.detailed.unwrap_or(false) {
        Json(serde_json::json!({
            "status": "ok",
            "service": "lead-scraper",
            "version": "0.1.0",
            "timestamp": Utc::now().to_rfc3339()
        }))
    } else {
        Json(serde_json::json!({ "status": "ok" }))
    }
}

async fn scrape_handler(
    State(state): State<Arc<AppState>>,
    Json(request): Json<ScrapeRequest>,
) -> Result<Json<ScrapeResponse>, StatusCode> {
    info!("Received scrape request for source: {}", request.source);

    let keywords = request.keywords.unwrap_or_else(|| vec![
        "need a website".to_string(),
        "looking for developer".to_string(),
        "hiring".to_string(),
        "web development".to_string(),
        "need help with".to_string(),
        "looking for agency".to_string(),
    ]);

    let limit = request.limit.unwrap_or(50);

    let leads = match request.source.as_str() {
        "reddit" => scrape_reddit(&state.http_client, &keywords, limit).await.unwrap_or_default(),
        "hackernews" | "hn" => scrape_hackernews(&state.http_client, &keywords, limit).await.unwrap_or_default(),
        "all" => {
            let mut all_leads = Vec::new();
            all_leads.extend(scrape_reddit(&state.http_client, &keywords, limit).await.unwrap_or_default());
            all_leads.extend(scrape_hackernews(&state.http_client, &keywords, limit).await.unwrap_or_default());
            all_leads
        }
        _ => {
            warn!("Unknown source: {}", request.source);
            return Err(StatusCode::BAD_REQUEST);
        }
    };

    let leads_count = leads.len();

    // Store leads in memory
    {
        let mut state_leads = state.leads.write().await;
        state_leads.extend(leads.clone());
    }

    // Send to database-manager
    for lead in &leads {
        if let Err(e) = send_to_database(&state, lead).await {
            warn!("Failed to send lead to database: {}", e);
        }
    }

    info!("Found {} leads", leads_count);

    Ok(Json(ScrapeResponse {
        success: true,
        leads_found: leads_count,
        leads,
    }))
}

async fn send_to_database(state: &AppState, lead: &Lead) -> anyhow::Result<()> {
    let query = format!(
        "CREATE leads SET id = '{}', source = '{}', source_url = '{}', title = '{}', description = {}, author = {}, status = '{}', created_at = time::now()",
        lead.id,
        lead.source,
        lead.source_url,
        lead.title.replace('\'', "\\'"),
        lead.description.as_ref().map(|d| format!("'{}'", d.replace('\'', "\\'"))).unwrap_or("NONE".to_string()),
        lead.author.as_ref().map(|a| format!("'{}'", a.replace('\'', "\\'"))).unwrap_or("NONE".to_string()),
        lead.status
    );

    let db_request = serde_json::json!({
        "query": query
    });

    state.http_client
        .post(&format!("{}/query", state.database_manager_url))
        .json(&db_request)
        .send()
        .await?;

    Ok(())
}

async fn list_leads_handler(
    State(state): State<Arc<AppState>>,
) -> Json<Vec<Lead>> {
    let leads = state.leads.read().await;
    Json(leads.clone())
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter("lead_scraper=info,tower_http=debug")
        .init();

    info!("Starting lead-scraper agent");

    // Create HTTP client
    let http_client = Client::builder()
        .user_agent("LeadScraperBot/1.0")
        .timeout(std::time::Duration::from_secs(30))
        .build()?;

    // Create application state
    let state = Arc::new(AppState {
        http_client,
        database_manager_url: std::env::var("DATABASE_MANAGER_URL")
            .unwrap_or_else(|_| "http://localhost:9012".to_string()),
        leads: Arc::new(RwLock::new(Vec::new())),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health_handler))
        .route("/scrape", post(scrape_handler))
        .route("/leads", get(list_leads_handler))
        .with_state(state);

    // Start server
    let addr = "0.0.0.0:9013";
    info!("Lead scraper listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
