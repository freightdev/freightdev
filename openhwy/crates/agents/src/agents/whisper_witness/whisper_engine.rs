// Whisper Engine - Sends alerts to drivers
// She whispers. She warns.

use anyhow::Result;
use crate::{WhisperAlert, TacticDetection, BrokerTactic};
use uuid::Uuid;

#[derive(Clone)]
pub struct WhisperEngine {}

impl WhisperEngine {
    pub fn new() -> Self {
        Self {}
    }
    
    pub fn create_alert(&self, detection: &TacticDetection) -> Result<WhisperAlert> {
        let message = match detection.tactic {
            BrokerTactic::UrgencyPressure => {
                "⚠️ WHISPER: They're using urgency to pressure you. Take your time. Real loads don't disappear in 5 minutes."
            }
            BrokerTactic::FalseSarcity => {
                "⚠️ WHISPER: '10 other drivers calling' is a classic pressure tactic. If it's such a good load, why are they still calling?"
            }
            BrokerTactic::TimeDecay => {
                "⚠️ WHISPER: 'Rate drops every hour' is artificial pressure. Market rates don't change that fast."
            }
            BrokerTactic::Lowballing => {
                "🚨 WHISPER: That rate is significantly below market. You can do better. Don't settle."
            }
            BrokerTactic::BaitAndSwitch => {
                "🚨 CRITICAL: Rate changed after you showed interest. MAJOR RED FLAG. Walk away or get it in writing."
            }
            BrokerTactic::GuiltTrip => {
                "⚠️ WHISPER: They're trying to guilt you. This is business, not friendship. Your time has value."
            }
            BrokerTactic::PersonalAppeal => {
                "ℹ️ WHISPER: 'I take care of my best drivers' - Words are cheap. Judge by actions, not promises."
            }
            BrokerTactic::FakeRelationship => {
                "⚠️ WHISPER: Building fake rapport. If they really valued you, they'd offer a fair rate from the start."
            }
            BrokerTactic::MisrepresentedLoad => {
                "🚨 CRITICAL: Load details don't match. STOP. Verify everything in writing before agreeing."
            }
            BrokerTactic::HiddenStops => {
                "🚨 ALERT: Additional stops not mentioned initially. RED FLAG. Get full details and adjust rate."
            }
            BrokerTactic::WeekendTrap => {
                "⚠️ WHISPER: Friday pickup, Monday delivery = your weekend is gone. Make sure the rate compensates."
            }
            BrokerTactic::DeadheadMinimization => {
                "⚠️ WHISPER: Verify actual deadhead miles on a map. They might be understating the distance."
            }
            BrokerTactic::DetentionLie => {
                "⚠️ WHISPER: 'Never any detention' - Get it in writing. Empty promises don't pay the bills."
            }
            BrokerTactic::HiddenFees => {
                "🚨 ALERT: Hidden fees or costs mentioned. Get EVERYTHING in the rate confirmation."
            }
            BrokerTactic::PaymentStalling => {
                "⚠️ WHISPER: Check their payment terms carefully. '30 days' can become 60+ with some brokers."
            }
            BrokerTactic::Legitimate => {
                "✅ Normal conversation. No red flags detected."
            }
            BrokerTactic::Unclear => {
                "ℹ️ WHISPER: Stay alert. Something to keep in mind."
            }
        };
        
        Ok(WhisperAlert {
            id: Uuid::new_v4().to_string(),
            tactic: detection.tactic.clone(),
            severity: detection.severity.clone(),
            message: message.to_string(),
            sent_at: chrono::Utc::now(),
            acknowledged: false,
        })
    }
    
    pub fn send_whisper(&self, alert: &WhisperAlert) -> Result<()> {
        // In production, this would:
        // 1. Send desktop notification
        // 2. Push to mobile app
        // 3. Display in dashboard
        // 4. Play audio alert if configured
        
        tracing::warn!("🤫 {}", alert.message);
        
        // Desktop notification (if available)
        #[cfg(not(target_os = "windows"))]
        {
            if let Err(e) = notify_rust::Notification::new()
                .summary("Whisper Witness")
                .body(&alert.message)
                .show()
            {
                tracing::debug!("Could not send desktop notification: {}", e);
            }
        }
        
        Ok(())
    }
}

