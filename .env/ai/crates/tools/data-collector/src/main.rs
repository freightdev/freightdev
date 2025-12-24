// Data Collector & Scheduler Agent
// Handles scheduled data collection, API polling, and automation

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::{error, info, warn};
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CollectionJob {
    id: String,
    name: String,
    job_type: JobType,
    schedule: String, // Cron expression
    enabled: bool,
    last_run: Option<DateTime<Utc>>,
    next_run: Option<DateTime<Utc>>,
    run_count: u64,
    success_count: u64,
    failure_count: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum JobType {
    HttpGet { url: String, headers: HashMap<String, String> },
    HttpPost { url: String, body: String, headers: HashMap<String, String> },
    DatabaseQuery { query: String },
    FileWatch { path: String, pattern: String },
    Custom { handler: String, params: HashMap<String, String> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct JobResult {
    job_id: String,
    execution_id: String,
    started_at: DateTime<Utc>,
    completed_at: Option<DateTime<Utc>>,
    status: ExecutionStatus,
    data: Option<serde_json::Value>,
    error: Option<String>,
    duration_ms: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum ExecutionStatus {
    Running,
    Success,
    Failed,
    Timeout,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CreateJobRequest {
    name: String,
    job_type: JobType,
    schedule: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct JobControlRequest {
    job_id: String,
    action: JobAction,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum JobAction {
    Enable,
    Disable,
    RunNow,
    Delete,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    jobs: Arc<RwLock<HashMap<String, CollectionJob>>>,
    results: Arc<RwLock<Vec<JobResult>>>,
    scheduler: Arc<JobScheduler>,
}

// ============================================================================
// Job Execution
// ============================================================================

async fn execute_job(job: &CollectionJob) -> Result<serde_json::Value, String> {
    info!("Executing job: {} ({})", job.name, job.id);

    match &job.job_type {
        JobType::HttpGet { url, headers } => {
            let client = reqwest::Client::new();
            let mut request = client.get(url);

            for (key, value) in headers {
                request = request.header(key, value);
            }

            let response = request
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;

            let status = response.status();
            let body = response
                .text()
                .await
                .map_err(|e| format!("Failed to read response: {}", e))?;

            Ok(serde_json::json!({
                "status": status.as_u16(),
                "body": body
            }))
        }

        JobType::HttpPost { url, body, headers } => {
            let client = reqwest::Client::new();
            let mut request = client.post(url).body(body.clone());

            for (key, value) in headers {
                request = request.header(key, value);
            }

            let response = request
                .send()
                .await
                .map_err(|e| format!("HTTP request failed: {}", e))?;

            let status = response.status();
            let response_body = response
                .text()
                .await
                .map_err(|e| format!("Failed to read response: {}", e))?;

            Ok(serde_json::json!({
                "status": status.as_u16(),
                "body": response_body
            }))
        }

        JobType::DatabaseQuery { query } => {
            // Placeholder - would connect to SurrealDB
            Ok(serde_json::json!({
                "query": query,
                "result": "executed"
            }))
        }

        JobType::FileWatch { path, pattern } => {
            // Placeholder - would implement file watching
            Ok(serde_json::json!({
                "path": path,
                "pattern": pattern,
                "files": []
            }))
        }

        JobType::Custom { handler, params } => {
            // Placeholder - would dispatch to custom handlers
            Ok(serde_json::json!({
                "handler": handler,
                "params": params
            }))
        }
    }
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Data Collector: ONLINE")
}

async fn list_jobs(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let jobs = state.jobs.read().await;
    let job_list: Vec<CollectionJob> = jobs.values().cloned().collect();

    Json(serde_json::json!({
        "success": true,
        "jobs": job_list,
        "count": job_list.len()
    }))
}

async fn create_job(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreateJobRequest>,
) -> impl IntoResponse {
    let job = CollectionJob {
        id: Uuid::new_v4().to_string(),
        name: req.name.clone(),
        job_type: req.job_type,
        schedule: req.schedule.clone(),
        enabled: true,
        last_run: None,
        next_run: None,
        run_count: 0,
        success_count: 0,
        failure_count: 0,
    };

    let job_id = job.id.clone();

    // Store job
    let mut jobs = state.jobs.write().await;
    jobs.insert(job_id.clone(), job.clone());

    info!("Created job: {} ({})", req.name, job_id);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "job": job
        })),
    )
}

async fn control_job(
    State(state): State<Arc<AppState>>,
    Json(req): Json<JobControlRequest>,
) -> impl IntoResponse {
    let mut jobs = state.jobs.write().await;

    let job = match jobs.get_mut(&req.job_id) {
        Some(j) => j,
        None => {
            return (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({
                    "error": "Job not found"
                })),
            );
        }
    };

    match req.action {
        JobAction::Enable => {
            job.enabled = true;
            info!("Enabled job: {}", req.job_id);
        }
        JobAction::Disable => {
            job.enabled = false;
            info!("Disabled job: {}", req.job_id);
        }
        JobAction::RunNow => {
            if job.enabled {
                let job_clone = job.clone();
                drop(jobs); // Release lock before async work

                let start = std::time::Instant::now();
                let started_at = Utc::now();

                let result = match execute_job(&job_clone).await {
                    Ok(data) => JobResult {
                        job_id: job_clone.id.clone(),
                        execution_id: Uuid::new_v4().to_string(),
                        started_at,
                        completed_at: Some(Utc::now()),
                        status: ExecutionStatus::Success,
                        data: Some(data),
                        error: None,
                        duration_ms: Some(start.elapsed().as_millis() as u64),
                    },
                    Err(e) => JobResult {
                        job_id: job_clone.id.clone(),
                        execution_id: Uuid::new_v4().to_string(),
                        started_at,
                        completed_at: Some(Utc::now()),
                        status: ExecutionStatus::Failed,
                        data: None,
                        error: Some(e),
                        duration_ms: Some(start.elapsed().as_millis() as u64),
                    },
                };

                // Store result
                let mut results = state.results.write().await;
                results.push(result.clone());

                // Update job stats
                let mut jobs = state.jobs.write().await;
                if let Some(job) = jobs.get_mut(&req.job_id) {
                    job.run_count += 1;
                    job.last_run = Some(started_at);
                    if matches!(result.status, ExecutionStatus::Success) {
                        job.success_count += 1;
                    } else {
                        job.failure_count += 1;
                    }
                }

                return (
                    StatusCode::OK,
                    Json(serde_json::json!({
                        "success": true,
                        "result": result
                    })),
                );
            } else {
                return (
                    StatusCode::BAD_REQUEST,
                    Json(serde_json::json!({
                        "error": "Job is disabled"
                    })),
                );
            }
        }
        JobAction::Delete => {
            jobs.remove(&req.job_id);
            info!("Deleted job: {}", req.job_id);
        }
    }

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true
        })),
    )
}

