// Coordinator Abstraction Layer
// Supports multiple LLM backends: Anthropic, OpenAI, local models

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use thiserror::Error;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerationRequest {
    pub messages: Vec<Message>,
    pub max_tokens: Option<u32>,
    pub temperature: Option<f32>,
    pub system: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerationResponse {
    pub content: String,
    pub model: String,
    pub usage: TokenUsage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenUsage {
    pub input_tokens: u32,
    pub output_tokens: u32,
    pub total_tokens: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CoordinatorType {
    Anthropic,
    OpenAI,
    Local(String), // model name
}

// ============================================================================
// Errors
// ============================================================================

#[derive(Debug, Error)]
pub enum CoordinatorError {
    #[error("Request failed: {0}")]
    RequestFailed(String),

    #[error("Invalid response: {0}")]
    InvalidResponse(String),

    #[error("Authentication failed")]
    AuthenticationFailed,

    #[error("Model not available: {0}")]
    ModelNotAvailable(String),

    #[error("Rate limited")]
    RateLimited,

    #[error("Context length exceeded")]
    ContextTooLong,
}

pub type Result<T> = std::result::Result<T, CoordinatorError>;

// ============================================================================
// Trait
// ============================================================================

#[async_trait]
pub trait Coordinator: Send + Sync {
    /// Generate a response
    async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse>;

    /// Get coordinator type
    fn coordinator_type(&self) -> CoordinatorType;

    /// Health check
    async fn health(&self) -> bool;

    /// Get model name
    fn model_name(&self) -> String;
}

// ============================================================================
// Anthropic API Implementation
// ============================================================================

pub struct AnthropicCoordinator {
    api_key: String,
    model: String,
    client: reqwest::Client,
}

impl AnthropicCoordinator {
    pub fn new(api_key: String, model: Option<String>) -> Self {
        Self {
            api_key,
            model: model.unwrap_or_else(|| "claude-sonnet-4-5-20250929".to_string()),
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl Coordinator for AnthropicCoordinator {
    async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse> {
        // Convert to Anthropic API format
        let mut body = serde_json::json!({
            "model": self.model,
            "messages": request.messages,
            "max_tokens": request.max_tokens.unwrap_or(4096),
        });

        if let Some(system) = request.system {
            body["system"] = serde_json::json!(system);
        }

        if let Some(temp) = request.temperature {
            body["temperature"] = serde_json::json!(temp);
        }

        // Make request
        let response = self
            .client
            .post("https://api.anthropic.com/v1/messages")
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("content-type", "application/json")
            .json(&body)
            .send()
            .await
            .map_err(|e| CoordinatorError::RequestFailed(e.to_string()))?;

        if !response.status().is_success() {
            return Err(CoordinatorError::RequestFailed(format!(
                "HTTP {}",
                response.status()
            )));
        }

        // Parse response
        let json: serde_json::Value = response
            .json()
            .await
            .map_err(|e| CoordinatorError::InvalidResponse(e.to_string()))?;

        let content = json["content"][0]["text"]
            .as_str()
            .ok_or_else(|| CoordinatorError::InvalidResponse("No content".to_string()))?
            .to_string();

        let usage = TokenUsage {
            input_tokens: json["usage"]["input_tokens"].as_u64().unwrap_or(0) as u32,
            output_tokens: json["usage"]["output_tokens"].as_u64().unwrap_or(0) as u32,
            total_tokens: json["usage"]["input_tokens"].as_u64().unwrap_or(0) as u32
                + json["usage"]["output_tokens"].as_u64().unwrap_or(0) as u32,
        };

        Ok(GenerationResponse {
            content,
            model: self.model.clone(),
            usage,
        })
    }

    fn coordinator_type(&self) -> CoordinatorType {
        CoordinatorType::Anthropic
    }

    async fn health(&self) -> bool {
        // Simple health check - try to reach the API
        self.client
            .get("https://api.anthropic.com")
            .send()
            .await
            .is_ok()
    }

    fn model_name(&self) -> String {
        self.model.clone()
    }
}

// ============================================================================
// OpenAI Implementation
// ============================================================================

pub struct OpenAICoordinator {
    api_key: String,
    model: String,
    client: reqwest::Client,
}

impl OpenAICoordinator {
    pub fn new(api_key: String, model: Option<String>) -> Self {
        Self {
            api_key,
            model: model.unwrap_or_else(|| "gpt-4o".to_string()),
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl Coordinator for OpenAICoordinator {
    async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse> {
        let mut messages = request.messages;

        // Add system message if provided
        if let Some(system) = request.system {
            messages.insert(
                0,
                Message {
                    role: "system".to_string(),
                    content: system,
                },
            );
        }

        let body = serde_json::json!({
            "model": self.model,
            "messages": messages,
            "max_tokens": request.max_tokens.unwrap_or(4096),
            "temperature": request.temperature.unwrap_or(0.7),
        });

        let response = self
            .client
            .post("https://api.openai.com/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .send()
            .await
            .map_err(|e| CoordinatorError::RequestFailed(e.to_string()))?;

        if !response.status().is_success() {
            return Err(CoordinatorError::RequestFailed(format!(
                "HTTP {}",
                response.status()
            )));
        }

        let json: serde_json::Value = response
            .json()
            .await
            .map_err(|e| CoordinatorError::InvalidResponse(e.to_string()))?;

        let content = json["choices"][0]["message"]["content"]
            .as_str()
            .ok_or_else(|| CoordinatorError::InvalidResponse("No content".to_string()))?
            .to_string();

        let usage = TokenUsage {
            input_tokens: json["usage"]["prompt_tokens"].as_u64().unwrap_or(0) as u32,
            output_tokens: json["usage"]["completion_tokens"].as_u64().unwrap_or(0) as u32,
            total_tokens: json["usage"]["total_tokens"].as_u64().unwrap_or(0) as u32,
        };

        Ok(GenerationResponse {
            content,
            model: self.model.clone(),
            usage,
        })
    }

    fn coordinator_type(&self) -> CoordinatorType {
        CoordinatorType::OpenAI
    }

    async fn health(&self) -> bool {
        self.client
            .get("https://api.openai.com/v1/models")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .send()
            .await
            .is_ok()
    }

    fn model_name(&self) -> String {
        self.model.clone()
    }
}

// ============================================================================
// Local Model Implementation (llama.cpp via Ollama)
// ============================================================================

pub struct LocalCoordinator {
    endpoint: String,
    model: String,
    client: reqwest::Client,
}

impl LocalCoordinator {
    pub fn new(endpoint: String, model: String) -> Self {
        Self {
            endpoint,
            model,
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl Coordinator for LocalCoordinator {
    async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse> {
        // Build prompt from messages
        let mut prompt = String::new();
        if let Some(system) = request.system {
            prompt.push_str(&format!("System: {}\n\n", system));
        }

        for msg in &request.messages {
            prompt.push_str(&format!("{}: {}\n", msg.role, msg.content));
        }

        let body = serde_json::json!({
            "model": self.model,
            "prompt": prompt,
            "stream": false,
            "options": {
                "temperature": request.temperature.unwrap_or(0.7),
                "num_predict": request.max_tokens.unwrap_or(2048),
            }
        });

        let url = format!("{}/api/generate", self.endpoint);
        let response = self
            .client
            .post(&url)
            .json(&body)
            .send()
            .await
            .map_err(|e| CoordinatorError::RequestFailed(e.to_string()))?;

        if !response.status().is_success() {
            return Err(CoordinatorError::RequestFailed(format!(
                "HTTP {}",
                response.status()
            )));
        }

        let json: serde_json::Value = response
            .json()
            .await
            .map_err(|e| CoordinatorError::InvalidResponse(e.to_string()))?;

        let content = json["response"]
            .as_str()
            .ok_or_else(|| CoordinatorError::InvalidResponse("No response".to_string()))?
            .to_string();

        // Ollama doesn't provide detailed token usage
        let usage = TokenUsage {
            input_tokens: 0,
            output_tokens: 0,
            total_tokens: 0,
        };

        Ok(GenerationResponse {
            content,
            model: self.model.clone(),
            usage,
        })
    }

    fn coordinator_type(&self) -> CoordinatorType {
        CoordinatorType::Local(self.model.clone())
    }

    async fn health(&self) -> bool {
        let url = format!("{}/api/tags", self.endpoint);
        self.client.get(&url).send().await.is_ok()
    }

    fn model_name(&self) -> String {
        self.model.clone()
    }
}

// ============================================================================
// Coordinator Manager (Failover Support)
// ============================================================================

pub struct CoordinatorManager {
    coordinators: Vec<Arc<dyn Coordinator>>,
    current_index: std::sync::atomic::AtomicUsize,
}

impl CoordinatorManager {
    pub fn new(coordinators: Vec<Arc<dyn Coordinator>>) -> Self {
        Self {
            coordinators,
            current_index: std::sync::atomic::AtomicUsize::new(0),
        }
    }

    pub async fn generate(&self, request: GenerationRequest) -> Result<GenerationResponse> {
        let start_index = self
            .current_index
            .load(std::sync::atomic::Ordering::Relaxed);

        // Try current coordinator
        for offset in 0..self.coordinators.len() {
            let index = (start_index + offset) % self.coordinators.len();
            let coordinator = &self.coordinators[index];

            // Check health first
            if !coordinator.health().await {
                tracing::warn!(
                    "Coordinator {} is unhealthy, trying next",
                    coordinator.model_name()
                );
                continue;
            }

            // Try generation
            match coordinator.generate(request.clone()).await {
                Ok(response) => {
                    // Update current index if we failed over
                    if index != start_index {
                        tracing::info!(
                            "Failed over to coordinator: {}",
                            coordinator.model_name()
                        );
                        self.current_index
                            .store(index, std::sync::atomic::Ordering::Relaxed);
                    }
                    return Ok(response);
                }
                Err(e) => {
                    tracing::error!(
                        "Coordinator {} failed: {}",
                        coordinator.model_name(),
                        e
                    );
                    continue;
                }
            }
        }

        Err(CoordinatorError::ModelNotAvailable(
            "All coordinators failed".to_string(),
        ))
    }

    pub fn current_coordinator(&self) -> &Arc<dyn Coordinator> {
        let index = self
            .current_index
            .load(std::sync::atomic::Ordering::Relaxed);
        &self.coordinators[index]
    }
}
