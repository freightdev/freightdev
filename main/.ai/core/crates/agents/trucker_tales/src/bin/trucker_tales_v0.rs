// Trucker's Tales v0.0.1
// "Tell your tale. The road will remember."
//
// A storytelling agent that listens to truckers and transforms their experiences
// into written tales. Not just for entertainment - to preserve truth and teach
// the next generation what really happens out there.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tokio::fs;
use tracing::{info, warn};
use uuid::Uuid;

mod tale_listener;
mod story_structurer;
mod emotion_enhancer;
mod format_converter;
mod publishing;

use tale_listener::TaleListener;
use story_structurer::StoryStructurer;
use emotion_enhancer::EmotionEnhancer;
use format_converter::FormatConverter;
use publishing::Publisher;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "TT";
const AGENT_NAME: &str = "Trucker's Tales";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "Tell your tale. The road will remember.";

// ============================================================================
// TALE DATA STRUCTURES
// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Tale {
    pub id: String,
    pub driver_id: String,
    pub title: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    
    // Story content
    pub entries: Vec<TaleEntry>,
    pub timeline: Vec<TimelineEvent>,
    pub lessons: Vec<Lesson>,
    
    // Metadata
    pub tags: Vec<String>,
    pub location_mentions: Vec<String>,
    pub people_mentioned: Vec<String>,
    
    // Publishing
    pub status: TaleStatus,
    pub consent_given: bool,
    pub published_url: Option<String>,
    
    // Rights management
    pub license: TaleLicense,
    pub owner: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TaleEntry {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub entry_type: EntryType,
    pub content: String,
    pub emotion_score: Option<EmotionAnalysis>,
    pub location: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum EntryType {
    Voice,
    Text,
    Note,
    Reflection,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TimelineEvent {
    pub timestamp: DateTime<Utc>,
    pub event_type: String,
    pub description: String,
    pub significance: EventSignificance,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum EventSignificance {
    Minor,
    Notable,
    Critical,
    LifeChanging,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Lesson {
    pub title: String,
    pub content: String,
    pub learned_from: String, // What event taught this
    pub applies_to: Vec<String>, // Who this lesson helps
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EmotionAnalysis {
    pub joy: f32,
    pub fear: f32,
    pub anger: f32,
    pub sadness: f32,
    pub pride: f32,
    pub overall_sentiment: f32, // -1.0 to 1.0
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum TaleStatus {
    Draft,
    InProgress,
    Complete,
    Published,
    Archived,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum TaleLicense {
    PrivateOwned,
    CreativeCommons,
    ProfitSharing, // Via Owlusive Treasures
    OpenHWYArchive,
}

// ============================================================================
// REQUEST/RESPONSE TYPES
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct TaleRequest {
    pub action: TaleAction,
    pub driver_id: String,
    pub data: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum TaleAction {
    #[serde(rename = "start_tale")]
    StartTale { title: Option<String> },
    
    #[serde(rename = "add_entry")]
    AddEntry { 
        content: String, 
        entry_type: EntryType,
        location: Option<String>,
    },
    
    #[serde(rename = "add_voice")]
    AddVoice { 
        audio_base64: String,
        duration_seconds: Option<u32>,
    },
    
    #[serde(rename = "structure_tale")]
    StructureTale { tale_id: String },
    
    #[serde(rename = "add_lesson")]
    AddLesson {
        tale_id: String,
        lesson: Lesson,
    },
    
    #[serde(rename = "publish_tale")]
    PublishTale {
        tale_id: String,
        license: TaleLicense,
        target: PublishTarget,
    },
    
    #[serde(rename = "export_tale")]
    ExportTale {
        tale_id: String,
        format: ExportFormat,
    },
}

#[derive(Debug, Serialize, Deserialize)]
pub enum PublishTarget {
    OwlusiveTreasures,
    OpenHWYArchive,
    PersonalLibrary,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ExportFormat {
    Markdown,
    PDF,
    EPUB,
    JSON,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TaleResponse {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
}

// ============================================================================
// TRUCKER'S TALES AGENT
// ============================================================================

pub struct TruckersTales {
    tale_listener: TaleListener,
    story_structurer: StoryStructurer,
    emotion_enhancer: EmotionEnhancer,
    format_converter: FormatConverter,
    publisher: Publisher,
    
    tales_dir: PathBuf,
    active_sessions: std::sync::Arc<tokio::sync::RwLock<std::collections::HashMap<String, Tale>>>,
}

impl TruckersTales {
    pub async fn new() -> Result<Self> {
        info!("🚛 Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("📖 {}", AGENT_TAGLINE);
        
        let tales_dir = PathBuf::from("/var/lib/truckers_tales");
        fs::create_dir_all(&tales_dir).await
            .context("Failed to create tales directory")?;
        
        Ok(Self {
            tale_listener: TaleListener::new().await?,
            story_structurer: StoryStructurer::new(),
            emotion_enhancer: EmotionEnhancer::new(),
            format_converter: FormatConverter::new(),
            publisher: Publisher::new(),
            tales_dir,
            active_sessions: std::sync::Arc::new(tokio::sync::RwLock::new(std::collections::HashMap::new())),
        })
    }
    
    pub async fn handle_request(&mut self, request: TaleRequest) -> Result<TaleResponse> {
        info!("📥 Handling tale request: {:?}", request.action);
        
        let result = match request.action {
            TaleAction::StartTale { title } => {
                self.start_new_tale(request.driver_id, title).await
            }
            
            TaleAction::AddEntry { content, entry_type, location } => {
                self.add_entry(request.driver_id, content, entry_type, location).await
            }
            
            TaleAction::AddVoice { audio_base64, duration_seconds } => {
                self.add_voice_entry(request.driver_id, audio_base64, duration_seconds).await
            }
            
            TaleAction::StructureTale { tale_id } => {
                self.structure_tale(tale_id).await
            }
            
            TaleAction::AddLesson { tale_id, lesson } => {
                self.add_lesson(tale_id, lesson).await
            }
            
            TaleAction::PublishTale { tale_id, license, target } => {
                self.publish_tale(tale_id, license, target).await
            }
            
            TaleAction::ExportTale { tale_id, format } => {
                self.export_tale(tale_id, format).await
            }
        };
        
        match result {
            Ok(data) => Ok(TaleResponse {
                success: true,
                message: "Tale action completed".to_string(),
                data: Some(data),
            }),
            Err(e) => Ok(TaleResponse {
                success: false,
                message: format!("Tale action failed: {}", e),
                data: None,
            }),
        }
    }
    
    // ========================================================================
    // CORE TALE OPERATIONS
    // ========================================================================
    
    async fn start_new_tale(&mut self, driver_id: String, title: Option<String>) -> Result<serde_json::Value> {
        info!("📖 Starting new tale for driver: {}", driver_id);
        
        let tale = Tale {
            id: Uuid::new_v4().to_string(),
            driver_id: driver_id.clone(),
            title,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            entries: vec![],
            timeline: vec![],
            lessons: vec![],
            tags: vec![],
            location_mentions: vec![],
            people_mentioned: vec![],
            status: TaleStatus::InProgress,
            consent_given: false,
            published_url: None,
            license: TaleLicense::PrivateOwned,
            owner: driver_id.clone(),
        };
        
        let tale_id = tale.id.clone();
        
        // Store in active sessions
        let mut sessions = self.active_sessions.write().await;
        sessions.insert(driver_id.clone(), tale);
        
        info!("✅ New tale started: {}", tale_id);
        
        Ok(serde_json::json!({
            "tale_id": tale_id,
            "status": "Tale session started. Begin recording your story.",
        }))
    }
    
    async fn add_entry(
        &mut self,
        driver_id: String,
        content: String,
        entry_type: EntryType,
        location: Option<String>,
    ) -> Result<serde_json::Value> {
        info!("✍️  Adding entry for driver: {}", driver_id);
        
        let mut sessions = self.active_sessions.write().await;
        let tale = sessions.get_mut(&driver_id)
            .context("No active tale session for driver")?;
        
        // Analyze emotion
        let emotion_score = self.emotion_enhancer.analyze(&content).await?;
        
        // Create entry
        let entry = TaleEntry {
            id: Uuid::new_v4().to_string(),
            timestamp: Utc::now(),
            entry_type,
            content: content.clone(),
            emotion_score: Some(emotion_score),
            location: location.clone(),
        };
        
        // Detect significant events
        if let Some(event) = self.detect_road_event(&content, location.as_deref()) {
            tale.timeline.push(event);
        }
        
        // Extract tags
        let new_tags = self.extract_tags(&content);
        for tag in new_tags {
            if !tale.tags.contains(&tag) {
                tale.tags.push(tag);
            }
        }
        
        tale.entries.push(entry);
        tale.updated_at = Utc::now();
        
        // Auto-save
        self.save_tale(&tale).await?;
        
        Ok(serde_json::json!({
            "status": "Entry added",
            "entry_count": tale.entries.len(),
        }))
    }
    
    async fn add_voice_entry(
        &mut self,
        driver_id: String,
        audio_base64: String,
        _duration_seconds: Option<u32>,
    ) -> Result<serde_json::Value> {
        info!("🎤 Adding voice entry for driver: {}", driver_id);
        
        // Transcribe audio to text
        let transcription = self.tale_listener.transcribe_audio(&audio_base64).await?;
        
        // Add as entry
        self.add_entry(
            driver_id,
            transcription.clone(),
            EntryType::Voice,
            None,
        ).await?;
        
        Ok(serde_json::json!({
            "status": "Voice transcribed and added",
            "transcription": transcription,
        }))
    }
    
    async fn structure_tale(&mut self, tale_id: String) -> Result<serde_json::Value> {
        info!("📝 Structuring tale: {}", tale_id);
        
        let tale = self.load_tale(&tale_id).await?;
        
        // Structure the story
        let structured = self.story_structurer.structure(&tale).await?;
        
        Ok(serde_json::json!({
            "status": "Tale structured",
            "structure": structured,
        }))
    }
    
    async fn add_lesson(&mut self, tale_id: String, lesson: Lesson) -> Result<serde_json::Value> {
        info!("🎓 Adding lesson to tale: {}", tale_id);
        
        let mut tale = self.load_tale(&tale_id).await?;
        tale.lessons.push(lesson);
        tale.updated_at = Utc::now();
        
        self.save_tale(&tale).await?;
        
        Ok(serde_json::json!({
            "status": "Lesson added",
            "lesson_count": tale.lessons.len(),
        }))
    }
    
    async fn publish_tale(
        &mut self,
        tale_id: String,
        license: TaleLicense,
        target: PublishTarget,
    ) -> Result<serde_json::Value> {
        info!("🌍 Publishing tale: {} to {:?}", tale_id, target);
        
        let mut tale = self.load_tale(&tale_id).await?;
        
        if !tale.consent_given {
            anyhow::bail!("Cannot publish without driver consent");
        }
        
        tale.license = license.clone();
        tale.status = TaleStatus::Published;
        
        // Publish to target
        let published_url = self.publisher.publish(&tale, target).await?;
        tale.published_url = Some(published_url.clone());
        
        self.save_tale(&tale).await?;
        
        Ok(serde_json::json!({
            "status": "Tale published",
            "url": published_url,
            "license": format!("{:?}", license),
        }))
    }
    
    async fn export_tale(&mut self, tale_id: String, format: ExportFormat) -> Result<serde_json::Value> {
        info!("📄 Exporting tale: {} as {:?}", tale_id, format);
        
        let tale = self.load_tale(&tale_id).await?;
        
        let exported = self.format_converter.convert(&tale, format).await?;
        
        Ok(serde_json::json!({
            "status": "Tale exported",
            "format": format!("{:?}", format),
            "content": exported,
        }))
    }
    
    // ========================================================================
    // HELPERS
    // ========================================================================
    
    fn detect_road_event(&self, content: &str, location: Option<&str>) -> Option<TimelineEvent> {
        let lower = content.to_lowercase();
        
        // Detect significant events
        let (event_type, significance) = if lower.contains("accident") || lower.contains("crash") {
            ("accident", EventSignificance::Critical)
        } else if lower.contains("breakdown") || lower.contains("mechanical") {
            ("breakdown", EventSignificance::Notable)
        } else if lower.contains("weather") && (lower.contains("storm") || lower.contains("snow")) {
            ("severe_weather", EventSignificance::Notable)
        } else if lower.contains("delivered") || lower.contains("delivery") {
            ("delivery", EventSignificance::Minor)
        } else if lower.contains("pickup") || lower.contains("loaded") {
            ("pickup", EventSignificance::Minor)
        } else {
            return None;
        };
        
        Some(TimelineEvent {
            timestamp: Utc::now(),
            event_type: event_type.to_string(),
            description: content.to_string(),
            significance,
        })
    }
    
    fn extract_tags(&self, content: &str) -> Vec<String> {
        let mut tags = Vec::new();
        let lower = content.to_lowercase();
        
        // Common trucking tags
        if lower.contains("winter") || lower.contains("snow") || lower.contains("ice") {
            tags.push("winter_driving".to_string());
        }
        if lower.contains("night") || lower.contains("overnight") {
            tags.push("night_driving".to_string());
        }
        if lower.contains("mountain") || lower.contains("hills") {
            tags.push("mountain_driving".to_string());
        }
        if lower.contains("rookie") || lower.contains("first time") {
            tags.push("rookie_experience".to_string());
        }
        if lower.contains("family") || lower.contains("home") {
            tags.push("family".to_string());
        }
        
        tags
    }
    
    async fn save_tale(&self, tale: &Tale) -> Result<()> {
        let file_path = self.tales_dir.join(format!("{}.json", tale.id));
        let json = serde_json::to_string_pretty(tale)?;
        fs::write(&file_path, json).await?;
        Ok(())
    }
    
    async fn load_tale(&self, tale_id: &str) -> Result<Tale> {
        let file_path = self.tales_dir.join(format!("{}.json", tale_id));
        let json = fs::read_to_string(&file_path).await?;
        let tale = serde_json::from_str(&json)?;
        Ok(tale)
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    
    info!("🚛 {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("📖 {}", AGENT_TAGLINE);
    info!("");
    info!("A tale told is a truth preserved.");
    info!("The road will remember.");
    info!("");
    
    let mut tales = TruckersTales::new().await?;
    
    // Example: Start a tale
    let request = TaleRequest {
        action: TaleAction::StartTale { title: Some("My First Winter Run".to_string()) },
        driver_id: "driver-001".to_string(),
        data: serde_json::json!({}),
    };
    
    let response = tales.handle_request(request).await?;
    info!("✅ Response: {}", serde_json::to_string_pretty(&response)?);
    
    Ok(())
}
