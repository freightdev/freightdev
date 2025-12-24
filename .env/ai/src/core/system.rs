// System awareness - knows about all agents, services, and commands

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentInfo {
    pub name: String,
    pub port: u16,
    pub status: AgentStatus,
    pub description: String,
    pub endpoints: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AgentStatus {
    Running,
    Built,
    NotBuilt,
}

#[derive(Debug, Clone)]
pub struct SystemMap {
    pub agents: HashMap<String, AgentInfo>,
    pub managers: HashMap<String, AgentInfo>,
    pub services: HashMap<String, AgentInfo>,
    pub scripts: HashMap<String, String>,
}

impl SystemMap {
    pub fn new() -> Self {
        let mut map = Self {
            agents: HashMap::new(),
            managers: HashMap::new(),
            services: HashMap::new(),
            scripts: HashMap::new(),
        };

        // AGENTS
        map.agents.insert("lead-scraper".to_string(), AgentInfo {
            name: "lead-scraper".to_string(),
            port: 9013,
            status: AgentStatus::Running,
            description: "Scrapes Reddit and HackerNews for leads".to_string(),
            endpoints: vec!["/health".to_string(), "/scrape".to_string(), "/leads".to_string()],
        });

        map.agents.insert("lead-analyzer".to_string(), AgentInfo {
            name: "lead-analyzer".to_string(),
            port: 9014,
            status: AgentStatus::Running,
            description: "Analyzes leads using LLM for fit scoring".to_string(),
            endpoints: vec!["/health".to_string(), "/analyze".to_string()],
        });

        map.agents.insert("data-collector".to_string(), AgentInfo {
            name: "data-collector".to_string(),
            port: 9006,
            status: AgentStatus::Built,
            description: "Scheduled data collection and automation".to_string(),
            endpoints: vec!["/health".to_string(), "/jobs/control".to_string()],
        });

        map.agents.insert("web-scraper".to_string(), AgentInfo {
            name: "web-scraper".to_string(),
            port: 9003,
            status: AgentStatus::Built,
            description: "General-purpose web scraping".to_string(),
            endpoints: vec!["/health".to_string(), "/scrape".to_string()],
        });

        map.agents.insert("web-searcher".to_string(), AgentInfo {
            name: "web-searcher".to_string(),
            port: 9004,
            status: AgentStatus::Built,
            description: "Search engine integration".to_string(),
            endpoints: vec!["/health".to_string(), "/search".to_string()],
        });

        map.agents.insert("code-assistant".to_string(), AgentInfo {
            name: "code-assistant".to_string(),
            port: 9005,
            status: AgentStatus::Built,
            description: "Code generation and assistance".to_string(),
            endpoints: vec!["/health".to_string(), "/generate".to_string()],
        });

        // MANAGERS
        map.managers.insert("lead-manager".to_string(), AgentInfo {
            name: "lead-manager".to_string(),
            port: 9015,
            status: AgentStatus::Running,
            description: "Orchestrates lead generation pipeline".to_string(),
            endpoints: vec!["/health".to_string(), "/scrape-and-analyze".to_string(), "/daily-digest".to_string()],
        });

        map.managers.insert("database-manager".to_string(), AgentInfo {
            name: "database-manager".to_string(),
            port: 9012,
            status: AgentStatus::Built,
            description: "SurrealDB abstraction layer".to_string(),
            endpoints: vec!["/health".to_string(), "/query".to_string()],
        });

        map.managers.insert("service-manager".to_string(), AgentInfo {
            name: "service-manager".to_string(),
            port: 9000,
            status: AgentStatus::Built,
            description: "Service lifecycle management".to_string(),
            endpoints: vec!["/health".to_string(), "/services".to_string()],
        });

        // EXTERNAL SERVICES
        map.services.insert("surrealdb".to_string(), AgentInfo {
            name: "surrealdb".to_string(),
            port: 8000,
            status: AgentStatus::Running,
            description: "Primary database".to_string(),
            endpoints: vec!["/".to_string()],
        });

        map.services.insert("llama.cpp".to_string(), AgentInfo {
            name: "llama.cpp".to_string(),
            port: 11435,
            status: AgentStatus::Running,
            description: "LLM inference engine".to_string(),
            endpoints: vec!["/health".to_string(), "/completion".to_string()],
        });

        // SCRIPTS
        map.scripts.insert("start-lead-system".to_string(),
            "./bin/lead-system/start-lead-system.sh".to_string());
        map.scripts.insert("stop-lead-system".to_string(),
            "./bin/lead-system/stop-lead-system.sh".to_string());
        map.scripts.insert("status-lead-system".to_string(),
            "./bin/lead-system/status-lead-system.sh".to_string());
        map.scripts.insert("scrape-leads".to_string(),
            "./bin/lead-system/scrape-leads.sh".to_string());
        map.scripts.insert("daily-digest".to_string(),
            "./bin/lead-system/daily-digest.sh".to_string());
        map.scripts.insert("quick-test".to_string(),
            "./bin/lead-system/quick-test.sh".to_string());
        map.scripts.insert("system-status".to_string(),
            "./bin/core/system-status.sh".to_string());
        map.scripts.insert("build-all".to_string(),
            "./bin/core/build-all.sh".to_string());

        map
    }

    pub fn describe_all(&self) -> String {
        let mut desc = String::from("AVAILABLE SYSTEM RESOURCES:\n\n");

        desc.push_str("AGENTS:\n");
        for (name, info) in &self.agents {
            desc.push_str(&format!("- {} (port {}): {} [{}]\n",
                name, info.port, info.description,
                match info.status {
                    AgentStatus::Running => "RUNNING",
                    AgentStatus::Built => "BUILT",
                    AgentStatus::NotBuilt => "NOT BUILT",
                }
            ));
            desc.push_str(&format!("  Endpoints: {}\n", info.endpoints.join(", ")));
        }

        desc.push_str("\nMANAGERS:\n");
        for (name, info) in &self.managers {
            desc.push_str(&format!("- {} (port {}): {} [{}]\n",
                name, info.port, info.description,
                match info.status {
                    AgentStatus::Running => "RUNNING",
                    AgentStatus::Built => "BUILT",
                    AgentStatus::NotBuilt => "NOT BUILT",
                }
            ));
            desc.push_str(&format!("  Endpoints: {}\n", info.endpoints.join(", ")));
        }

        desc.push_str("\nSERVICES:\n");
        for (name, info) in &self.services {
            desc.push_str(&format!("- {} (port {}): {}\n", name, info.port, info.description));
        }

        desc.push_str("\nSCRIPTS:\n");
        for (name, path) in &self.scripts {
            desc.push_str(&format!("- {}: {}\n", name, path));
        }

        desc
    }

    pub fn get_agent(&self, name: &str) -> Option<&AgentInfo> {
        self.agents.get(name)
            .or_else(|| self.managers.get(name))
            .or_else(|| self.services.get(name))
    }
}