// ============================================================================
// AUDIO LISTENER
// ============================================================================

use tokio::sync::mpsc;

pub struct AudioListener {
    // In production, this would handle actual audio capture
    active: bool,
}

impl AudioListener {
    pub async fn new() -> Result<Self> {
        Ok(Self { active: false })
    }
    
    pub async fn start_capture(&mut self, _tx: mpsc::Sender<Vec<f32>>) -> Result<()> {
        tracing::info!("🎤 Audio capture started");
        self.active = true;
        
        // In production:
        // 1. Initialize audio device
        // 2. Start capturing audio stream
        // 3. Send chunks to tx channel
        // 4. Handle errors and reconnection
        
        Ok(())
    }
    
    pub async fn stop_capture(&mut self) -> Result<()> {
        tracing::info!("🛑 Audio capture stopped");
        self.active = false;
        Ok(())
    }
}

// ============================================================================
// TRANSCRIPT SUMMARIZER
// ============================================================================

use crate::{Conversation, ConversationSummary, DriverRecommendation, LoadDetails, TacticSeverity};

pub struct TranscriptSummarizer {}

impl TranscriptSummarizer {
    pub fn new() -> Self {
        Self {}
    }
    
    pub fn summarize(&self, conversation: &Conversation) -> Result<ConversationSummary> {
        let duration = if let Some(ended) = conversation.ended_at {
            (ended - conversation.started_at).num_seconds() as u64
        } else {
            0
        };
        
        // Find highest severity
        let highest_severity = conversation.detections.iter()
            .map(|d| &d.severity)
            .max_by_key(|s| Self::severity_level(s))
            .cloned()
            .unwrap_or(TacticSeverity::Info);
        
        // Extract load details from transcript
        let load_details = Self::extract_load_details(&conversation.transcript);
        
        // Generate recommendation
        let recommendation = Self::generate_recommendation(
            &conversation.detections,
            &highest_severity,
        );
        
        // Generate notes
        let notes = Self::generate_notes(&conversation.detections);
        
        Ok(ConversationSummary {
            total_duration_seconds: duration,
            total_tactics_detected: conversation.detections.len(),
            highest_severity,
            load_details,
            recommendation,
            notes,
        })
    }
    
    fn severity_level(severity: &TacticSeverity) -> u8 {
        match severity {
            TacticSeverity::Info => 0,
            TacticSeverity::Warning => 1,
            TacticSeverity::Alert => 2,
            TacticSeverity::Critical => 3,
        }
    }
    
    fn extract_load_details(transcript: &[crate::TranscriptLine]) -> Option<LoadDetails> {
        let text = transcript.iter()
            .map(|l| l.text.as_str())
            .collect::<Vec<_>>()
            .join(" ");
        
        // Simple extraction (in production, use NLP)
        let rate = text.split_whitespace()
            .find(|w| w.starts_with('$'))
            .and_then(|w| w.trim_start_matches('$').replace(',', "").parse().ok());
        
        Some(LoadDetails {
            origin: None,
            destination: None,
            rate,
            equipment: None,
            pickup_date: None,
        })
    }
    
    fn generate_recommendation(
        detections: &[crate::TacticDetection],
        highest_severity: &TacticSeverity,
    ) -> DriverRecommendation {
        let critical_count = detections.iter()
            .filter(|d| matches!(d.severity, TacticSeverity::Critical))
            .count();
        
        let alert_count = detections.iter()
            .filter(|d| matches!(d.severity, TacticSeverity::Alert))
            .count();
        
        if critical_count > 0 {
            DriverRecommendation::Decline
        } else if alert_count >= 2 {
            DriverRecommendation::Negotiate
        } else if matches!(highest_severity, TacticSeverity::Warning) {
            DriverRecommendation::Cautious
        } else {
            DriverRecommendation::Safe
        }
    }
    
    fn generate_notes(detections: &[crate::TacticDetection]) -> Vec<String> {
        let mut notes = Vec::new();
        
        if detections.is_empty() {
            notes.push("No concerning tactics detected.".to_string());
            return notes;
        }
        
        for detection in detections {
            notes.push(format!(
                "{:?}: \"{}\"",
                detection.tactic,
                detection.trigger_phrase
            ));
        }
        
        notes
    }
}
