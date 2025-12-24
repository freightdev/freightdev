// Vision Controller
// Image processing, analysis, and vision AI using Intel NPU on workbox
// Port: 9010

use axum::{
    extract::{Multipart, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use image::{DynamicImage, ImageFormat, Rgba};
use imageproc::drawing::*;
use imageproc::rect::Rect;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::Cursor;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::info;
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ImageAnalysisRequest {
    image_id: Option<String>,
    image_url: Option<String>,
    image_base64: Option<String>,
    operations: Vec<ImageOperation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum ImageOperation {
    Resize { width: u32, height: u32 },
    Crop { x: u32, y: u32, width: u32, height: u32 },
    Grayscale,
    Blur { sigma: f32 },
    EdgeDetect,
    Rotate { degrees: f32 },
    Brightness { factor: f32 },
    Contrast { factor: f32 },
    Annotate { boxes: Vec<BoundingBox> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct BoundingBox {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    label: String,
    confidence: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct VisionAnalysisRequest {
    image_id: String,
    model: VisionModel,
    prompt: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum VisionModel {
    LLaVA,          // Vision-language model
    ObjectDetection, // Object detection
    FaceDetection,   // Face detection
    OCR,            // Text extraction
    ImageCaption,   // Generate image captions
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ImageRecord {
    id: String,
    filename: String,
    format: String,
    width: u32,
    height: u32,
    size_bytes: usize,
    created_at: chrono::DateTime<chrono::Utc>,
    data: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalysisResult {
    image_id: String,
    analysis_type: String,
    result: serde_json::Value,
    processed_image_id: Option<String>,
    timestamp: chrono::DateTime<chrono::Utc>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    images: Arc<RwLock<HashMap<String, ImageRecord>>>,
    analyses: Arc<RwLock<Vec<AnalysisResult>>>,
    ollama_node: String, // workbox for vision tasks
}

// ============================================================================
// Image Processing
// ============================================================================

fn decode_image(data: &[u8]) -> Result<DynamicImage, String> {
    image::load_from_memory(data).map_err(|e| format!("Failed to decode image: {}", e))
}

fn encode_image(img: &DynamicImage, format: ImageFormat) -> Result<Vec<u8>, String> {
    let mut buffer = Cursor::new(Vec::new());
    img.write_to(&mut buffer, format)
        .map_err(|e| format!("Failed to encode image: {}", e))?;
    Ok(buffer.into_inner())
}

fn apply_operation(img: DynamicImage, operation: &ImageOperation) -> Result<DynamicImage, String> {
    match operation {
        ImageOperation::Resize { width, height } => {
            Ok(img.resize_exact(*width, *height, image::imageops::FilterType::Lanczos3))
        }
        ImageOperation::Crop { x, y, width, height } => {
            Ok(img.crop_imm(*x, *y, *width, *height))
        }
        ImageOperation::Grayscale => Ok(DynamicImage::ImageLuma8(img.to_luma8())),
        ImageOperation::Blur { sigma } => Ok(img.blur(*sigma)),
        ImageOperation::EdgeDetect => {
            // Simple edge detection using sobel
            let gray = img.to_luma8();
            let edges_u16 = imageproc::gradients::sobel_gradients(&gray);
            // Convert u16 to u8 by scaling down
            let edges = image::ImageBuffer::from_fn(edges_u16.width(), edges_u16.height(), |x, y| {
                let pixel = edges_u16.get_pixel(x, y);
                image::Luma([(pixel[0] / 256) as u8])
            });
            Ok(DynamicImage::ImageLuma8(edges))
        }
        ImageOperation::Rotate { degrees } => {
            // Rotate in 90-degree increments for simplicity
            let rotations = (degrees / 90.0).round() as i32;
            let mut result = img;
            for _ in 0..(rotations % 4).abs() {
                result = result.rotate90();
            }
            Ok(result)
        }
        ImageOperation::Brightness { factor } => Ok(img.brighten((*factor * 100.0) as i32)),
        ImageOperation::Contrast { factor } => {
            Ok(img.adjust_contrast(*factor))
        }
        ImageOperation::Annotate { boxes } => {
            let mut img_rgba = img.to_rgba8();
            for bbox in boxes {
                let rect = Rect::at(bbox.x as i32, bbox.y as i32)
                    .of_size(bbox.width, bbox.height);
                draw_hollow_rect_mut(
                    &mut img_rgba,
                    rect,
                    Rgba([255u8, 0u8, 0u8, 255u8]),
                );
                // Draw label background
                let label_y = if bbox.y > 20 { bbox.y - 20 } else { bbox.y + bbox.height };
                draw_filled_rect_mut(
                    &mut img_rgba,
                    Rect::at(bbox.x as i32, label_y as i32).of_size(100, 18),
                    Rgba([255u8, 0u8, 0u8, 200u8]),
                );
            }
            Ok(DynamicImage::ImageRgba8(img_rgba))
        }
    }
}

// ============================================================================
// Vision AI (using Ollama on workbox)
// ============================================================================

async fn analyze_with_ollama(
    node: &str,
    model: &VisionModel,
    image_base64: &str,
    prompt: Option<&str>,
) -> Result<serde_json::Value, String> {
    let url = format!("http://{}:11434/api/generate", node);

    let model_name = match model {
        VisionModel::LLaVA => "llava:latest",
        VisionModel::ImageCaption => "llava:latest",
        _ => return Ok(serde_json::json!({"note": "Model not yet integrated with Ollama"})),
    };

    let prompt_text = prompt.unwrap_or("Describe this image in detail.");

    let payload = serde_json::json!({
        "model": model_name,
        "prompt": prompt_text,
        "images": [image_base64],
        "stream": false
    });

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&payload)
        .timeout(std::time::Duration::from_secs(120))
        .send()
        .await
        .map_err(|e| format!("Ollama request failed: {}", e))?;

    let result: serde_json::Value = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;

    Ok(result)
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Vision Controller: ONLINE")
}

async fn upload_image(
    State(state): State<Arc<AppState>>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let mut image_data: Option<Vec<u8>> = None;
    let mut filename = String::from("unknown");

    while let Ok(Some(field)) = multipart.next_field().await {
        let field_name = field.name().unwrap_or("").to_string();

        if field_name == "image" {
            filename = field.file_name().unwrap_or("image.png").to_string();
            image_data = Some(field.bytes().await.unwrap_or_default().to_vec());
        }
    }

    let data = match image_data {
        Some(d) => d,
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "No image data provided"})),
            )
        }
    };

    // Decode image to get metadata
    let img = match decode_image(&data) {
        Ok(i) => i,
        Err(e) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": e})),
            )
        }
    };

    let id = Uuid::new_v4().to_string();
    let record = ImageRecord {
        id: id.clone(),
        filename,
        format: "png".to_string(),
        width: img.width(),
        height: img.height(),
        size_bytes: data.len(),
        created_at: chrono::Utc::now(),
        data,
    };

    let mut images = state.images.write().await;
    images.insert(id.clone(), record.clone());

    info!("Image uploaded: {} ({}x{})", id, img.width(), img.height());

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "image_id": id,
            "width": img.width(),
            "height": img.height(),
            "size_bytes": record.size_bytes
        })),
    )
}

