// Autonomous Agent - Main orchestration logic

use crate::llm::LLMClient;
use crate::tools::{ToolRegistry, ToolCall};
use crate::system::SystemMap;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::Duration;
use tokio::time::sleep;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentState {
    pub current_objective: String,
    pub completed_tasks: Vec<String>,
    pub last_decision: String,
    pub cycle_count: u64,
}

pub struct AutonomousAgent {
    llm: LLMClient,
    tools: ToolRegistry,
    system: SystemMap,
    state: AgentState,
}

impl AutonomousAgent {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Self::with_objective("Monitor and improve CoDriver system".to_string()).await
    }

    pub async fn with_objective(objective: String) -> Result<Self, Box<dyn std::error::Error>> {
        Ok(Self {
            llm: LLMClient::new(),
            tools: ToolRegistry::new(),
            system: SystemMap::new(),
            state: AgentState {
                current_objective: objective,
                completed_tasks: Vec::new(),
                last_decision: String::new(),
                cycle_count: 0,
            },
        })
    }

    pub async fn run(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🚀 Starting autonomous operation loop...");
        println!();

        // Initial health check
        self.check_system_health().await?;

        loop {
            self.state.cycle_count += 1;

            println!("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            println!("🔄 Cycle #{} - {}", self.state.cycle_count, Utc::now().format("%H:%M:%S"));
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

            // Step 1: Gather context
            let context = self.gather_context().await?;

            // Step 2: Decide what to do
            let decision = self.make_decision(&context).await?;
            self.state.last_decision = decision.clone();

            // Step 3: Create plan
            let plan = self.create_plan(&decision).await?;

            // Step 4: Execute plan
            self.execute_plan(&plan).await?;

            // Step 5: Reflect on results
            self.reflect().await?;

            // Wait before next cycle (2 minutes)
            println!("\n💤 Sleeping for 2 minutes...");
            sleep(Duration::from_secs(120)).await;
        }
    }

    async fn check_system_health(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🏥 Checking system health...");

        // Check LLM
        match self.llm.complete("Say 'OK'", 10).await {
            Ok(_) => println!("  ✓ LLM server responding"),
            Err(e) => {
                println!("  ✗ LLM server error: {}", e);
                return Err("LLM not available".into());
            }
        }

        // Check database
        let mut params = HashMap::new();
        params.insert("command".to_string(), "systemctl --user is-active surrealdb".to_string());

        match self.tools.execute(&ToolCall {
            tool: "bash".to_string(),
            parameters: params,
        }).await {
            Ok(result) if result.success => println!("  ✓ SurrealDB running"),
            _ => println!("  ⚠ SurrealDB may not be running"),
        }

        // Check lead services
        let services = vec!["lead-scraper", "lead-analyzer", "lead-manager"];
        for service in services {
            let mut params = HashMap::new();
            params.insert("command".to_string(), format!("systemctl --user is-active {}", service));

            match self.tools.execute(&ToolCall {
                tool: "bash".to_string(),
                parameters: params,
            }).await {
                Ok(result) if result.success => println!("  ✓ {} running", service),
                _ => println!("  ⚠ {} may not be running", service),
            }
        }

        println!();
        Ok(())
    }

    async fn gather_context(&self) -> Result<String, Box<dyn std::error::Error>> {
        println!("📊 Gathering context...");

        // Get system status
        let mut params = HashMap::new();
        params.insert("command".to_string(), "./bin/core/system-status.sh".to_string());

        let status_result = self.tools.execute(&ToolCall {
            tool: "bash".to_string(),
            parameters: params,
        }).await?;

        // Build context summary
        let context = format!(
            r#"CURRENT STATE:
Cycle: {}
Objective: {}
Last Decision: {}
Completed Tasks: {}

SYSTEM STATUS:
{}

AVAILABLE TOOLS:
{}

SYSTEM RESOURCES:
{}"#,
            self.state.cycle_count,
            self.state.current_objective,
            if self.state.last_decision.is_empty() { "None yet" } else { &self.state.last_decision },
            self.state.completed_tasks.len(),
            if status_result.success {
                status_result.output.lines().take(20).collect::<Vec<_>>().join("\n")
            } else {
                "Status check failed".to_string()
            },
            self.tools.describe_all(),
            self.system.describe_all()
        );

        Ok(context)
    }

    async fn make_decision(&self, context: &str) -> Result<String, Box<dyn std::error::Error>> {
        println!("🧠 Making decision...");

        let options = vec![
            "Check and update system status using scripts",
            "Run lead generation pipeline (scrape -> analyze -> digest)",
            "Call an agent to perform a specific task",
            "Start a built agent that's not running",
            "Test and verify all services working",
            "Monitor and wait (everything running smoothly)",
        ];

        let decision = self.llm.decide(context, &options).await?;

        println!("💭 Decision: {}", decision);

        Ok(decision)
    }

    async fn create_plan(&self, decision: &str) -> Result<String, Box<dyn std::error::Error>> {
        println!("📋 Creating plan...");

        let plan = self.llm.plan(decision, &self.tools.describe_all()).await?;

        println!("📝 Plan:\n{}", plan);

        Ok(plan)
    }

    async fn execute_plan(&self, plan: &str) -> Result<(), Box<dyn std::error::Error>> {
        println!("\n⚡ Executing plan...");

        // Parse plan into tool calls
        let steps: Vec<&str> = plan.lines()
            .filter(|line| !line.trim().is_empty())
            .collect();

        for (i, step) in steps.iter().enumerate() {
            println!("\n  Step {}/{}: {}", i + 1, steps.len(), step);

            // Simple parsing: "TOOL_NAME: description"
            if let Some((tool, description)) = step.split_once(':') {
                let tool_name = tool.trim().to_lowercase();

                match tool_name.as_str() {
                    "bash" => {
                        let cmd = description.trim();
                        let mut params = HashMap::new();
                        params.insert("command".to_string(), cmd.to_string());

                        match self.tools.execute(&ToolCall {
                            tool: "bash".to_string(),
                            parameters: params,
                        }).await {
                            Ok(result) => {
                                println!("    ✓ {}", if result.success { "Success" } else { "Failed" });
                                if !result.output.is_empty() {
                                    let output_preview = result.output.lines().take(5).collect::<Vec<_>>().join("\n           ");
                                    println!("    Output: {}", output_preview);
                                }
                            }
                            Err(e) => println!("    ✗ Error: {}", e),
                        }
                    }
                    "call_agent" => {
                        // Extract agent name from description
                        let agent_desc = description.trim();
                        println!("    🤖 Calling agent: {}", agent_desc);

                        // Try to parse agent call (format: "agent_name endpoint payload")
                        let parts: Vec<&str> = agent_desc.split_whitespace().collect();
                        if parts.len() >= 2 {
                            let agent_name = parts[0];
                            let endpoint = parts[1];

                            if let Some(agent_info) = self.system.get_agent(agent_name) {
                                let url = format!("http://localhost:{}{}", agent_info.port, endpoint);
                                println!("    → Calling: {}", url);

                                let mut params = HashMap::new();
                                params.insert("command".to_string(),
                                    format!("curl -s {}", url));

                                match self.tools.execute(&ToolCall {
                                    tool: "bash".to_string(),
                                    parameters: params,
                                }).await {
                                    Ok(result) => {
                                        println!("    ✓ Agent responded");
                                        if !result.output.is_empty() {
                                            println!("    Response: {}", result.output.lines().next().unwrap_or(""));
                                        }
                                    }
                                    Err(e) => println!("    ✗ Error: {}", e),
                                }
                            } else {
                                println!("    ⚠ Agent not found: {}", agent_name);
                            }
                        }
                    }
                    "read_file" => {
                        let path = description.trim();
                        let mut params = HashMap::new();
                        params.insert("path".to_string(), path.to_string());

                        match self.tools.execute(&ToolCall {
                            tool: "read_file".to_string(),
                            parameters: params,
                        }).await {
                            Ok(result) => {
                                println!("    ✓ File read");
                                if !result.output.is_empty() {
                                    println!("    Preview: {}", result.output.lines().take(3).collect::<Vec<_>>().join("\n           "));
                                }
                            }
                            Err(e) => println!("    ✗ Error: {}", e),
                        }
                    }
                    "write_file" => {
                        println!("    📝 Would write file: {}", description.trim());
                    }
                    "list_files" => {
                        let mut params = HashMap::new();
                        params.insert("path".to_string(), description.trim().to_string());

                        match self.tools.execute(&ToolCall {
                            tool: "list_files".to_string(),
                            parameters: params,
                        }).await {
                            Ok(_result) => println!("    ✓ Listed files"),
                            Err(e) => println!("    ✗ Error: {}", e),
                        }
                    }
                    "web_search" => {
                        let query = description.trim();
                        let mut params = HashMap::new();
                        params.insert("query".to_string(), query.to_string());

                        match self.tools.execute(&ToolCall {
                            tool: "web_search".to_string(),
                            parameters: params,
                        }).await {
                            Ok(result) => {
                                println!("    ✓ Web search complete");
                                if !result.output.is_empty() {
                                    println!("    Results: {}", result.output.lines().take(3).collect::<Vec<_>>().join("\n           "));
                                }
                            }
                            Err(e) => println!("    ✗ Error: {}", e),
                        }
                    }
                    _ => {
                        println!("    ⚠ Unknown tool: {}", tool_name);
                    }
                }
            }

            // Small delay between steps
            sleep(Duration::from_millis(500)).await;
        }

        println!("\n  ✅ Plan execution complete");

        Ok(())
    }

    async fn reflect(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("\n🤔 Reflecting on this cycle...");

        // Simple reflection: just track what we did
        self.state.completed_tasks.push(format!(
            "Cycle {}: {}",
            self.state.cycle_count,
            self.state.last_decision
        ));

        // Keep only last 10 tasks in memory
        if self.state.completed_tasks.len() > 10 {
            self.state.completed_tasks.remove(0);
        }

        println!("  ✓ State updated, ready for next cycle");

        Ok(())
    }
}
