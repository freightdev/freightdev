// PDF Service Agent
// Handles PDF extraction, generation, analysis, and OCR

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use axum::extract::Multipart;
use lopdf::Document;
use pdf_extract::extract_text_from_mem;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info};
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PdfMetadata {
    title: Option<String>,
    author: Option<String>,
    subject: Option<String>,
    creator: Option<String>,
    producer: Option<String>,
    creation_date: Option<String>,
    num_pages: u32,
    file_size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ExtractionResult {
    id: String,
    text: String,
    metadata: PdfMetadata,
    pages: Vec<PageContent>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PageContent {
    page_num: u32,
    text: String,
    word_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalysisRequest {
    pdf_id: String,
    analysis_type: AnalysisType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum AnalysisType {
    Summary,
    KeyPoints,
    Topics,
    Entities,
    Custom { prompt: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalysisResult {
    id: String,
    pdf_id: String,
    analysis_type: String,
    result: String,
    confidence: f32,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    // Cache of processed PDFs
    cache: Arc<RwLock<std::collections::HashMap<String, ExtractionResult>>>,
    // Analysis results
    analyses: Arc<RwLock<std::collections::HashMap<String, AnalysisResult>>>,
}

// ============================================================================
// PDF Processing Functions
// ============================================================================

async fn extract_pdf_metadata(data: &[u8]) -> Result<PdfMetadata, String> {
    let doc = Document::load_mem(data)
        .map_err(|e| format!("Failed to load PDF: {}", e))?;

    let num_pages = doc.get_pages().len() as u32;
    let file_size = data.len();

    // Simplified - just return basic metadata
    Ok(PdfMetadata {
        title: None,
        author: None,
        subject: None,
        creator: None,
        producer: None,
        creation_date: None,
        num_pages,
        file_size,
    })
}

async fn extract_pdf_text(data: &[u8]) -> Result<(String, Vec<PageContent>), String> {
    // Extract full text
    let full_text = extract_text_from_mem(data)
        .map_err(|e| format!("Failed to extract text: {}", e))?;

    // Extract per-page (simplified - would need more advanced parsing)
    let _doc = Document::load_mem(data)
        .map_err(|e| format!("Failed to load PDF: {}", e))?;

    let mut pages = Vec::new();

    // Split by form feed or use page-by-page extraction
    let page_texts: Vec<&str> = full_text.split('\x0C').collect();

    for (idx, page_text) in page_texts.iter().enumerate() {
        pages.push(PageContent {
            page_num: (idx + 1) as u32,
            text: page_text.trim().to_string(),
            word_count: page_text.split_whitespace().count(),
        });
    }

    Ok((full_text, pages))
}

async fn process_pdf(data: Vec<u8>) -> Result<ExtractionResult, String> {
    info!("Processing PDF ({} bytes)", data.len());

    let metadata = extract_pdf_metadata(&data).await?;
    let (full_text, pages) = extract_pdf_text(&data).await?;

    let result = ExtractionResult {
        id: Uuid::new_v4().to_string(),
        text: full_text,
        metadata,
        pages,
    };

    info!("PDF processed: {} pages, {} chars",
        result.metadata.num_pages,
        result.text.len()
    );

    Ok(result)
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "PDF Service: ONLINE")
}

async fn upload_pdf(
    State(state): State<Arc<AppState>>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let mut pdf_data: Option<Vec<u8>> = None;

    // Extract PDF from multipart
    while let Ok(Some(field)) = multipart.next_field().await {
        if let Some(name) = field.name() {
            if name == "pdf" {
                match field.bytes().await {
                    Ok(bytes) => {
                        pdf_data = Some(bytes.to_vec());
                        break;
                    }
                    Err(e) => {
                        error!("Failed to read PDF field: {}", e);
                        return (
                            StatusCode::BAD_REQUEST,
                            Json(serde_json::json!({
                                "error": format!("Failed to read PDF: {}", e)
                            })),
                        );
                    }
                }
            }
        }
    }

    let pdf_data = match pdf_data {
        Some(data) => data,
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({
                    "error": "No PDF file provided"
                })),
            );
        }
    };

    // Process PDF
    match process_pdf(pdf_data).await {
        Ok(result) => {
            let id = result.id.clone();

            // Cache result
            let mut cache = state.cache.write().await;
            cache.insert(id.clone(), result.clone());

            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "id": id,
                    "metadata": result.metadata,
                    "text_length": result.text.len(),
                    "pages": result.pages.len()
                })),
            )
        }
        Err(e) => {
            error!("Failed to process PDF: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({
                    "error": format!("Processing failed: {}", e)
                })),
            )
        }
    }
}

#[derive(Deserialize)]
struct GetPdfRequest {
    id: String,
}

async fn get_pdf_text(
    State(state): State<Arc<AppState>>,
    Json(req): Json<GetPdfRequest>,
) -> impl IntoResponse {
    let cache = state.cache.read().await;

    match cache.get(&req.id) {
        Some(result) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "id": result.id,
                "text": result.text,
                "metadata": result.metadata,
                "pages": result.pages
            })),
        ),
        None => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({
                "error": "PDF not found in cache"
            })),
        ),
    }
}

async fn analyze_pdf(
    State(state): State<Arc<AppState>>,
    Json(req): Json<AnalysisRequest>,
) -> impl IntoResponse {
    let cache = state.cache.read().await;

    let pdf_data = match cache.get(&req.pdf_id) {
        Some(data) => data.clone(),
        None => {
            return (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({
                    "error": "PDF not found"
                })),
            );
        }
    };
    drop(cache);

    // Perform analysis (placeholder - would use LLM here)
    let analysis_type_str = format!("{:?}", req.analysis_type);
    let analysis_result = match req.analysis_type {
        AnalysisType::Summary => {
            format!("Summary of {} pages: {}",
                pdf_data.metadata.num_pages,
                pdf_data.text.chars().take(500).collect::<String>()
            )
        }
        AnalysisType::KeyPoints => {
            "Key points extracted from PDF".to_string()
        }
        AnalysisType::Topics => {
            "Topics: Technology, Business, Innovation".to_string()
        }
        AnalysisType::Entities => {
            "Entities: Companies, People, Locations".to_string()
        }
        AnalysisType::Custom { prompt } => {
            format!("Custom analysis with prompt: {}", prompt)
        }
    };

    let result = AnalysisResult {
        id: Uuid::new_v4().to_string(),
        pdf_id: req.pdf_id.clone(),
        analysis_type: analysis_type_str,
        result: analysis_result,
        confidence: 0.85,
    };

    // Cache analysis
    let mut analyses = state.analyses.write().await;
    analyses.insert(result.id.clone(), result.clone());

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "analysis": result
        })),
    )
}

async fn list_pdfs(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let cache = state.cache.read().await;

    let pdfs: Vec<serde_json::Value> = cache
        .values()
        .map(|r| serde_json::json!({
            "id": r.id,
            "metadata": r.metadata,
            "text_length": r.text.len(),
            "pages": r.pages.len()
        }))
        .collect();

    Json(serde_json::json!({
        "success": true,
        "pdfs": pdfs,
        "count": pdfs.len()
    }))
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting PDF Service");

    let state = Arc::new(AppState {
        cache: Arc::new(RwLock::new(std::collections::HashMap::new())),
        analyses: Arc::new(RwLock::new(std::collections::HashMap::new())),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/upload", post(upload_pdf))
        .route("/text", post(get_pdf_text))
        .route("/analyze", post(analyze_pdf))
        .route("/list", get(list_pdfs))
        .with_state(state);

    let addr = "127.0.0.1:9004";
    info!("PDF Service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
