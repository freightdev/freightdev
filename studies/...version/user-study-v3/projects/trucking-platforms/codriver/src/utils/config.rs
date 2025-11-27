//! config.rs - Loads and parses codriver.yaml for runtime configuration.

use std::fs;
use std::path::Path;

use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct CoDriverConfig {
    pub model: String,
    pub temperature: f32,
    pub top_p: f32,
    pub max_tokens: usize,
    pub stream: bool,
    pub memory_context: bool,
}

impl Default for CoDriverConfig {
    fn default() -> Self {
        Self {
            model: "mistral".into(),
            temperature: 0.7,
            top_p: 0.95,
            max_tokens: 1024,
            stream: true,
            memory_context: true,
        }
    }
}

pub fn load_config() -> CoDriverConfig {
    let path = Path::new("codriver.yaml");
    if path.exists() {
        let raw = fs::read_to_string(path)
            .unwrap_or_else(|_| panic!("❌ Failed to read {}", path.display()));
        serde_yaml::from_str(&raw).unwrap_or_else(|_| {
            eprintln!("⚠️  Failed to parse config, falling back to default.");
            CoDriverConfig::default()
        })
    } else {
        CoDriverConfig::default()
    }
}
