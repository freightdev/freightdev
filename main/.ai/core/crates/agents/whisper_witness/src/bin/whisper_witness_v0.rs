// Whisper Witness v0.0.1
// "She whispers the truth and witnesses the trap."
//
// This agent LISTENS to conversations between drivers and brokers.
// She detects manipulation, deceit, and predatory tactics.
// She whispers warnings. She witnesses the trap.
// She does NOT intervene. She does NOT negotiate.
// She ONLY warns. Because drivers deserve to know.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{mpsc, RwLock};
use tracing::{info, warn, error};
use uuid::Uuid;

mod audio_listener;
mod tactic_detector;
mod whisper_engine;
mod transcript_summarizer;
mod broker_tactics;

use audio_listener::AudioListener;
use tactic_detector::TacticDetector;
use whisper_engine::WhisperEngine;
use transcript_summarizer::TranscriptSummarizer;
use broker_tactics::BrokerTacticDatabase;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "WW";
const AGENT_NAME: &str = "Whisper Witness";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "She whispers the truth and witnesses the trap.";

// ============================================================================
// BROKER TACTICS - THE TRUTH DATABASE
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BrokerTactic {
    // Pressure tactics
    UrgencyPressure,        // "This load won't last 5 minutes!"
    FalseSarcity,           // "I have 10 other drivers calling about this"
    TimeDecay,              // "Rate drops $50 every hour"
    
    // Rate manipulation
    Lowballing,             // Significantly under market rate
    HiddenFees,             // "Plus detention" but not in writing
    BaitAndSwitch,          // Rate changes after acceptance
    
    // Emotional manipulation
    GuiltTrip,              // "Come on, help me out here"
    PersonalAppeal,         // "I'm trying to take care of you"
    FakeRelationship,       // "We always take care of our best drivers"
    
    // Deception
    MisrepresentedLoad,     // Wrong weight, dimensions, or commodity
    HiddenStops,            // Additional pickups/drops not mentioned
    PaymentStalling,        // "30 days" becomes 60+
    
    // Exploitation
    WeekendTrap,            // Friday pickup, Monday delivery, ruins weekend
    DeadheadMinimization,   // "Only 200 miles deadhead" when it's actually 400
    DetentionLie,           // "They never have detention" but they always do
    
    // Professional
    Legitimate,             // Normal, fair negotiation
    Unclear,                // Need more context
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TacticDetection {
    pub tactic: BrokerTactic,
    pub confidence: f32,          // 0.0 - 1.0
    pub trigger_phrase: String,
    pub context: String,
    pub timestamp: DateTime<Utc>,
    pub severity: TacticSeverity,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TacticSeverity {
    Info,       // Worth noting
    Warning,    // Should be careful
    Alert,      // Serious red flag
    Critical,   // RUN AWAY
}

// ============================================================================
// CONVERSATION TRACKING
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Conversation {
    pub id: String,
    pub driver_id: String,
    pub broker_name: Option<String>,
    pub broker_company: Option<String>,
    pub started_at: DateTime<Utc>,
    pub ended_at: Option<DateTime<Utc>>,
    pub transcript: Vec<TranscriptLine>,
    pub detections: Vec<TacticDetection>,
    pub whispers_sent: Vec<WhisperAlert>,
    pub summary: Option<ConversationSummary>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranscriptLine {
    pub timestamp: DateTime<Utc>,
    pub speaker: Speaker,
    pub text: String,
    pub confidence: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Speaker {
    Driver,
    Broker,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WhisperAlert {
    pub id: String,
    pub tactic: BrokerTactic,
    pub severity: TacticSeverity,
    pub message: String,
    pub sent_at: DateTime<Utc>,
    pub acknowledged: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationSummary {
    pub total_duration_seconds: u64,
    pub total_tactics_detected: usize,
    pub highest_severity: TacticSeverity,
    pub load_details: Option<LoadDetails>,
    pub recommendation: DriverRecommendation,
    pub notes: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoadDetails {
    pub origin: Option<String>,
    pub destination: Option<String>,
    pub rate: Option<f32>,
    pub equipment: Option<String>,
    pub pickup_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DriverRecommendation {
    Safe,           // Normal conversation, no red flags
    Cautious,       // Some tactics detected, be careful
    Negotiate,      // Get everything in writing
    Decline,        // Too many red flags, pass on this load
}

// ============================================================================
// WHISPER WITNESS AGENT
// ============================================================================

pub struct WhisperWitness {
    audio_listener: AudioListener,
    tactic_detector: TacticDetector,
    whisper_engine: WhisperEngine,
    summarizer: TranscriptSummarizer,
    tactic_database: BrokerTacticDatabase,
    
    // Active conversations
    conversations: Arc<RwLock<HashMap<String, Conversation>>>,
    
    // Configuration
    config: WhisperConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WhisperConfig {
    pub enable_whispers: bool,
    pub enable_logging: bool,
    pub enable_summaries: bool,
    pub whisper_threshold: TacticSeverity, // Only whisper at or above this severity
    pub auto_summarize: bool,
}

impl Default for WhisperConfig {
    fn default() -> Self {
        Self {
            enable_whispers: true,
            enable_logging: true,
            enable_summaries: true,
            whisper_threshold: TacticSeverity::Warning,
            auto_summarize: true,
        }
    }
}

impl WhisperWitness {
    pub async fn new(config: WhisperConfig) -> Result<Self> {
        info!("👂 Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("🤫 {}", AGENT_TAGLINE);
        info!("");
        info!("She listens. She learns. She warns.");
        info!("");
        
        Ok(Self {
            audio_listener: AudioListener::new().await?,
            tactic_detector: TacticDetector::new()?,
            whisper_engine: WhisperEngine::new(),
            summarizer: TranscriptSummarizer::new(),
            tactic_database: BrokerTacticDatabase::new()?,
            conversations: Arc::new(RwLock::new(HashMap::new())),
            config,
        })
    }
    
    // ========================================================================
    // LISTEN TO CONVERSATION
    // ========================================================================
    
    pub async fn start_listening(&mut self, driver_id: String) -> Result<String> {
        let conversation_id = Uuid::new_v4().to_string();
        
        info!("👂 Starting to listen... Conversation ID: {}", conversation_id);
        
        let conversation = Conversation {
            id: conversation_id.clone(),
            driver_id: driver_id.clone(),
            broker_name: None,
            broker_company: None,
            started_at: Utc::now(),
            ended_at: None,
            transcript: Vec::new(),
            detections: Vec::new(),
            whispers_sent: Vec::new(),
            summary: None,
        };
        
        let mut conversations = self.conversations.write().await;
        conversations.insert(conversation_id.clone(), conversation);
        
        // Start audio capture
        let (tx, mut rx) = mpsc::channel(100);
        self.audio_listener.start_capture(tx).await?;
        
        // Spawn processor task
        let conversations_clone = self.conversations.clone();
        let conversation_id_clone = conversation_id.clone();
        let tactic_detector = self.tactic_detector.clone();
        let whisper_engine = self.whisper_engine.clone();
        let config = self.config.clone();
        
        tokio::spawn(async move {
            while let Some(audio_chunk) = rx.recv().await {
                if let Err(e) = Self::process_audio_chunk(
                    audio_chunk,
                    &conversation_id_clone,
                    &conversations_clone,
                    &tactic_detector,
                    &whisper_engine,
                    &config,
                ).await {
                    error!("Error processing audio: {}", e);
                }
            }
        });
        
        Ok(conversation_id)
    }
    
    async fn process_audio_chunk(
        audio_chunk: Vec<f32>,
        conversation_id: &str,
        conversations: &Arc<RwLock<HashMap<String, Conversation>>>,
        detector: &TacticDetector,
        whisper: &WhisperEngine,
        config: &WhisperConfig,
    ) -> Result<()> {
        // Transcribe audio
        let text = Self::transcribe_audio(&audio_chunk).await?;
        
        if text.is_empty() {
            return Ok(());
        }
        
        info!("📝 Transcribed: {}", text);
        
        // Identify speaker (simplified)
        let speaker = Self::identify_speaker(&text);
        
        // Add to transcript
        let line = TranscriptLine {
            timestamp: Utc::now(),
            speaker,
            text: text.clone(),
            confidence: 0.85,
        };
        
        let mut convos = conversations.write().await;
        if let Some(convo) = convos.get_mut(conversation_id) {
            convo.transcript.push(line);
            
            // Detect tactics in this line
            let detections = detector.analyze_text(&text, &convo.transcript)?;
            
            for detection in detections {
                info!("🚨 TACTIC DETECTED: {:?} (confidence: {:.2})", 
                      detection.tactic, detection.confidence);
                
                // Check if we should whisper
                if config.enable_whispers && 
                   Self::should_whisper(&detection.severity, &config.whisper_threshold) {
                    
                    let alert = whisper.create_alert(&detection)?;
                    whisper.send_whisper(&alert)?;
                    
                    convo.whispers_sent.push(alert);
                }
                
                convo.detections.push(detection);
            }
        }
        
        Ok(())
    }
    
    async fn transcribe_audio(audio: &[f32]) -> Result<String> {
        // TODO: Use actual Whisper model or cloud API
        // For now, return empty string as we don't have real audio
        Ok(String::new())
    }
    
    fn identify_speaker(text: &str) -> Speaker {
        // Simple heuristics (in production, use voice recognition)
        if text.contains("I'll take") || text.contains("my truck") {
            Speaker::Driver
        } else if text.contains("rate is") || text.contains("load goes") {
            Speaker::Broker
        } else {
            Speaker::Unknown
        }
    }
    
    fn should_whisper(detection_severity: &TacticSeverity, threshold: &TacticSeverity) -> bool {
        use TacticSeverity::*;
        
        let severity_level = match detection_severity {
            Info => 0,
            Warning => 1,
            Alert => 2,
            Critical => 3,
        };
        
        let threshold_level = match threshold {
            Info => 0,
            Warning => 1,
            Alert => 2,
            Critical => 3,
        };
        
        severity_level >= threshold_level
    }
    
    // ========================================================================
    // STOP LISTENING & SUMMARIZE
    // ========================================================================
    
    pub async fn stop_listening(&mut self, conversation_id: &str) -> Result<ConversationSummary> {
        info!("🛑 Stopping listener for conversation: {}", conversation_id);
        
        self.audio_listener.stop_capture().await?;
        
        let mut conversations = self.conversations.write().await;
        let conversation = conversations.get_mut(conversation_id)
            .context("Conversation not found")?;
        
        conversation.ended_at = Some(Utc::now());
        
        // Generate summary
        let summary = self.summarizer.summarize(conversation)?;
        conversation.summary = Some(summary.clone());
        
        info!("📊 Conversation summarized");
        info!("   Total tactics detected: {}", summary.total_tactics_detected);
        info!("   Highest severity: {:?}", summary.highest_severity);
        info!("   Recommendation: {:?}", summary.recommendation);
        
        Ok(summary)
    }
    
    // ========================================================================
    // REPLAY & ANALYZE
    // ========================================================================
    
    pub async fn analyze_transcript(&self, transcript_text: &str, driver_id: String) -> Result<ConversationSummary> {
        info!("📖 Analyzing provided transcript...");
        
        // Parse transcript into lines
        let lines: Vec<TranscriptLine> = transcript_text
            .lines()
            .enumerate()
            .map(|(i, line)| TranscriptLine {
                timestamp: Utc::now() + chrono::Duration::seconds(i as i64),
                speaker: Self::identify_speaker(line),
                text: line.to_string(),
                confidence: 1.0,
            })
            .collect();
        
        // Create temporary conversation
        let mut conversation = Conversation {
            id: Uuid::new_v4().to_string(),
            driver_id,
            broker_name: None,
            broker_company: None,
            started_at: Utc::now(),
            ended_at: Some(Utc::now()),
            transcript: lines.clone(),
            detections: Vec::new(),
            whispers_sent: Vec::new(),
            summary: None,
        };
        
        // Analyze each line
        for line in &lines {
            let detections = self.tactic_detector.analyze_text(&line.text, &conversation.transcript)?;
            conversation.detections.extend(detections);
        }
        
        // Generate summary
        let summary = self.summarizer.summarize(&conversation)?;
        
        Ok(summary)
    }
    
    // ========================================================================
    // QUERY OPERATIONS
    // ========================================================================
    
    pub async fn get_conversation(&self, conversation_id: &str) -> Result<Conversation> {
        let conversations = self.conversations.read().await;
        conversations.get(conversation_id)
            .cloned()
            .context("Conversation not found")
    }
    
    pub async fn list_conversations(&self, driver_id: &str) -> Vec<Conversation> {
        let conversations = self.conversations.read().await;
        conversations.values()
            .filter(|c| c.driver_id == driver_id)
            .cloned()
            .collect()
    }
}

// ============================================================================
// WHISPER MESSAGES - WHAT SHE SAYS
// ============================================================================

impl WhisperEngine {
    pub fn get_whisper_message(tactic: &BrokerTactic) -> &'static str {
        match tactic {
            BrokerTactic::UrgencyPressure => {
                "⚠️ WHISPER: They're using urgency to pressure you. Take your time."
            }
            BrokerTactic::FalseSarcity => {
                "⚠️ WHISPER: 'Other drivers calling' is a classic pressure tactic. Don't rush."
            }
            BrokerTactic::Lowballing => {
                "🚨 WHISPER: That rate is significantly below market. You can do better."
            }
            BrokerTactic::BaitAndSwitch => {
                "🚨 ALERT: Rate changed after you showed interest. RED FLAG. Get it in writing."
            }
            BrokerTactic::GuiltTrip => {
                "⚠️ WHISPER: They're trying to guilt you. This is business, not friendship."
            }
            BrokerTactic::MisrepresentedLoad => {
                "🚨 CRITICAL: Load details don't match. Verify everything in writing."
            }
            BrokerTactic::WeekendTrap => {
                "⚠️ WHISPER: This ruins your weekend. Make sure the rate compensates."
            }
            BrokerTactic::HiddenStops => {
                "🚨 ALERT: Additional stops not mentioned initially. RED FLAG."
            }
            BrokerTactic::TimeDecay => {
                "⚠️ WHISPER: 'Rate drops every hour' is pressure. Rate doesn't change that fast."
            }
            BrokerTactic::DeadheadMinimization => {
                "⚠️ WHISPER: Verify actual deadhead miles. They might be understating it."
            }
            _ => {
                "ℹ️ WHISPER: Something worth noting. Stay alert."
            }
        }
    }
}

// ============================================================================
// MAIN
// ============================================================================

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    
    info!("👂 {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("🤫 {}", AGENT_TAGLINE);
    info!("");
    info!("She listens.");
    info!("She learns.");
    info!("She warns.");
    info!("");
    info!("Because drivers deserve to know the truth.");
    info!("");
    
    let config = WhisperConfig::default();
    let mut witness = WhisperWitness::new(config).await?;
    
    // Example: Analyze a transcript
    let sample_transcript = r#"
Broker: Hey, I've got a great load for you! Chicago to Dallas, $2,200.
Driver: What's the pickup date?
Broker: Tomorrow morning. But listen, I've got 3 other drivers calling about this load right now.
Driver: What's the weight?
Broker: 42,000 pounds, dry van, 53 footer.
Broker: Hey, I'm gonna level with you - rate drops $50 every hour on this one.
Driver: That seems low for that run.
Broker: Come on man, help me out here. I'm trying to take care of my best drivers.
Driver: I need to think about it.
Broker: This won't last 5 minutes. You snooze, you lose buddy.
    "#;
    
    let summary = witness.analyze_transcript(sample_transcript, "driver-001".to_string()).await?;
    
    info!("");
    info!("📊 CONVERSATION ANALYSIS:");
    info!("   Tactics detected: {}", summary.total_tactics_detected);
    info!("   Highest severity: {:?}", summary.highest_severity);
    info!("   Recommendation: {:?}", summary.recommendation);
    info!("");
    
    Ok(())
}
