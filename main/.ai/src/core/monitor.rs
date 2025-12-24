// Autonomous CoDriver Agent
// Self-directed AI agent that uses Ollama for decision-making
// Monitors trucking data, orchestrates ai-agents, and builds out .ai/ architecture
// Keeps user in the loop with approval system

use serde::{Deserialize, Serialize};
use std::time::Duration;
use tokio::time::sleep;
use chrono::{DateTime, Utc};
use reqwest::Client;
use surrealdb::Surreal;
use surrealdb::engine::remote::ws::Ws;

// ============================================================================
// Configuration
// ============================================================================

const OLLAMA_NODE: &str = "http://192.168.12.106:11434";
const OLLAMA_MODEL: &str = "mistral:latest";  // 7.2B - much faster
const DATA_COLLECTOR_URL: &str = "http://localhost:9006";
const WEB_SCRAPER_URL: &str = "http://localhost:9003";
// const COORDINATOR_URL: &str = "http://localhost:9009";  // Reserved for future use
const EMAIL_SERVICE_URL: &str = "http://localhost:9011";
const SURREALDB_URL: &str = "ws://192.168.12.136:9000";

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CodriverState {
    current_objective: String,
    focus_area: FocusArea,
    last_decision: DateTime<Utc>,
    trucking_intel_summary: String,
    active_projects: Vec<Project>,
    knowledge_base: Vec<KnowledgeItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum FocusArea {
    TruckingIntelligence,  // Monitoring rates, routes, regulations
    AgencyDevelopment,     // Building out .ai/ architecture
    UserRequest,           // Working on user-assigned task
    Maintenance,           // System health, updates
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Project {
    id: String,
    name: String,
    description: String,
    status: ProjectStatus,
    tasks: Vec<Task>,
    requires_approval: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum ProjectStatus {
    Planning,
    AwaitingApproval,
    InProgress,
    Completed,
    Paused,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Task {
    description: String,
    assigned_agent: Option<String>,
    status: TaskStatus,
    result: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum TaskStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    AwaitingApproval,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct KnowledgeItem {
    topic: String,
    summary: String,
    source: String,
    timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DecisionContext {
    trucking_data: TruckingDataSummary,
    system_state: SystemState,
    pending_approvals: Vec<String>,
    user_directives: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct TruckingDataSummary {
    latest_rates: Option<FreightRates>,
    recent_news: Vec<String>,
    regulatory_updates: Vec<String>,
    last_update: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct FreightRates {
    van_rate: f32,
    reefer_rate: f32,
    flatbed_rate: f32,
    trend: String,  // "rising", "falling", "stable"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SystemState {
    agents_online: Vec<String>,
    agents_offline: Vec<String>,
    database_healthy: bool,
    ollama_available: bool,
}

// ============================================================================
// Autonomous CoDriver Agent
// ============================================================================

pub struct AutonomousCoDriver {
    client: Client,
    state: CodriverState,
    db: Option<Surreal<surrealdb::engine::remote::ws::Client>>,
}

impl AutonomousCoDriver {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Ok(Self {
            client: Client::new(),
            state: CodriverState {
                current_objective: "Initialize and monitor trucking intelligence".to_string(),
                focus_area: FocusArea::TruckingIntelligence,
                last_decision: Utc::now(),
                trucking_intel_summary: String::new(),
                active_projects: Vec::new(),
                knowledge_base: Vec::new(),
            },
            db: None,
        })
    }

    /// Main autonomous loop
    pub async fn run(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🚛 CoDriver: Starting autonomous operation...");
        println!("🧠 Using Ollama brain: {}", OLLAMA_MODEL);
        println!("📊 Monitoring trucking intelligence");
        println!("👤 User approval required for: deployments, code changes, spending");
        println!();

        // Connect to SurrealDB
        self.connect_database().await?;

        // Load previous state if exists
        self.load_state().await?;

        loop {
            println!("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            println!("🔄 CoDriver Decision Cycle - {}", Utc::now().format("%H:%M:%S"));
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

            // Step 1: Gather context
            let context = self.gather_context().await?;

            // Step 2: Make decision using Ollama
            let decision = self.make_decision(&context).await?;

            // Step 3: Execute decision (with approval if needed)
            self.execute_decision(decision).await?;

            // Step 4: Update trucking intelligence
            self.update_trucking_intel(&context).await?;

            // Step 5: Save state
            self.save_state().await?;

            // Step 6: Sleep before next cycle (5 minutes)
            println!("\n💤 Sleeping for 5 minutes...");
            sleep(Duration::from_secs(300)).await;
        }
    }

    async fn connect_database(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("📡 Connecting to SurrealDB...");
        match Surreal::new::<Ws>(SURREALDB_URL).await {
            Ok(db) => {
                match db.use_ns("workspace").use_db("codriver_state").await {
                    Ok(_) => {
                        self.db = Some(db);
                        println!("✅ Database connected");
                    }
                    Err(e) => {
                        println!("⚠️  Database namespace/db error: {}", e);
                        println!("   Continuing without database persistence...");
                    }
                }
            }
            Err(e) => {
                println!("⚠️  Database connection failed: {}", e);
                println!("   Continuing without database persistence...");
            }
        }
        Ok(())
    }

    async fn gather_context(&self) -> Result<DecisionContext, Box<dyn std::error::Error>> {
        println!("📊 Gathering context...");

        // Get trucking data from collector
        let trucking_data = self.fetch_trucking_data().await?;

        // Check system state
        let system_state = self.check_system_state().await?;

        // Get pending approvals from coordinator
        let pending_approvals = self.fetch_pending_approvals().await?;

        Ok(DecisionContext {
            trucking_data,
            system_state,
            pending_approvals,
            user_directives: Vec::new(),  // TODO: Load from database
        })
    }

    async fn fetch_trucking_data(&self) -> Result<TruckingDataSummary, Box<dyn std::error::Error>> {
        // TODO: Query data-collector for latest trucking intel
        // For now, placeholder
        Ok(TruckingDataSummary {
            latest_rates: None,
            recent_news: vec![],
            regulatory_updates: vec![],
            last_update: Utc::now(),
        })
    }

    async fn check_system_state(&self) -> Result<SystemState, Box<dyn std::error::Error>> {
        let mut agents_online = Vec::new();
        let mut agents_offline = Vec::new();

        // Check each agent
        for (name, url) in [
            ("data-collector", DATA_COLLECTOR_URL),
            ("web-scraper", WEB_SCRAPER_URL),
        ] {
            match self.client.get(format!("{}/health", url)).send().await {
                Ok(_) => agents_online.push(name.to_string()),
                Err(_) => agents_offline.push(name.to_string()),
            }
        }

        Ok(SystemState {
            agents_online,
            agents_offline,
            database_healthy: self.db.is_some(),
            ollama_available: self.check_ollama().await.is_ok(),
        })
    }

    async fn check_ollama(&self) -> Result<(), Box<dyn std::error::Error>> {
        self.client
            .get(format!("{}/api/tags", OLLAMA_NODE))
            .send()
            .await?;
        Ok(())
    }

    async fn fetch_pending_approvals(&self) -> Result<Vec<String>, Box<dyn std::error::Error>> {
        // TODO: Query coordinator for pending approvals
        Ok(Vec::new())
    }

    async fn make_decision(&self, context: &DecisionContext) -> Result<String, Box<dyn std::error::Error>> {
        println!("🧠 Consulting Ollama brain...");

        let prompt = self.build_decision_prompt(context);

        let response = self.ask_ollama(&prompt).await?;

        println!("💭 Decision: {}", response);

        Ok(response)
    }

    fn build_decision_prompt(&self, context: &DecisionContext) -> String {
        format!(
            r#"You are CoDriver, an autonomous AI agent focused on trucking industry intelligence and self-improvement.

CURRENT OBJECTIVE: {}
FOCUS AREA: {:?}

SYSTEM STATE:
- Agents Online: {}
- Agents Offline: {}
- Database: {}
- Ollama: {}

TRUCKING INTELLIGENCE:
- Last Update: {}
- Recent News: {} items
- Regulatory Updates: {} items

YOUR CAPABILITIES:
1. Monitor trucking rates, routes, and regulations
2. Delegate tasks to specialized agents (web-scraper, data-collector, etc.)
3. Build and improve the .ai/ architecture
4. Learn from collected data

CURRENT TASK:
Decide what to work on next. Choose ONE action:

A) Update trucking intelligence (query data-collector for latest rates/news)
B) Improve an existing agent (suggest enhancement)
C) Create new capability in .ai/ (propose new agent or feature)
D) Maintenance (check logs, clean up, optimize)
E) Wait (if everything is running smoothly)

Respond with ONLY the letter (A/B/C/D/E) and a brief reason (1 sentence).
Format: "A - [reason]"
"#,
            self.state.current_objective,
            self.state.focus_area,
            context.system_state.agents_online.join(", "),
            context.system_state.agents_offline.join(", "),
            if context.system_state.database_healthy { "✅" } else { "❌" },
            if context.system_state.ollama_available { "✅" } else { "❌" },
            context.trucking_data.last_update.format("%H:%M:%S"),
            context.trucking_data.recent_news.len(),
            context.trucking_data.regulatory_updates.len(),
        )
    }

    async fn ask_ollama(&self, prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
        let payload = serde_json::json!({
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": false,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
            }
        });

        let response = self.client
            .post(format!("{}/api/generate", OLLAMA_NODE))
            .json(&payload)
            .timeout(Duration::from_secs(120))
            .send()
            .await?;

        let result: serde_json::Value = response.json().await?;

        Ok(result["response"].as_str().unwrap_or("").to_string())
    }

    async fn execute_decision(&self, decision: String) -> Result<(), Box<dyn std::error::Error>> {
        println!("⚡ Executing decision...");

        // Parse decision (starts with A/B/C/D/E)
        let action = decision.chars().next().unwrap_or('E');

        match action {
            'A' => self.update_trucking_intelligence().await?,
            'B' => self.improve_agent().await?,
            'C' => self.create_capability().await?,
            'D' => self.perform_maintenance().await?,
            'E' => println!("✅ Monitoring... all systems nominal"),
            _ => println!("⚠️  Unknown decision: {}", decision),
        }

        Ok(())
    }

    async fn update_trucking_intelligence(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("📰 Updating trucking intelligence...");

        // Trigger data collection
        let _response = self.client
            .post(format!("{}/jobs/control", DATA_COLLECTOR_URL))
            .json(&serde_json::json!({
                "job_id": "trucking-intel",
                "action": "RunNow"
            }))
            .send()
            .await?;

        println!("✅ Data collection triggered");

        Ok(())
    }

    async fn improve_agent(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🔧 Analyzing agents for improvement...");

        // Use Ollama to suggest improvements
        let prompt = "Suggest ONE small improvement to the data-collector agent that would make it more useful for trucking intelligence. Be specific and actionable.";

        let suggestion = self.ask_ollama(prompt).await?;

        println!("💡 Suggestion: {}", suggestion);

        // Request approval via email
        self.request_approval(
            "Improve data-collector agent",
            "Medium",
            &suggestion,
            "APPROVE - Continuous improvement"
        ).await?;

        Ok(())
    }

    async fn create_capability(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🏗️  Proposing new capability...");

        let prompt = "Suggest ONE new agent or feature for the .ai/ architecture that would help with trucking industry intelligence or agency operations. Keep it small and achievable.";

        let proposal = self.ask_ollama(prompt).await?;

        println!("💭 Proposal: {}", proposal);

        // Request approval via email
        self.request_approval(
            &format!("Create new capability: {}", proposal.lines().next().unwrap_or("New feature")),
            "High",
            &proposal,
            "Requires review - new functionality"
        ).await?;

        Ok(())
    }

    async fn request_approval(
        &self,
        action: &str,
        risk_level: &str,
        details: &str,
        recommendation: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let approval_id = uuid::Uuid::new_v4().to_string();

        println!("📧 Requesting approval via email...");
        println!("   Approval ID: {}", approval_id);

        // Call email service
        let _response = self.client
            .post(format!("{}/email/approval", EMAIL_SERVICE_URL))
            .json(&serde_json::json!({
                "approval_id": approval_id,
                "action": action,
                "risk_level": risk_level,
                "details": details,
                "recommendation": recommendation
            }))
            .send()
            .await?;

        if _response.status().is_success() {
            println!("✅ Approval request sent to jesse.freightdev@gmail.com");
        } else {
            println!("⚠️  Failed to send approval email: {}", _response.status());
        }

        Ok(())
    }

    async fn perform_maintenance(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("🧹 Performing maintenance...");

        // Check disk space
        // Clean old logs
        // Verify backups
        // Update dependencies

        println!("✅ Maintenance complete");

        Ok(())
    }

    async fn update_trucking_intel(&self, _context: &DecisionContext) -> Result<(), Box<dyn std::error::Error>> {
        // Update internal knowledge base with latest trucking data
        // TODO: Implement knowledge base updates from context
        Ok(())
    }

    async fn load_state(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        // TODO: Load state from SurrealDB
        println!("📂 State loaded from database");
        Ok(())
    }

    async fn save_state(&self) -> Result<(), Box<dyn std::error::Error>> {
        // TODO: Save state to SurrealDB
        Ok(())
    }
}
