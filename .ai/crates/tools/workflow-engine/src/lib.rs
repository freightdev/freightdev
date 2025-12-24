// Generic Workflow Engine
// Handles ANY workflow: paperwork, dispatching, trading, etc.
// Pure Rust, runs on Ollama nodes, no API required

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use thiserror::Error;
use tokio::sync::RwLock;
use tracing::{error, info, warn};

// ============================================================================
// Core Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowDefinition {
    pub id: String,
    pub name: String,
    pub description: String,
    pub steps: Vec<WorkflowStep>,
    pub timeout_seconds: Option<u64>,
    pub retry_policy: RetryPolicy,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowStep {
    pub id: String,
    pub name: String,
    pub step_type: StepType,
    pub timeout_seconds: Option<u64>,
    pub required: bool,
    pub on_failure: FailureAction,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum StepType {
    LLMTask { prompt_template: String, model: String },
    DataFetch { source: String, query: String },
    DataTransform { operation: String },
    Decision { condition: String, if_true: String, if_false: String },
    HttpRequest { url: String, method: String },
    FileOperation { operation: String, path: String },
    Custom { handler: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FailureAction {
    Retry,
    Skip,
    Abort,
    TriggerHuman, // Signal for coordinator assistance
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetryPolicy {
    pub max_attempts: u32,
    pub backoff_seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowInstance {
    pub id: String,
    pub workflow_id: String,
    pub status: WorkflowStatus,
    pub current_step: usize,
    pub started_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub context: HashMap<String, serde_json::Value>,
    pub step_results: Vec<StepResult>,
    pub error: Option<String>,
    pub human_triggered: bool, // Signal sent to coordinator
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WorkflowStatus {
    Pending,
    Running,
    Waiting,    // Waiting for human input
    Completed,
    Failed,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StepResult {
    pub step_id: String,
    pub status: String,
    pub output: Option<serde_json::Value>,
    pub error: Option<String>,
    pub duration_ms: u64,
    pub attempts: u32,
}

// ============================================================================
// Errors
// ============================================================================

#[derive(Debug, Error)]
pub enum WorkflowError {
    #[error("Step failed: {0}")]
    StepFailed(String),

    #[error("Workflow timeout")]
    Timeout,

    #[error("Workflow cancelled")]
    Cancelled,

    #[error("Invalid step type")]
    InvalidStepType,

    #[error("Human intervention required")]
    HumanRequired,
}

// ============================================================================
// Step Executor Trait
// ============================================================================

#[async_trait]
pub trait StepExecutor: Send + Sync {
    async fn execute(
        &self,
        step: &WorkflowStep,
        context: &HashMap<String, serde_json::Value>,
    ) -> Result<serde_json::Value, WorkflowError>;
}

// ============================================================================
// Signal System (for coordinator assistance)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowSignal {
    pub instance_id: String,
    pub signal_type: SignalType,
    pub reason: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SignalType {
    TaskTakingTooLong,
    StepFailed,
    WorkflowStuck,
    NeedHumanDecision,
}

// ============================================================================
// Workflow Engine
// ============================================================================

pub struct WorkflowEngine {
    workflows: Arc<RwLock<HashMap<String, WorkflowDefinition>>>,
    instances: Arc<RwLock<HashMap<String, WorkflowInstance>>>,
    executors: Arc<RwLock<HashMap<String, Arc<dyn StepExecutor>>>>,
    signals: Arc<RwLock<Vec<WorkflowSignal>>>,
}

impl WorkflowEngine {
    pub fn new() -> Self {
        Self {
            workflows: Arc::new(RwLock::new(HashMap::new())),
            instances: Arc::new(RwLock::new(HashMap::new())),
            executors: Arc::new(RwLock::new(HashMap::new())),
            signals: Arc::new(RwLock::new(Vec::new())),
        }
    }

    pub async fn register_workflow(&self, workflow: WorkflowDefinition) {
        let mut workflows = self.workflows.write().await;
        workflows.insert(workflow.id.clone(), workflow);
    }

    pub async fn register_executor(&self, name: String, executor: Arc<dyn StepExecutor>) {
        let mut executors = self.executors.write().await;
        executors.insert(name, executor);
    }

    pub async fn start_workflow(
        &self,
        workflow_id: &str,
        initial_context: HashMap<String, serde_json::Value>,
    ) -> Result<String, WorkflowError> {
        let workflows = self.workflows.read().await;
        let workflow = workflows
            .get(workflow_id)
            .ok_or_else(|| WorkflowError::StepFailed("Workflow not found".to_string()))?
            .clone();
        drop(workflows);

        let instance = WorkflowInstance {
            id: uuid::Uuid::new_v4().to_string(),
            workflow_id: workflow_id.to_string(),
            status: WorkflowStatus::Running,
            current_step: 0,
            started_at: Utc::now(),
            updated_at: Utc::now(),
            completed_at: None,
            context: initial_context,
            step_results: Vec::new(),
            error: None,
            human_triggered: false,
        };

        let instance_id = instance.id.clone();

        let mut instances = self.instances.write().await;
        instances.insert(instance_id.clone(), instance);

        info!("Started workflow instance: {}", instance_id);

        Ok(instance_id)
    }

    pub async fn execute_step(
        &self,
        instance_id: &str,
        step_index: usize,
    ) -> Result<(), WorkflowError> {
        let mut instances = self.instances.write().await;
        let instance = instances
            .get_mut(instance_id)
            .ok_or_else(|| WorkflowError::StepFailed("Instance not found".to_string()))?;

        let workflows = self.workflows.read().await;
        let workflow = workflows
            .get(&instance.workflow_id)
            .ok_or_else(|| WorkflowError::StepFailed("Workflow not found".to_string()))?;

        if step_index >= workflow.steps.len() {
            instance.status = WorkflowStatus::Completed;
            instance.completed_at = Some(Utc::now());
            return Ok(());
        }

        let step = &workflow.steps[step_index];
        info!("Executing step: {} ({})", step.name, step.id);

        let start = std::time::Instant::now();
        let mut attempts = 0;
        let max_attempts = workflow.retry_policy.max_attempts;

        loop {
            attempts += 1;

            // Check for timeout
            if let Some(timeout_secs) = step.timeout_seconds {
                if start.elapsed().as_secs() > timeout_secs {
                    self.trigger_signal(
                        instance_id,
                        SignalType::TaskTakingTooLong,
                        format!("Step {} exceeded timeout", step.name),
                    )
                    .await;
                    return Err(WorkflowError::Timeout);
                }
            }

            // Execute step (placeholder - would use registered executors)
            let result = self.execute_step_internal(step, &instance.context).await;

            match result {
                Ok(output) => {
                    instance.step_results.push(StepResult {
                        step_id: step.id.clone(),
                        status: "completed".to_string(),
                        output: Some(output.clone()),
                        error: None,
                        duration_ms: start.elapsed().as_millis() as u64,
                        attempts,
                    });

                    // Update context with output
                    instance
                        .context
                        .insert(format!("step_{}_output", step.id), output);

                    instance.current_step = step_index + 1;
                    instance.updated_at = Utc::now();

                    return Ok(());
                }
                Err(e) => {
                    warn!("Step {} failed (attempt {}): {:?}", step.name, attempts, e);

                    if attempts >= max_attempts {
                        match step.on_failure {
                            FailureAction::Retry => {
                                // Already retried max times
                                self.trigger_signal(
                                    instance_id,
                                    SignalType::StepFailed,
                                    format!("Step {} failed after {} attempts", step.name, attempts),
                                )
                                .await;
                                return Err(e);
                            }
                            FailureAction::Skip => {
                                info!("Skipping failed step: {}", step.name);
                                instance.current_step = step_index + 1;
                                return Ok(());
                            }
                            FailureAction::Abort => {
                                instance.status = WorkflowStatus::Failed;
                                return Err(e);
                            }
                            FailureAction::TriggerHuman => {
                                instance.status = WorkflowStatus::Waiting;
                                instance.human_triggered = true;
                                self.trigger_signal(
                                    instance_id,
                                    SignalType::NeedHumanDecision,
                                    format!("Step {} needs human intervention", step.name),
                                )
                                .await;
                                return Err(WorkflowError::HumanRequired);
                            }
                        }
                    }

                    // Retry with backoff
                    tokio::time::sleep(Duration::from_secs(
                        workflow.retry_policy.backoff_seconds * attempts as u64,
                    ))
                    .await;
                }
            }
        }
    }

    async fn execute_step_internal(
        &self,
        step: &WorkflowStep,
        context: &HashMap<String, serde_json::Value>,
    ) -> Result<serde_json::Value, WorkflowError> {
        // Placeholder - would use registered executors
        match &step.step_type {
            StepType::LLMTask { prompt_template, model } => {
                // Would call llama.cpp here
                Ok(serde_json::json!({
                    "result": "LLM task completed",
                    "model": model
                }))
            }
            StepType::DataFetch { source, query } => {
                Ok(serde_json::json!({
                    "data": "fetched data"
                }))
            }
            _ => Ok(serde_json::json!({})),
        }
    }

    async fn trigger_signal(&self, instance_id: &str, signal_type: SignalType, reason: String) {
        let signal = WorkflowSignal {
            instance_id: instance_id.to_string(),
            signal_type,
            reason: reason.clone(),
            timestamp: Utc::now(),
        };

        let mut signals = self.signals.write().await;
        signals.push(signal);

        warn!("SIGNAL TRIGGERED: {} - {}", instance_id, reason);
    }

    pub async fn get_signals(&self) -> Vec<WorkflowSignal> {
        let signals = self.signals.read().await;
        signals.clone()
    }

    pub async fn get_instance(&self, instance_id: &str) -> Option<WorkflowInstance> {
        let instances = self.instances.read().await;
        instances.get(instance_id).cloned()
    }
}

impl Default for WorkflowEngine {
    fn default() -> Self {
        Self::new()
    }
}
