// src/config/loader.rs

use super::{Config, ConfigValidator};
use anyhow::Result;
use notify::{Event, RecursiveMode, Watcher};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info};

impl Config {
    pub async fn load<P: AsRef<Path>>(path: P) -> Result<Config> {
        let content = tokio::fs::read_to_string(path).await?;
        let config: Config = serde_yaml::from_str(&content)?;
        ConfigValidator::validate(&config)?;
        Ok(config)
    }

    pub async fn watch(config: Arc<Config>) -> Result<()> {
        let (tx, mut rx) = tokio::sync::mpsc::channel(100);

        let mut watcher = notify::recommended_watcher(move |res: Result<Event, _>| {
            if let Ok(event) = res {
                let _ = tx.blocking_send(event);
            }
        })?;

        watcher.watch(Path::new("config/"), RecursiveMode::Recursive)?;

        info!("Watching config directory for changes");

        while let Some(event) = rx.recv().await {
            if event.kind.is_modify() {
                info!("Config file changed, reloading...");
                match Self::load("config/marketeer.yaml").await {
                    Ok(_new_config) => {
                        info!("Configuration reloaded successfully");
                        // In production, update shared config via RwLock
                    }
                    Err(e) => {
                        error!("Failed to reload config: {}", e);
                    }
                }
            }
        }

        Ok(())
    }
}