async fn process_image(
    State(state): State<Arc<AppState>>,
    Json(req): Json<ImageAnalysisRequest>,
) -> impl IntoResponse {
    // Get image data
    let images = state.images.read().await;

    let image_data = if let Some(id) = &req.image_id {
        images.get(id).map(|r| r.data.clone())
    } else if let Some(base64_data) = &req.image_base64 {
        BASE64.decode(base64_data).ok()
    } else if let Some(_url) = &req.image_url {
        // TODO: Download from URL
        None
    } else {
        None
    };

    let data = match image_data {
        Some(d) => d,
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "Image not found"})),
            )
        }
    };

    drop(images);

    // Decode image
    let mut img = match decode_image(&data) {
        Ok(i) => i,
        Err(e) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": e})),
            )
        }
    };

    // Apply operations
    for operation in &req.operations {
        img = match apply_operation(img, operation) {
            Ok(i) => i,
            Err(e) => {
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(serde_json::json!({"error": e})),
                )
            }
        };
    }

    // Encode result
    let encoded = match encode_image(&img, ImageFormat::Png) {
        Ok(e) => e,
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": e})),
            )
        }
    };

    // Store processed image
    let processed_id = Uuid::new_v4().to_string();
    let record = ImageRecord {
        id: processed_id.clone(),
        filename: "processed.png".to_string(),
        format: "png".to_string(),
        width: img.width(),
        height: img.height(),
        size_bytes: encoded.len(),
        created_at: chrono::Utc::now(),
        data: encoded.clone(),
    };

    let mut images = state.images.write().await;
    images.insert(processed_id.clone(), record);

    info!("Image processed: {}", processed_id);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "processed_image_id": processed_id,
            "image_base64": BASE64.encode(&encoded),
            "width": img.width(),
            "height": img.height()
        })),
    )
}

