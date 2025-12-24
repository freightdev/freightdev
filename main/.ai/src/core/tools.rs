// Tool system for autonomous agent
// Provides: bash, file operations, git, search

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use std::process::Command;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ToolError {
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
    #[error("File error: {0}")]
    FileError(String),
    #[error("Permission denied: {0}")]
    PermissionDenied(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub tool: String,
    pub parameters: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    pub success: bool,
    pub output: String,
    pub error: Option<String>,
}

#[async_trait]
pub trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError>;
}

// ============================================================================
// Bash Tool
// ============================================================================

pub struct BashTool;

#[async_trait]
impl Tool for BashTool {
    fn name(&self) -> &str {
        "bash"
    }

    fn description(&self) -> &str {
        "Execute bash commands. Use for: system operations, running scripts, checking status."
    }

    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError> {
        let command = params.get("command")
            .ok_or_else(|| ToolError::ExecutionFailed("Missing 'command' parameter".to_string()))?;

        // Safety check - don't allow destructive commands without confirmation
        let dangerous_patterns = ["rm -rf /", "mkfs", "dd if=", "> /dev/sda"];
        for pattern in dangerous_patterns {
            if command.contains(pattern) {
                return Err(ToolError::PermissionDenied(
                    format!("Dangerous command blocked: {}", pattern)
                ));
            }
        }

        println!("🔧 Executing: {}", command);

        let output = Command::new("bash")
            .arg("-c")
            .arg(command)
            .current_dir("/home/admin/WORKSPACE/projects/ACTIVE/codriver")
            .output()
            .map_err(|e| ToolError::ExecutionFailed(e.to_string()))?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        Ok(ToolResult {
            success: output.status.success(),
            output: stdout,
            error: if stderr.is_empty() { None } else { Some(stderr) },
        })
    }
}

// ============================================================================
// File Read Tool
// ============================================================================

pub struct FileReadTool;

#[async_trait]
impl Tool for FileReadTool {
    fn name(&self) -> &str {
        "read_file"
    }

    fn description(&self) -> &str {
        "Read contents of a file. Use for: viewing code, config files, documentation."
    }

    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError> {
        let path = params.get("path")
            .ok_or_else(|| ToolError::ExecutionFailed("Missing 'path' parameter".to_string()))?;

        let full_path = Path::new("/home/admin/WORKSPACE/projects/ACTIVE/codriver").join(path);

        println!("📖 Reading: {}", path);

        let content = tokio::fs::read_to_string(&full_path).await
            .map_err(|e| ToolError::FileError(e.to_string()))?;

        Ok(ToolResult {
            success: true,
            output: content,
            error: None,
        })
    }
}

// ============================================================================
// File Write Tool
// ============================================================================

pub struct FileWriteTool;

#[async_trait]
impl Tool for FileWriteTool {
    fn name(&self) -> &str {
        "write_file"
    }

    fn description(&self) -> &str {
        "Write content to a file. Use for: creating new files, updating configs."
    }

    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError> {
        let path = params.get("path")
            .ok_or_else(|| ToolError::ExecutionFailed("Missing 'path' parameter".to_string()))?;
        let content = params.get("content")
            .ok_or_else(|| ToolError::ExecutionFailed("Missing 'content' parameter".to_string()))?;

        let full_path = Path::new("/home/admin/WORKSPACE/projects/ACTIVE/codriver").join(path);

        println!("📝 Writing: {}", path);

        tokio::fs::write(&full_path, content).await
            .map_err(|e| ToolError::FileError(e.to_string()))?;

        Ok(ToolResult {
            success: true,
            output: format!("File written: {}", path),
            error: None,
        })
    }
}

// ============================================================================
// File List Tool
// ============================================================================

pub struct FileListTool;

#[async_trait]
impl Tool for FileListTool {
    fn name(&self) -> &str {
        "list_files"
    }