async fn get_results(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let results = state.results.read().await;
    let recent_results: Vec<JobResult> = results.iter().rev().take(100).cloned().collect();

    Json(serde_json::json!({
        "success": true,
        "results": recent_results,
        "count": recent_results.len()
    }))
}

#[derive(Deserialize)]
struct JobResultsQuery {
    job_id: String,
}

async fn get_job_results(
    State(state): State<Arc<AppState>>,
    Json(query): Json<JobResultsQuery>,
) -> impl IntoResponse {
    let results = state.results.read().await;
    let job_results: Vec<JobResult> = results
        .iter()
        .filter(|r| r.job_id == query.job_id)
        .cloned()
        .collect();

    Json(serde_json::json!({
        "success": true,
        "results": job_results,
        "count": job_results.len()
    }))
}

async fn get_stats(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let jobs = state.jobs.read().await;
    let results = state.results.read().await;

    let total_jobs = jobs.len();
    let enabled_jobs = jobs.values().filter(|j| j.enabled).count();
    let disabled_jobs = jobs.values().filter(|j| !j.enabled).count();

    let total_executions = results.len();
    let successful = results.iter().filter(|r| matches!(r.status, ExecutionStatus::Success)).count();
    let failed = results.iter().filter(|r| matches!(r.status, ExecutionStatus::Failed)).count();

    let total_run_count: u64 = jobs.values().map(|j| j.run_count).sum();
    let total_success_count: u64 = jobs.values().map(|j| j.success_count).sum();
    let total_failure_count: u64 = jobs.values().map(|j| j.failure_count).sum();

    Json(serde_json::json!({
        "success": true,
        "stats": {
            "jobs": {
                "total": total_jobs,
                "enabled": enabled_jobs,
                "disabled": disabled_jobs
            },
            "executions": {
                "total": total_executions,
                "successful": successful,
                "failed": failed
            },
            "lifetime": {
                "total_runs": total_run_count,
                "total_successes": total_success_count,
                "total_failures": total_failure_count,
                "success_rate": if total_run_count > 0 {
                    (total_success_count as f64 / total_run_count as f64) * 100.0
                } else {
                    0.0
                }
            }
        }
    }))
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Data Collector & Scheduler");

    // Create scheduler
    let scheduler = JobScheduler::new().await?;
    scheduler.start().await?;

    let state = Arc::new(AppState {
        jobs: Arc::new(RwLock::new(HashMap::new())),
        results: Arc::new(RwLock::new(Vec::new())),
        scheduler: Arc::new(scheduler),
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/jobs", get(list_jobs))
        .route("/jobs/create", post(create_job))
        .route("/jobs/control", post(control_job))
        .route("/results", get(get_results))
        .route("/results/job", post(get_job_results))
        .route("/stats", get(get_stats))
        .with_state(state);

    let addr = "127.0.0.1:9006";
    info!("Data Collector listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