async fn analyze_image(
    State(state): State<Arc<AppState>>,
    Json(req): Json<VisionAnalysisRequest>,
) -> impl IntoResponse {
    // Get image
    let images = state.images.read().await;
    let image_record = match images.get(&req.image_id) {
        Some(r) => r.clone(),
        None => {
            return (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "Image not found"})),
            )
        }
    };
    drop(images);

    // Encode image as base64
    let image_base64 = BASE64.encode(&image_record.data);

    // Analyze with Ollama
    let analysis = analyze_with_ollama(
        &state.ollama_node,
        &req.model,
        &image_base64,
        req.prompt.as_deref(),
    )
    .await
    .unwrap_or_else(|e| serde_json::json!({"error": e}));

    // Store analysis result
    let result = AnalysisResult {
        image_id: req.image_id.clone(),
        analysis_type: format!("{:?}", req.model),
        result: analysis.clone(),
        processed_image_id: None,
        timestamp: chrono::Utc::now(),
    };

    let mut analyses = state.analyses.write().await;
    analyses.push(result);

    info!("Image analyzed: {} using {:?}", req.image_id, req.model);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "analysis": analysis
        })),
    )
}

async fn list_images(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let images = state.images.read().await;
    let image_list: Vec<_> = images
        .values()
        .map(|r| {
            serde_json::json!({
                "id": r.id,
                "filename": r.filename,
                "format": r.format,
                "width": r.width,
                "height": r.height,
                "size_bytes": r.size_bytes,
                "created_at": r.created_at
            })
        })
        .collect();

    (StatusCode::OK, Json(serde_json::json!(image_list)))
}

async fn get_image(
    State(state): State<Arc<AppState>>,
    Json(req): Json<serde_json::Value>,
) -> impl IntoResponse {
    let image_id = req["image_id"].as_str().unwrap_or("");

    let images = state.images.read().await;
    let image_record = match images.get(image_id) {
        Some(r) => r.clone(),
        None => {
            return (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "Image not found"})),
            )
        }
    };

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "image_id": image_record.id,
            "filename": image_record.filename,
            "format": image_record.format,
            "width": image_record.width,
            "height": image_record.height,
            "image_base64": BASE64.encode(&image_record.data)
        })),
    )
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Vision Controller");
    info!("Intel NPU acceleration available on workbox (192.168.12.136)");

    let state = Arc::new(AppState {
        images: Arc::new(RwLock::new(HashMap::new())),
        analyses: Arc::new(RwLock::new(Vec::new())),
        ollama_node: "192.168.12.136".to_string(), // workbox with NPU
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/upload", post(upload_image))
        .route("/process", post(process_image))
        .route("/analyze", post(analyze_image))
        .route("/images", get(list_images))
        .route("/image/get", post(get_image))
        .with_state(state);

    let addr = "127.0.0.1:9010";
    info!("Vision Controller listening on {}", addr);
    info!("Using Ollama on workbox for vision AI");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