    fn description(&self) -> &str {
        "List files in a directory. Use for: exploring codebase, finding files."
    }

    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError> {
        let path = params.get("path").map(|s| s.as_str()).unwrap_or(".");

        let output = Command::new("ls")
            .arg("-la")
            .arg(path)
            .current_dir("/home/admin/WORKSPACE/projects/ACTIVE/codriver")
            .output()
            .map_err(|e| ToolError::ExecutionFailed(e.to_string()))?;

        Ok(ToolResult {
            success: output.status.success(),
            output: String::from_utf8_lossy(&output.stdout).to_string(),
            error: None,
        })
    }
}

// ============================================================================
// Web Search Tool (calls web-searcher agent)
// ============================================================================

pub struct WebSearchTool {
    client: reqwest::Client,
}

impl WebSearchTool {
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::new(),
        }
    }
}

#[async_trait]
impl Tool for WebSearchTool {
    fn name(&self) -> &str {
        "web_search"
    }

    fn description(&self) -> &str {
        "Search the web using web-searcher agent. Use for: finding best practices, tutorials, examples."
    }

    async fn execute(&self, params: HashMap<String, String>) -> Result<ToolResult, ToolError> {
        let query = params.get("query")
            .ok_or_else(|| ToolError::ExecutionFailed("Missing 'query' parameter".to_string()))?;

        println!("🔍 Calling web-searcher agent for: {}", query);

        // First check if web-searcher is running
        let health_check = self.client
            .get("http://localhost:9004/health")
            .send()
            .await;

        if health_check.is_err() {
            return Ok(ToolResult {
                success: false,
                output: String::new(),
                error: Some("web-searcher agent not running. Start it first or use bash to search manually.".to_string()),
            });
        }

        // Call web-searcher agent
        let search_request = serde_json::json!({
            "query": query,
            "max_results": 5
        });

        match self.client
            .post("http://localhost:9004/search")
            .json(&search_request)
            .send()
            .await
        {
            Ok(response) => {
                let result: serde_json::Value = response.json().await
                    .map_err(|e| ToolError::ExecutionFailed(e.to_string()))?;

                Ok(ToolResult {
                    success: true,
                    output: format!("Search results:\n{}", serde_json::to_string_pretty(&result).unwrap()),
                    error: None,
                })
            }
            Err(e) => {
                Ok(ToolResult {
                    success: false,
                    output: String::new(),
                    error: Some(format!("web-searcher call failed: {}", e)),
                })
            }
        }
    }
}

// ============================================================================
// Tool Registry
// ============================================================================

pub struct ToolRegistry {
    tools: HashMap<String, Box<dyn Tool>>,
}

impl ToolRegistry {
    pub fn new() -> Self {
        let mut tools: HashMap<String, Box<dyn Tool>> = HashMap::new();

        tools.insert("bash".to_string(), Box::new(BashTool));
        tools.insert("read_file".to_string(), Box::new(FileReadTool));
        tools.insert("write_file".to_string(), Box::new(FileWriteTool));
        tools.insert("list_files".to_string(), Box::new(FileListTool));
        tools.insert("web_search".to_string(), Box::new(WebSearchTool::new()));

        Self { tools }
    }

    pub fn get(&self, name: &str) -> Option<&Box<dyn Tool>> {
        self.tools.get(name)
    }

    pub fn list(&self) -> Vec<String> {
        self.tools.keys().cloned().collect()
    }

    pub fn describe_all(&self) -> String {
        let mut desc = String::from("Available tools:\n\n");
        for (name, tool) in &self.tools {
            desc.push_str(&format!("- {}: {}\n", name, tool.description()));
        }
        desc
    }

    pub async fn execute(&self, call: &ToolCall) -> Result<ToolResult, ToolError> {
        let tool = self.get(&call.tool)
            .ok_or_else(|| ToolError::ExecutionFailed(format!("Unknown tool: {}", call.tool)))?;

        tool.execute(call.parameters.clone()).await
    }
}
