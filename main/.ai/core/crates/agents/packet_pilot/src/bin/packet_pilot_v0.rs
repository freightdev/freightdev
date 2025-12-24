// PacketPilot v0.0.1
// Automates all paperwork required to set up freight loads
// Designed to be called by CoDriver coordinator

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tokio::fs;
use tracing::{info, warn, error};

mod email_monitor;
mod pdf_processor;
mod form_filler;
mod protocol_detector;
mod signature_handler;

use email_monitor::EmailMonitor;
use pdf_processor::PdfProcessor;
use form_filler::FormFiller;
use protocol_detector::ProtocolDetector;
use signature_handler::SignatureHandler;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "PP";
const AGENT_NAME: &str = "PacketPilot";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "If it sets the load, PacketPilot handles it.";

// ============================================================================
// DATA STRUCTURES
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct PacketRequest {
    pub request_type: PacketRequestType,
    pub data: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum PacketRequestType {
    #[serde(rename = "fill_packet")]
    FillPacket {
        broker_name: String,
        packet_url: Option<String>,
        packet_pdf: Option<String>, // base64 encoded
    },
    
    #[serde(rename = "sign_ratecon")]
    SignRatecon {
        ratecon_pdf: String, // base64 encoded
        signature_image: Option<String>,
    },
    
    #[serde(rename = "monitor_email")]
    MonitorEmail {
        email_address: String,
        keywords: Vec<String>,
    },
    
    #[serde(rename = "fill_online_form")]
    FillOnlineForm {
        form_url: String,
        form_data: serde_json::Value,
    },
    
    #[serde(rename = "detect_protocol")]
    DetectProtocol {
        broker_name: String,
    },
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PacketResponse {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub execution_time_ms: u128,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PacketResult {
    pub packet_id: String,
    pub status: PacketStatus,
    pub completed_document: Option<String>, // base64 encoded PDF
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum PacketStatus {
    Completed,
    PartiallyCompleted,
    Failed,
    ManualReviewRequired,
}

// ============================================================================
// PACKETPILOT AGENT
// ============================================================================

pub struct PacketPilot {
    email_monitor: EmailMonitor,
    pdf_processor: PdfProcessor,
    form_filler: FormFiller,
    protocol_detector: ProtocolDetector,
    signature_handler: SignatureHandler,
    working_dir: PathBuf,
}

impl PacketPilot {
    pub async fn new() -> Result<Self> {
        info!("🚀 Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("📋 {}", AGENT_TAGLINE);
        
        // Create working directory
        let working_dir = PathBuf::from("/tmp/packetpilot");
        fs::create_dir_all(&working_dir).await
            .context("Failed to create working directory")?;
        
        Ok(Self {
            email_monitor: EmailMonitor::new(),
            pdf_processor: PdfProcessor::new(),
            form_filler: FormFiller::new().await?,
            protocol_detector: ProtocolDetector::new(),
            signature_handler: SignatureHandler::new()?,
            working_dir,
        })
    }
    
    pub async fn handle_request(&mut self, request: PacketRequest) -> Result<PacketResponse> {
        let start = std::time::Instant::now();
        
        info!("📥 Handling request: {:?}", request.request_type);
        
        let result = match request.request_type {
            PacketRequestType::FillPacket { broker_name, packet_url, packet_pdf } => {
                self.fill_packet(broker_name, packet_url, packet_pdf).await
            }
            
            PacketRequestType::SignRatecon { ratecon_pdf, signature_image } => {
                self.sign_ratecon(ratecon_pdf, signature_image).await
            }
            
            PacketRequestType::MonitorEmail { email_address, keywords } => {
                self.monitor_email(email_address, keywords).await
            }
            
            PacketRequestType::FillOnlineForm { form_url, form_data } => {
                self.fill_online_form(form_url, form_data).await
            }
            
            PacketRequestType::DetectProtocol { broker_name } => {
                self.detect_protocol(broker_name).await
            }
        };
        
        let execution_time_ms = start.elapsed().as_millis();
        
        match result {
            Ok(data) => Ok(PacketResponse {
                success: true,
                message: "Request completed successfully".to_string(),
                data: Some(data),
                execution_time_ms,
            }),
            Err(e) => {
                error!("❌ Request failed: {}", e);
                Ok(PacketResponse {
                    success: false,
                    message: format!("Request failed: {}", e),
                    data: None,
                    execution_time_ms,
                })
            }
        }
    }
    
    // ========================================================================
    // CORE CAPABILITIES
    // ========================================================================
    
    async fn fill_packet(
        &mut self,
        broker_name: String,
        packet_url: Option<String>,
        packet_pdf: Option<String>,
    ) -> Result<serde_json::Value> {
        info!("📄 Filling packet for broker: {}", broker_name);
        
        // Step 1: Detect protocol for this broker
        let protocol = self.protocol_detector.detect(&broker_name).await?;
        info!("✓ Detected protocol: {}", protocol.name);
        
        // Step 2: Get the packet (download or decode)
        let pdf_bytes = if let Some(url) = packet_url {
            info!("📥 Downloading packet from: {}", url);
            self.download_packet(&url).await?
        } else if let Some(base64_pdf) = packet_pdf {
            info!("📥 Decoding provided PDF");
            base64::decode(base64_pdf)?
        } else {
            anyhow::bail!("No packet URL or PDF provided");
        };
        
        // Step 3: Process the PDF
        let filled_pdf = self.pdf_processor.fill_fields(
            &pdf_bytes,
            &protocol.field_mappings,
        ).await?;
        
        // Step 4: Encode result
        let result_base64 = base64::encode(&filled_pdf);
        
        Ok(serde_json::json!({
            "packet_id": uuid::Uuid::new_v4().to_string(),
            "broker": broker_name,
            "status": "completed",
            "filled_pdf": result_base64,
        }))
    }
    
    async fn sign_ratecon(
        &mut self,
        ratecon_pdf: String,
        signature_image: Option<String>,
    ) -> Result<serde_json::Value> {
        info!("✍️  Signing rate confirmation");
        
        // Decode PDF
        let pdf_bytes = base64::decode(ratecon_pdf)?;
        
        // Sign it
        let signed_pdf = self.signature_handler.sign_pdf(
            &pdf_bytes,
            signature_image.as_deref(),
        ).await?;
        
        // Encode result
        let result_base64 = base64::encode(&signed_pdf);
        
        Ok(serde_json::json!({
            "status": "signed",
            "signed_pdf": result_base64,
        }))
    }
    
    async fn monitor_email(
        &mut self,
        email_address: String,
        keywords: Vec<String>,
    ) -> Result<serde_json::Value> {
        info!("📧 Monitoring email: {}", email_address);
        
        let messages = self.email_monitor.check_inbox(
            &email_address,
            &keywords,
        ).await?;
        
        Ok(serde_json::json!({
            "found_messages": messages.len(),
            "messages": messages,
        }))
    }
    
    async fn fill_online_form(
        &mut self,
        form_url: String,
        form_data: serde_json::Value,
    ) -> Result<serde_json::Value> {
        info!("🌐 Filling online form: {}", form_url);
        
        let result = self.form_filler.fill_form(
            &form_url,
            &form_data,
        ).await?;
        
        Ok(serde_json::json!({
            "status": "submitted",
            "confirmation": result.confirmation_number,
            "screenshot": result.screenshot_base64,
        }))
    }
    
    async fn detect_protocol(
        &mut self,
        broker_name: String,
    ) -> Result<serde_json::Value> {
        info!("🔍 Detecting protocol for: {}", broker_name);
        
        let protocol = self.protocol_detector.detect(&broker_name).await?;
        
        Ok(serde_json::json!({
            "broker": broker_name,
            "protocol": protocol.name,
            "submission_method": protocol.submission_method,
            "required_fields": protocol.field_mappings.keys().collect::<Vec<_>>(),
        }))
    }
    
    // ========================================================================
    // HELPERS
    // ========================================================================
    
    async fn download_packet(&self, url: &str) -> Result<Vec<u8>> {
        let response = reqwest::get(url).await?;
        let bytes = response.bytes().await?;
        Ok(bytes.to_vec())
    }
}

// ============================================================================
// CODRIVER INTEGRATION
// ============================================================================

/// This is the main entry point that CoDriver will call
#[derive(Debug, Serialize, Deserialize)]
pub struct CoDriverRequest {
    pub intent: String,
    pub payload: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CoDriverResponse {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
}

pub async fn handle_codriver_request(request: CoDriverRequest) -> CoDriverResponse {
    let mut pilot = match PacketPilot::new().await {
        Ok(p) => p,
        Err(e) => {
            return CoDriverResponse {
                success: false,
                message: format!("Failed to initialize PacketPilot: {}", e),
                data: None,
            }
        }
    };
    
    // Parse intent and convert to PacketRequest
    let packet_request = match request.intent.as_str() {
        "fill_packet" => {
            serde_json::from_value::<PacketRequest>(request.payload)
        }
        "sign_ratecon" => {
            serde_json::from_value::<PacketRequest>(request.payload)
        }
        _ => {
            return CoDriverResponse {
                success: false,
                message: format!("Unknown intent: {}", request.intent),
                data: None,
            }
        }
    };
    
    let packet_request = match packet_request {
        Ok(req) => req,
        Err(e) => {
            return CoDriverResponse {
                success: false,
                message: format!("Invalid request format: {}", e),
                data: None,
            }
        }
    };
    
    // Handle the request
    match pilot.handle_request(packet_request).await {
        Ok(response) => CoDriverResponse {
            success: response.success,
            message: response.message,
            data: response.data,
        },
        Err(e) => CoDriverResponse {
            success: false,
            message: format!("Request failed: {}", e),
            data: None,
        },
    }
}

// ============================================================================
// MAIN (for standalone mode)
// ============================================================================

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    
    info!("🚀 {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("📋 {}", AGENT_TAGLINE);
    
    // Initialize agent
    let mut pilot = PacketPilot::new().await?;
    
    // Example: Fill a packet
    let request = PacketRequest {
        request_type: PacketRequestType::FillPacket {
            broker_name: "CH Robinson".to_string(),
            packet_url: Some("https://example.com/packet.pdf".to_string()),
            packet_pdf: None,
        },
        data: serde_json::json!({}),
    };
    
    let response = pilot.handle_request(request).await?;
    info!("✅ Response: {}", serde_json::to_string_pretty(&response)?);
    
    Ok(())
}
