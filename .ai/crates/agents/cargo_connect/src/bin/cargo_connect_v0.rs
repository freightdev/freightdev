// CargoConnect v0.0.1
// "Connect your own freight. No middleman. No scraping games."
//
// CargoConnect is NOT a load board.
// It's a bridge to YOUR load boards.
// 
// Your credentials. Your data. Your control.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, warn, error};
use uuid::Uuid;

mod credential_vault;
mod session_manager;
mod load_fetcher;
mod filter_engine;
mod score_ranker;
mod load_boards;

use credential_vault::CredentialVault;
use session_manager::SessionManager;
use load_fetcher::LoadFetcher;
use filter_engine::FilterEngine;
use score_ranker::ScoreRanker;
use load_boards::LoadBoardConnector;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "CC";
const AGENT_NAME: &str = "CargoConnect";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "Connect your own freight. No middleman. No scraping games.";

// ============================================================================
// DATA STRUCTURES
// ============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LoadBoardAccount {
    pub id: String,
    pub user_id: String,
    pub board_type: LoadBoardType,
    pub username: String,
    #[serde(skip_serializing)]
    pub password_encrypted: Vec<u8>,
    pub status: AccountStatus,
    pub connected_at: Option<DateTime<Utc>>,
    pub last_sync: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum LoadBoardType {
    DAT,
    Truckstop,
    J1Freight,
    DirectFreight,
    CH Robinson,
    TQL,
    Coyote,
    Custom(String),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum AccountStatus {
    Connected,
    Disconnected,
    Expired,
    Error,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FreightLoad {
    pub id: String,
    pub source_board: LoadBoardType,
    pub external_id: String,
    
    // Origin & Destination
    pub origin_city: String,
    pub origin_state: String,
    pub origin_zip: Option<String>,
    pub destination_city: String,
    pub destination_state: String,
    pub destination_zip: Option<String>,
    
    // Timing
    pub pickup_date: String,
    pub delivery_date: Option<String>,
    
    // Equipment
    pub equipment_type: String,
    pub length_feet: Option<f32>,
    pub weight_lbs: Option<u32>,
    
    // Financial
    pub rate: Option<f32>,
    pub rate_per_mile: Option<f32>,
    pub distance_miles: Option<u32>,
    
    // Details
    pub commodity: Option<String>,
    pub broker: Option<String>,
    pub contact: Option<String>,
    pub phone: Option<String>,
    pub special_requirements: Vec<String>,
    
    // Metadata
    pub posted_at: Option<DateTime<Utc>>,
    pub fetched_at: DateTime<Utc>,
    pub score: Option<f32>, // Ranked score
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoadFilter {
    pub origin_states: Option<Vec<String>>,
    pub destination_states: Option<Vec<String>>,
    pub equipment_types: Option<Vec<String>>,
    pub min_rate: Option<f32>,
    pub max_rate: Option<f32>,
    pub min_rate_per_mile: Option<f32>,
    pub min_distance: Option<u32>,
    pub max_distance: Option<u32>,
    pub min_weight: Option<u32>,
    pub max_weight: Option<u32>,
    pub pickup_date_start: Option<String>,
    pub pickup_date_end: Option<String>,
}

// ============================================================================
// REQUEST/RESPONSE TYPES
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct CargoConnectRequest {
    pub action: CargoAction,
    pub user_id: String,
    pub data: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum CargoAction {
    #[serde(rename = "connect_account")]
    ConnectAccount {
        board_type: LoadBoardType,
        username: String,
        password: String,
    },
    
    #[serde(rename = "disconnect_account")]
    DisconnectAccount {
        account_id: String,
    },
    
    #[serde(rename = "fetch_loads")]
    FetchLoads {
        account_ids: Option<Vec<String>>, // If None, fetch from all
    },
    
    #[serde(rename = "apply_filter")]
    ApplyFilter {
        filter: LoadFilter,
        loads: Vec<FreightLoad>,
    },
    
    #[serde(rename = "rank_loads")]
    RankLoads {
        loads: Vec<FreightLoad>,
        preferences: ScoringPreferences,
    },
    
    #[serde(rename = "list_accounts")]
    ListAccounts,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ScoringPreferences {
    pub preferred_lanes: Vec<Lane>,
    pub rate_importance: f32,      // 0.0 - 1.0
    pub distance_importance: f32,   // 0.0 - 1.0
    pub deadhead_penalty: f32,      // 0.0 - 1.0
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Lane {
    pub origin_state: String,
    pub destination_state: String,
    pub preference_score: f32, // 0.0 - 1.0
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CargoConnectResponse {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
}

// ============================================================================
// CARGOCONNECT AGENT
// ============================================================================

pub struct CargoConnect {
    credential_vault: CredentialVault,
    session_manager: SessionManager,
    load_fetcher: LoadFetcher,
    filter_engine: FilterEngine,
    score_ranker: ScoreRanker,
    
    // Active accounts per user
    accounts: Arc<RwLock<HashMap<String, Vec<LoadBoardAccount>>>>,
}

impl CargoConnect {
    pub async fn new() -> Result<Self> {
        info!("🔗 Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("📦 {}", AGENT_TAGLINE);
        
        Ok(Self {
            credential_vault: CredentialVault::new()?,
            session_manager: SessionManager::new(),
            load_fetcher: LoadFetcher::new().await?,
            filter_engine: FilterEngine::new(),
            score_ranker: ScoreRanker::new(),
            accounts: Arc::new(RwLock::new(HashMap::new())),
        })
    }
    
    pub async fn handle_request(&mut self, request: CargoConnectRequest) -> Result<CargoConnectResponse> {
        info!("📥 Handling request: {:?}", request.action);
        
        let result = match request.action {
            CargoAction::ConnectAccount { board_type, username, password } => {
                self.connect_account(request.user_id, board_type, username, password).await
            }
            
            CargoAction::DisconnectAccount { account_id } => {
                self.disconnect_account(request.user_id, account_id).await
            }
            
            CargoAction::FetchLoads { account_ids } => {
                self.fetch_loads(request.user_id, account_ids).await
            }
            
            CargoAction::ApplyFilter { filter, loads } => {
                self.apply_filter(filter, loads).await
            }
            
            CargoAction::RankLoads { loads, preferences } => {
                self.rank_loads(loads, preferences).await
            }
            
            CargoAction::ListAccounts => {
                self.list_accounts(request.user_id).await
            }
        };
        
        match result {
            Ok(data) => Ok(CargoConnectResponse {
                success: true,
                message: "Request completed".to_string(),
                data: Some(data),
            }),
            Err(e) => {
                error!("Request failed: {}", e);
                Ok(CargoConnectResponse {
                    success: false,
                    message: format!("Request failed: {}", e),
                    data: None,
                })
            }
        }
    }
    
    // ========================================================================
    // CORE OPERATIONS
    // ========================================================================
    
    async fn connect_account(
        &mut self,
        user_id: String,
        board_type: LoadBoardType,
        username: String,
        password: String,
    ) -> Result<serde_json::Value> {
        info!("🔐 Connecting account for user {} to {:?}", user_id, board_type);
        
        // Test the connection first
        let connector = LoadBoardConnector::new(board_type.clone());
        let session = connector.login(&username, &password).await
            .context("Failed to authenticate with load board")?;
        
        info!("✅ Authentication successful");
        
        // Encrypt and store credentials
        let password_encrypted = self.credential_vault.encrypt(&password)?;
        
        let account = LoadBoardAccount {
            id: Uuid::new_v4().to_string(),
            user_id: user_id.clone(),
            board_type: board_type.clone(),
            username: username.clone(),
            password_encrypted,
            status: AccountStatus::Connected,
            connected_at: Some(Utc::now()),
            last_sync: None,
        };
        
        // Store session
        self.session_manager.store_session(&account.id, session).await?;
        
        // Add to accounts
        let mut accounts = self.accounts.write().await;
        accounts.entry(user_id.clone())
            .or_insert_with(Vec::new)
            .push(account.clone());
        
        info!("✅ Account connected: {}", account.id);
        
        Ok(serde_json::json!({
            "account_id": account.id,
            "board_type": format!("{:?}", board_type),
            "status": "connected",
        }))
    }
    
    async fn disconnect_account(
        &mut self,
        user_id: String,
        account_id: String,
    ) -> Result<serde_json::Value> {
        info!("🔌 Disconnecting account: {}", account_id);
        
        // Revoke session
        self.session_manager.revoke_session(&account_id).await?;
        
        // Remove from accounts
        let mut accounts = self.accounts.write().await;
        if let Some(user_accounts) = accounts.get_mut(&user_id) {
            user_accounts.retain(|a| a.id != account_id);
        }
        
        info!("✅ Account disconnected");
        
        Ok(serde_json::json!({
            "status": "disconnected",
        }))
    }
    
    async fn fetch_loads(
        &mut self,
        user_id: String,
        account_ids: Option<Vec<String>>,
    ) -> Result<serde_json::Value> {
        info!("📦 Fetching loads for user: {}", user_id);
        
        let accounts = self.accounts.read().await;
        let user_accounts = accounts.get(&user_id)
            .context("No accounts found for user")?;
        
        // Filter accounts if specific IDs provided
        let accounts_to_fetch: Vec<&LoadBoardAccount> = if let Some(ids) = account_ids {
            user_accounts.iter()
                .filter(|a| ids.contains(&a.id))
                .collect()
        } else {
            user_accounts.iter().collect()
        };
        
        if accounts_to_fetch.is_empty() {
            anyhow::bail!("No accounts available to fetch from");
        }
        
        info!("📊 Fetching from {} account(s)", accounts_to_fetch.len());
        
        // Fetch loads from each account
        let mut all_loads = Vec::new();
        
        for account in accounts_to_fetch {
            match self.fetch_from_account(account).await {
                Ok(loads) => {
                    info!("✅ Fetched {} loads from {:?}", loads.len(), account.board_type);
                    all_loads.extend(loads);
                }
                Err(e) => {
                    warn!("⚠️  Failed to fetch from {:?}: {}", account.board_type, e);
                }
            }
        }
        
        info!("✅ Total loads fetched: {}", all_loads.len());
        
        Ok(serde_json::json!({
            "loads": all_loads,
            "total": all_loads.len(),
        }))
    }
    
    async fn fetch_from_account(&self, account: &LoadBoardAccount) -> Result<Vec<FreightLoad>> {
        // Get session
        let session = self.session_manager.get_session(&account.id).await?;
        
        // Fetch loads
        let loads = self.load_fetcher.fetch(
            &account.board_type,
            &session,
        ).await?;
        
        Ok(loads)
    }
    
    async fn apply_filter(
        &self,
        filter: LoadFilter,
        loads: Vec<FreightLoad>,
    ) -> Result<serde_json::Value> {
        info!("🔍 Applying filter to {} loads", loads.len());
        
        let filtered = self.filter_engine.filter(loads, filter);
        
        info!("✅ Filtered to {} loads", filtered.len());
        
        Ok(serde_json::json!({
            "loads": filtered,
            "count": filtered.len(),
        }))
    }
    
    async fn rank_loads(
        &self,
        loads: Vec<FreightLoad>,
        preferences: ScoringPreferences,
    ) -> Result<serde_json::Value> {
        info!("📊 Ranking {} loads", loads.len());
        
        let ranked = self.score_ranker.rank(loads, preferences);
        
        info!("✅ Loads ranked");
        
        Ok(serde_json::json!({
            "loads": ranked,
            "count": ranked.len(),
        }))
    }
    
    async fn list_accounts(&self, user_id: String) -> Result<serde_json::Value> {
        let accounts = self.accounts.read().await;
        let user_accounts = accounts.get(&user_id)
            .map(|a| a.clone())
            .unwrap_or_default();
        
        Ok(serde_json::json!({
            "accounts": user_accounts,
            "count": user_accounts.len(),
        }))
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
    
    info!("🔗 {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("📦 {}", AGENT_TAGLINE);
    info!("");
    info!("Your credentials. Your data. Your control.");
    info!("No middleman. No scraping games.");
    info!("");
    
    let mut cargo = CargoConnect::new().await?;
    
    // Example: Connect to DAT
    let request = CargoConnectRequest {
        action: CargoAction::ConnectAccount {
            board_type: LoadBoardType::DAT,
            username: "demo@fed.com".to_string(),
            password: "demo-password".to_string(),
        },
        user_id: "user-001".to_string(),
        data: serde_json::json!({}),
    };
    
    let response = cargo.handle_request(request).await?;
    info!("✅ Response: {}", serde_json::to_string_pretty(&response)?);
    
    Ok(())
}
