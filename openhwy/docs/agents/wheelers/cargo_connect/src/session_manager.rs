// Session Manager - Manages active load board sessions
// Keeps you logged in, handles refresh tokens

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoadBoardSession {
    pub session_id: String,
    pub cookies: Vec<Cookie>,
    pub auth_token: Option<String>,
    pub expires_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Cookie {
    pub name: String,
    pub value: String,
    pub domain: String,
}

pub struct SessionManager {
    sessions: Arc<RwLock<HashMap<String, LoadBoardSession>>>,
}

impl SessionManager {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(RwLock::new(HashMap::new())),
        }
    }
    
    pub async fn store_session(&self, account_id: &str, session: LoadBoardSession) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.insert(account_id.to_string(), session);
        tracing::info!("✅ Session stored for account: {}", account_id);
        Ok(())
    }
    
    pub async fn get_session(&self, account_id: &str) -> Result<LoadBoardSession> {
        let sessions = self.sessions.read().await;
        sessions.get(account_id)
            .cloned()
            .ok_or_else(|| anyhow::anyhow!("No active session for account"))
    }
    
    pub async fn revoke_session(&self, account_id: &str) -> Result<()> {
        let mut sessions = self.sessions.write().await;
        sessions.remove(account_id);
        tracing::info!("🔌 Session revoked for account: {}", account_id);
        Ok(())
    }
    
    pub async fn refresh_session(&self, account_id: &str) -> Result<()> {
        // TODO: Implement session refresh logic
        tracing::info!("🔄 Refreshing session for: {}", account_id);
        Ok(())
    }
    
    pub async fn is_session_valid(&self, account_id: &str) -> bool {
        let sessions = self.sessions.read().await;
        if let Some(session) = sessions.get(account_id) {
            if let Some(expires_at) = session.expires_at {
                return expires_at > chrono::Utc::now();
            }
            return true;
        }
        false
    }
}
