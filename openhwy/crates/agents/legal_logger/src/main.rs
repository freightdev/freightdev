// Legal Logger v0.0.1
// "If it happened, he logged it. Legally."
//
// Legal Logger is THE authoritative logger for the Wheeler ecosystem.
// He is the ONLY agent with write access to the OpenHWY ledger.
//
// He does NOT:
// - Infer
// - Analyze
// - Judge
// - Alter
// - Delete
//
// He ONLY:
// - Logs what he's told
// - Signs it cryptographically
// - Stores it immutably
// - Retrieves on request
//
// The ledger is append-only. Once written, it's permanent.
// This is the source of truth. This is the historical record.
// This is Legal Logger.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, warn, error};
use uuid::Uuid;

mod ledger_writer;
mod encryption_module;
mod timestamp_engine;
mod signature_engine;
mod compression;

use ledger_writer::LedgerWriter;
use encryption_module::EncryptionModule;
use timestamp_engine::TimestampEngine;
use signature_engine::SignatureEngine;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "LL";
const AGENT_NAME: &str = "Legal Logger";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "If it happened, he logged it. Legally.";

// ============================================================================
// LOG ENTRY STRUCTURE
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogEntry {
    // Identity
    pub id: String,                          // Unique log entry ID
    pub entry_number: u64,                   // Sequential ledger position
    
    // Source
    pub source_agent: String,                // Which agent created this log
    pub user_id: Option<String>,             // Associated user (if any)
    pub session_id: Option<String>,          // Session context
    
    // Event
    pub event_type: EventType,               // What happened
    pub event_data: serde_json::Value,       // The actual event data
    pub description: String,                 // Human-readable description
    
    // Context
    pub tags: Vec<String>,                   // Searchable tags
    pub metadata: serde_json::Value,         // Additional metadata
    
    // Temporal
    pub timestamp: DateTime<Utc>,            // When it happened
    pub timezone: String,                    // Local timezone context
    
    // Cryptographic
    pub content_hash: String,                // SHA-256 of content
    pub signature: String,                   // Ed25519 signature
    pub previous_hash: Option<String>,       // Hash of previous entry (blockchain-style)
    
    // Status
    pub encrypted: bool,                     // Is event_data encrypted?
    pub verified: bool,                      // Has signature been verified?
    pub immutable: bool,                     // Committed to ledger (always true after write)
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum EventType {
    // Agent Actions
    AgentStarted,
    AgentStopped,
    AgentAction,
    AgentError,
    
    // User Actions
    UserLogin,
    UserLogout,
    UserAction,
    
    // System Events
    SystemEvent,
    ConfigChange,
    SecurityEvent,
    
    // Business Events
    LoadBooked,
    LoadDelivered,
    PaymentReceived,
    PaymentSent,
    DocumentSigned,
    
    // Compliance
    DOTInspection,
    HoursOfService,
    SafetyIncident,
    
    // Legal
    ContractSigned,
    DisputeFiled,
    DisputeResolved,
    
    // Audit
    AuditTrail,
    DataAccess,
    DataModification,
    
    // Communication
    MessageSent,
    MessageReceived,
    CallRecorded,
    
    // Custom
    Custom(String),
}

// ============================================================================
// LOG REQUEST
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogRequest {
    pub source_agent: String,
    pub user_id: Option<String>,
    pub session_id: Option<String>,
    pub event_type: EventType,
    pub event_data: serde_json::Value,
    pub description: String,
    pub tags: Vec<String>,
    pub metadata: Option<serde_json::Value>,
    pub encrypt: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LogResponse {
    pub success: bool,
    pub entry_id: Option<String>,
    pub entry_number: Option<u64>,
    pub timestamp: DateTime<Utc>,
    pub signature: Option<String>,
    pub error: Option<String>,
}

// ============================================================================
// QUERY STRUCTURE
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogQuery {
    pub user_id: Option<String>,
    pub agent: Option<String>,
    pub event_type: Option<EventType>,
    pub tags: Option<Vec<String>>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub limit: Option<usize>,
}

// ============================================================================
// LEGAL LOGGER AGENT
// ============================================================================

pub struct LegalLogger {
    ledger_writer: LedgerWriter,
    encryption: EncryptionModule,
    timestamp: TimestampEngine,
    signature: SignatureEngine,
    
    // Entry counter (ledger position)
    entry_counter: Arc<RwLock<u64>>,
    
    // Last entry hash (blockchain chain)
    last_hash: Arc<RwLock<Option<String>>>,
    
    // Configuration
    config: LoggerConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggerConfig {
    pub log_mode: LogMode,
    pub auto_flush: bool,
    pub require_signature: bool,
    pub enable_encryption: bool,
    pub enable_compression: bool,
    pub max_buffer_size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum LogMode {
    Strict,      // Every log must be signed and committed
    Permissive,  // Allow unsigned logs
    Development, // Local only, no ledger
}

impl Default for LoggerConfig {
    fn default() -> Self {
        Self {
            log_mode: LogMode::Strict,
            auto_flush: true,
            require_signature: true,
            enable_encryption: true,
            enable_compression: true,
            max_buffer_size: 1000,
        }
    }
}

impl LegalLogger {
    pub async fn new(config: LoggerConfig) -> Result<Self> {
        info!("⚖️  Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("📜 {}", AGENT_TAGLINE);
        info!("");
        info!("Legal Logger is the keeper of truth.");
        info!("Once logged, it's permanent. Once signed, it's proven.");
        info!("The ledger is append-only. History cannot be rewritten.");
        info!("");
        
        let ledger_writer = LedgerWriter::new().await?;
        let encryption = EncryptionModule::new()?;
        let timestamp = TimestampEngine::new();
        let signature = SignatureEngine::new()?;
        
        // Load last entry number
        let last_entry = ledger_writer.get_last_entry_number().await?;
        
        info!("✅ Ledger initialized at entry #{}", last_entry);
        
        Ok(Self {
            ledger_writer,
            encryption,
            timestamp,
            signature,
            entry_counter: Arc::new(RwLock::new(last_entry)),
            last_hash: Arc::new(RwLock::new(None)),
            config,
        })
    }
    
    // ========================================================================
    // LOG EVENT - THE PRIMARY OPERATION
    // ========================================================================
    
    pub async fn log_event(&mut self, request: LogRequest) -> Result<LogResponse> {
        info!("📝 Logging event: {:?} from {}", request.event_type, request.source_agent);
        
        // Validate in strict mode
        if self.config.log_mode == LogMode::Strict {
            self.validate_request(&request)?;
        }
        
        // Get next entry number
        let mut counter = self.entry_counter.write().await;
        *counter += 1;
        let entry_number = *counter;
        drop(counter);
        
        // Create entry
        let mut entry = LogEntry {
            id: Uuid::new_v4().to_string(),
            entry_number,
            source_agent: request.source_agent.clone(),
            user_id: request.user_id.clone(),
            session_id: request.session_id.clone(),
            event_type: request.event_type.clone(),
            event_data: request.event_data.clone(),
            description: request.description.clone(),
            tags: request.tags.clone(),
            metadata: request.metadata.unwrap_or(serde_json::json!({})),
            timestamp: self.timestamp.now(),
            timezone: self.timestamp.local_timezone(),
            content_hash: String::new(), // Calculated next
            signature: String::new(),     // Calculated next
            previous_hash: self.last_hash.read().await.clone(),
            encrypted: false,
            verified: false,
            immutable: false,
        };
        
        // Encrypt if requested
        if request.encrypt && self.config.enable_encryption {
            entry.event_data = serde_json::Value::String(
                self.encryption.encrypt(&entry.event_data.to_string())?
            );
            entry.encrypted = true;
        }
        
        // Calculate content hash
        entry.content_hash = self.calculate_content_hash(&entry)?;
        
        // Sign entry
        if self.config.require_signature {
            entry.signature = self.signature.sign(&entry.content_hash)?;
            entry.verified = true;
        }
        
        // Write to ledger
        self.ledger_writer.write_entry(&entry).await?;
        
        // Mark as immutable
        entry.immutable = true;
        
        // Update last hash
        let mut last_hash = self.last_hash.write().await;
        *last_hash = Some(entry.content_hash.clone());
        
        info!("✅ Logged entry #{} with ID {}", entry.entry_number, entry.id);
        
        Ok(LogResponse {
            success: true,
            entry_id: Some(entry.id),
            entry_number: Some(entry.entry_number),
            timestamp: entry.timestamp,
            signature: Some(entry.signature),
            error: None,
        })
    }
    
    fn validate_request(&self, request: &LogRequest) -> Result<()> {
        if request.source_agent.is_empty() {
            anyhow::bail!("source_agent is required");
        }
        
        if request.description.is_empty() {
            anyhow::bail!("description is required");
        }
        
        Ok(())
    }
    
    fn calculate_content_hash(&self, entry: &LogEntry) -> Result<String> {
        // Create canonical representation
        let content = serde_json::json!({
            "entry_number": entry.entry_number,
            "source_agent": entry.source_agent,
            "event_type": entry.event_type,
            "event_data": entry.event_data,
            "timestamp": entry.timestamp,
            "previous_hash": entry.previous_hash,
        });
        
        // Hash it
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(content.to_string().as_bytes());
        Ok(format!("{:x}", hasher.finalize()))
    }
    
    // ========================================================================
    // RETRIEVE ENTRIES
    // ========================================================================
    
    pub async fn get_entry(&self, entry_id: &str) -> Result<LogEntry> {
        self.ledger_writer.get_entry(entry_id).await
    }
    
    pub async fn query_entries(&self, query: LogQuery) -> Result<Vec<LogEntry>> {
        self.ledger_writer.query_entries(query).await
    }
    
    pub async fn get_user_history(&self, user_id: &str, limit: usize) -> Result<Vec<LogEntry>> {
        let query = LogQuery {
            user_id: Some(user_id.to_string()),
            agent: None,
            event_type: None,
            tags: None,
            start_time: None,
            end_time: None,
            limit: Some(limit),
        };
        
        self.query_entries(query).await
    }
    
    pub async fn get_agent_logs(&self, agent: &str, limit: usize) -> Result<Vec<LogEntry>> {
        let query = LogQuery {
            user_id: None,
            agent: Some(agent.to_string()),
            event_type: None,
            tags: None,
            start_time: None,
            end_time: None,
            limit: Some(limit),
        };
        
        self.query_entries(query).await
    }
    
    // ========================================================================
    // VERIFICATION
    // ========================================================================
    
    pub async fn verify_entry(&self, entry_id: &str) -> Result<bool> {
        let entry = self.get_entry(entry_id).await?;
        
        // Recalculate hash
        let calculated_hash = self.calculate_content_hash(&entry)?;
        
        if calculated_hash != entry.content_hash {
            warn!("⚠️  Entry {} failed hash verification", entry_id);
            return Ok(false);
        }
        
        // Verify signature
        if self.config.require_signature {
            if !self.signature.verify(&entry.content_hash, &entry.signature)? {
                warn!("⚠️  Entry {} failed signature verification", entry_id);
                return Ok(false);
            }
        }
        
        // Verify chain
        if let Some(prev_hash) = &entry.previous_hash {
            if entry.entry_number > 1 {
                let prev_entry = self.ledger_writer.get_entry_by_number(entry.entry_number - 1).await?;
                if &prev_entry.content_hash != prev_hash {
                    warn!("⚠️  Entry {} failed chain verification", entry_id);
                    return Ok(false);
                }
            }
        }
        
        info!("✅ Entry {} verified", entry_id);
        Ok(true)
    }
    
    pub async fn verify_chain(&self, start: u64, end: u64) -> Result<bool> {
        info!("🔍 Verifying chain from entry {} to {}", start, end);
        
        for n in start..=end {
            let entry = self.ledger_writer.get_entry_by_number(n).await?;
            if !self.verify_entry(&entry.id).await? {
                error!("❌ Chain verification failed at entry {}", n);
                return Ok(false);
            }
        }
        
        info!("✅ Chain verified: entries {} to {}", start, end);
        Ok(true)
    }
    
    // ========================================================================
    // STATISTICS
    // ========================================================================
    
    pub async fn get_stats(&self) -> LedgerStats {
        let total_entries = *self.entry_counter.read().await;
        
        LedgerStats {
            total_entries,
            ledger_size_bytes: 0, // TODO: Calculate actual size
            oldest_entry: None,
            newest_entry: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LedgerStats {
    pub total_entries: u64,
    pub ledger_size_bytes: u64,
    pub oldest_entry: Option<DateTime<Utc>>,
    pub newest_entry: Option<DateTime<Utc>>,
}

// ============================================================================
// MAIN
// ============================================================================

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    
    info!("⚖️  {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("📜 {}", AGENT_TAGLINE);
    info!("");
    info!("═══════════════════════════════════════════════════════════");
    info!("  THE LEDGER OF TRUTH");
    info!("═══════════════════════════════════════════════════════════");
    info!("");
    info!("Legal Logger is the authoritative keeper of records.");
    info!("");
    info!("Rules:");
    info!("  1. He logs what he's told to log");
    info!("  2. He signs everything cryptographically");
    info!("  3. The ledger is append-only - no deletions");
    info!("  4. Once written, it's permanent");
    info!("  5. History cannot be rewritten");
    info!("");
    info!("This is the source of truth for the Wheeler ecosystem.");
    info!("");
    
    let config = LoggerConfig::default();
    let mut logger = LegalLogger::new(config).await?;
    
    // Example: Log an event
    let request = LogRequest {
        source_agent: "PacketPilot".to_string(),
        user_id: Some("driver-001".to_string()),
        session_id: Some(Uuid::new_v4().to_string()),
        event_type: EventType::DocumentSigned,
        event_data: serde_json::json!({
            "document_type": "rate_confirmation",
            "broker": "XYZ Logistics",
            "rate": 2450.00,
            "load_id": "LOAD-12345"
        }),
        description: "Driver signed rate confirmation for load LOAD-12345".to_string(),
        tags: vec!["signature".to_string(), "rate_con".to_string()],
        metadata: Some(serde_json::json!({
            "ip_address": "192.168.1.100",
            "device": "mobile"
        })),
        encrypt: false,
    };
    
    let response = logger.log_event(request).await?;
    
    info!("");
    info!("✅ Log Response:");
    info!("   Entry ID: {}", response.entry_id.unwrap());
    info!("   Entry #: {}", response.entry_number.unwrap());
    info!("   Timestamp: {}", response.timestamp);
    info!("   Signature: {}...", &response.signature.unwrap()[..16]);
    info!("");
    
    // Verify the entry
    let entry_id = response.entry_id.unwrap();
    let verified = logger.verify_entry(&entry_id).await?;
    
    info!("🔍 Verification: {}", if verified { "✅ PASSED" } else { "❌ FAILED" });
    info!("");
    
    // Get stats
    let stats = logger.get_stats().await;
    info!("📊 Ledger Stats:");
    info!("   Total entries: {}", stats.total_entries);
    info!("");
    
    Ok(())
}
