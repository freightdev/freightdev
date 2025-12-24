// CoDriver v0.1 - Autonomous coordinator
// Uses hostbox qwen2.5:14b as brain
// Monitors openhwy/..codriver/chats/codriver.txt for tasks
// Functions: {
//   initialize, verify_ollama, check_new_messages, query_brain,
//   respond, handle_task, run
// } -> main

use reqwest::Client;
use serde_json::json;
use std::fs;
use std::path::Path;
use std::time::Duration;
use tokio::time::sleep;

const WORKBOX_OLLAMA: &str = "http://192.168.12.136:11434";
const BRAIN_MODEL: &str = "qwen2.5-coder:14b-instruct-q4_K_M";
const CHAT_FILE: &str = "/home/admin/freightdev/openhwy/.codriver/chats/codriver.txt";
const CHECK_INTERVAL_MS: u64 = 500;

struct CoDriver {
    client: Client,
    last_line_count: usize,
}

impl CoDriver {
    fn new() -> Self {
        Self {
            client: Client::new(),
            last_line_count: 0,
        }
    }

    async fn initialize(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("CoDriver v0.1 Online");
        println!("Brain: helpbox qwen2.5-coder:14b-instruct-q4_K_M");
        println!("Monitoring: {}", CHAT_FILE);
        println!();

        // Create chat file if it doesn't exist
        if !Path::new(CHAT_FILE).exists() {
            fs::write(CHAT_FILE, "# CoDriver Chat\n# Write messages as: user: \"your message\"\n\n")?;
        }

        // Count existing lines
        let content = fs::read_to_string(CHAT_FILE)?;
        self.last_line_count = content.lines().count();

        // Verify Ollama connection
        println!("Verifying Ollama connection...");
        match self.verify_ollama().await {
            Ok(_) => println!("✓ Connected to hostbox Ollama"),
            Err(e) => {
                eprintln!("Cannot connect to hostbox Ollama: {}", e);
                return Err(e);
            }
        }

        println!("\n✅ CoDriver ready!\n");
        Ok(())
    }

    async fn verify_ollama(&self) -> Result<(), Box<dyn std::error::Error>> {
        let response = self.client
            .get(format!("{}/api/tags", HELPBOX_OLLAMA))
            .timeout(Duration::from_secs(5))
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(format!("Ollama returned: {}", response.status()).into());
        }

        Ok(())
    }

    async fn check_new_messages(&mut self) -> Result<Option<String>, Box<dyn std::error::Error>> {
        let content = fs::read_to_string(CHAT_FILE)?;
        let lines: Vec<&str> = content.lines().collect();

        if lines.len() > self.last_line_count {
            // Get new lines
            let new_lines: Vec<&str> = lines[self.last_line_count..].to_vec();
            self.last_line_count = lines.len();

            // Find last user message
            for line in new_lines.iter().rev() {
                if line.trim().starts_with("user:") {
                    let message = line.trim()
                        .strip_prefix("user:")
                        .unwrap_or("")
                        .trim()
                        .trim_matches('"')
                        .to_string();

                    if !message.is_empty() {
                        return Ok(Some(message));
                    }
                }
            }
        }

        Ok(None)
    }

    async fn query_brain(&self, prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
        let payload = json!({
            "model": BRAIN_MODEL,
            "prompt": prompt,
            "stream": false,
            "options": {
                "temperature": 0.7,
                "num_predict": 500
            }
        });

        let response = self.client
            .post(format!("{}/api/generate", HELPBOX_OLLAMA))
            .json(&payload)
            .timeout(Duration::from_secs(120))
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(format!("Ollama query failed: {}", response.status()).into());
        }

        let result: serde_json::Value = response.json().await?;
        let answer = result["response"]
            .as_str()
            .unwrap_or("(no response)")
            .trim()
            .to_string();

        Ok(answer)
    }

    fn respond(&self, message: &str) -> Result<(), Box<dyn std::error::Error>> {
        // Read current content
        let mut content = fs::read_to_string(CHAT_FILE)?;

        // Append codriver response
        content.push_str(&format!("codriver: \"{}\"\n", message));

        // Write back
        fs::write(CHAT_FILE, content)?;

        Ok(())
    }

    async fn handle_task(&self, task: String) -> Result<(), Box<dyn std::error::Error>> {
        println!("📥 User task: {}", task);

        // Acknowledge receipt
        self.respond("Received. Thinking...")?;

        // Build decision prompt
        let decision_prompt = format!(
            r#"You are CoDriver, an autonomous AI coordinator managing a 4-node Ollama cluster.

User task: "{}"

Available capabilities:
1. generate_component - Generate React/TypeScript components using helpbox (L3)
2. find_leads - Search for paid development work ($1k+ gigs)
3. analyze_image - Process images using workbox (L1)
4. search_web - Search the web for information
5. respond_only - Just respond to the user's message

What should you do? Respond with ONLY the capability name (e.g., "generate_component" or "respond_only").
If it's just a greeting or conversation, use "respond_only"."#,
            task
        );

        // Ask brain what to do
        let decision = self.query_brain(&decision_prompt).await?;
        let action = decision.lines().next().unwrap_or("respond_only").trim().to_lowercase();

        println!("🧠 Decision: {}", action);

        // Execute based on decision
        match action.as_str() {
            s if s.contains("respond_only") || s.contains("conversation") => {
                let response_prompt = format!(
                    r#"You are CoDriver, a friendly autonomous AI assistant.

User message: "{}"

Respond helpfully and concisely (1-3 sentences max)."#,
                    task
                );

                let response = self.query_brain(&response_prompt).await?;
                self.respond(&response)?;
                println!("✓ Responded to user\n");
            }

            s if s.contains("generate_component") || s.contains("code") => {
                self.respond("Code generation coming soon! (Need to route to helpbox L3)")?;
                println!("⚠️  Code generation not implemented yet\n");
            }

            s if s.contains("find_leads") => {
                self.respond("Lead generation coming soon!")?;
                println!("⚠️  Lead generation not implemented yet\n");
            }

            _ => {
                self.respond("Not sure how to handle that yet. Try asking me something else!")?;
                println!("⚠️  Unknown action: {}\n", action);
            }
        }

        Ok(())
    }

    async fn run(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        loop {
            // Check for new user messages
            if let Some(task) = self.check_new_messages().await? {
                if let Err(e) = self.handle_task(task).await {
                    eprintln!("❌ Task failed: {}", e);
                    self.respond(&format!("Error: {}", e))?;
                }
            }

            // Sleep briefly
            sleep(Duration::from_millis(CHECK_INTERVAL_MS)).await;
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut codriver = CoDriver::new();
    codriver.initialize().await?;
    codriver.run().await?;

    Ok(())
}
