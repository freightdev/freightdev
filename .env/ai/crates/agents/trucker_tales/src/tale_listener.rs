// Tale Listener - Where drivers' voices become words
// Every trucker has a story. This is where we listen.

use anyhow::Result;
use tracing::{info, warn};

pub struct TaleListener {
    whisper_endpoint: Option<String>,
}

impl TaleListener {
    pub async fn new() -> Result<Self> {
        // Check for Whisper API endpoint
        let whisper_endpoint = std::env::var("WHISPER_API_URL").ok();
        
        if whisper_endpoint.is_some() {
            info!("🎤 Voice transcription enabled");
        } else {
            warn!("⚠️  No Whisper API configured - voice transcription disabled");
        }
        
        Ok(Self { whisper_endpoint })
    }
    
    pub async fn transcribe_audio(&self, audio_base64: &str) -> Result<String> {
        if let Some(endpoint) = &self.whisper_endpoint {
            // Call Whisper API
            info!("🎤 Transcribing audio...");
            
            let client = reqwest::Client::new();
            let response = client
                .post(format!("{}/transcribe", endpoint))
                .json(&serde_json::json!({
                    "audio": audio_base64,
                    "language": "en",
                }))
                .send()
                .await?;
            
            let result: serde_json::Value = response.json().await?;
            let transcription = result["text"]
                .as_str()
                .unwrap_or("(transcription failed)")
                .to_string();
            
            info!("✅ Transcribed {} characters", transcription.len());
            Ok(transcription)
        } else {
            // Fallback: Return placeholder
            Ok("[Voice recording - transcription not available. Driver spoke for approx duration.]".to_string())
        }
    }
    
    /// Listen in real-time (for live sessions)
    pub async fn listen_live(&self) -> Result<String> {
        // TODO: Implement real-time voice capture
        Ok("".to_string())
    }
    
    /// Enhance audio quality before transcription
    pub async fn enhance_audio(&self, audio_base64: &str) -> Result<String> {
        // TODO: Noise reduction, normalization
        Ok(audio_base64.to_string())
    }
}
