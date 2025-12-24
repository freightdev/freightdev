// LLM interface for autonomous decision-making
// Uses llama.cpp server (port 11435)

use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;

const LLM_URL: &str = "http://localhost:11435";

#[derive(Debug, Serialize)]
struct CompletionRequest {
    prompt: String,
    max_tokens: u32,
    temperature: f32,
    stop: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct CompletionResponse {
    content: String,
}

pub struct LLMClient {
    client: Client,
}

impl LLMClient {
    pub fn new() -> Self {
        Self {
            client: Client::new(),
        }
    }

    pub async fn complete(&self, prompt: &str, max_tokens: u32) -> Result<String, Box<dyn std::error::Error>> {
        let request = CompletionRequest {
            prompt: prompt.to_string(),
            max_tokens,
            temperature: 0.7,
            stop: vec!["</think>".to_string(), "\n\n\n".to_string()],
        };

        let response = self.client
            .post(format!("{}/completion", LLM_URL))
            .json(&request)
            .timeout(Duration::from_secs(120))
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(format!("LLM request failed: {}", response.status()).into());
        }

        let result: serde_json::Value = response.json().await?;

        // llama.cpp returns {content: "..."}
        let content = result["content"]
            .as_str()
            .unwrap_or("")
            .to_string();

        Ok(content)
    }

    pub async fn decide(&self, context: &str, options: &[&str]) -> Result<String, Box<dyn std::error::Error>> {
        let prompt = format!(
            r#"<think>
You are an autonomous AI coordinator managing a multi-agent system.

CONTEXT:
{}

OPTIONS:
{}

Choose the BEST option and explain your reasoning in one sentence.
Format: "[OPTION_NUMBER] - [reasoning]"
</think>

DECISION:"#,
            context,
            options.iter().enumerate()
                .map(|(i, opt)| format!("{}. {}", i + 1, opt))
                .collect::<Vec<_>>()
                .join("\n")
        );

        let response = self.complete(&prompt, 200).await?;
        Ok(response.trim().to_string())
    }

    pub async fn plan(&self, objective: &str, available_tools: &str) -> Result<String, Box<dyn std::error::Error>> {
        let prompt = format!(
            r#"<think>
You are an autonomous AI coordinator. Plan how to accomplish this objective.

OBJECTIVE: {}

AVAILABLE TOOLS:
{}

Create a step-by-step plan using available tools.
Format each step as: "TOOL_NAME: description"
Keep it to 3-5 steps.
</think>

PLAN:
"#,
            objective,
            available_tools
        );

        let response = self.complete(&prompt, 500).await?;
        Ok(response.trim().to_string())
    }
}
