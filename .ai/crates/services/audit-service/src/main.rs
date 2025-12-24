// Auditor Agent
// Continuously rotates through logs and records
// Audits designs, code changes, security, trading decisions

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, warn};
use walkdir::WalkDir;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AuditReport {
    timestamp: String,
    audit_type: String,
    target: String,
    findings: Vec<Finding>,
    severity: String,
    recommendations: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Finding {
    severity: String, // critical, high, medium, low, info
    category: String, // security, performance, quality, compliance
    description: String,
    location: Option<String>,
    recommendation: String,
}

#[derive(Debug, Clone)]
struct AuditTarget {
    path: PathBuf,
    audit_type: String,
    last_audited: Option<DateTime<Utc>>,
    priority: u8,
}

struct AppState {
    audit_targets: Arc<RwLock<Vec<AuditTarget>>>,
    recent_reports: Arc<RwLock<Vec<AuditReport>>>,
    audit_index: Arc<RwLock<usize>>,
}

// ============================================================================
// Audit Functions
// ============================================================================

fn audit_log_file(path: &PathBuf) -> Vec<Finding> {
    let mut findings = Vec::new();

    // Read log file
    if let Ok(content) = std::fs::read_to_string(path) {
        let lines: Vec<&str> = content.lines().collect();

        // Check for errors
        let error_count = lines.iter().filter(|l| l.contains("ERROR") || l.contains("error")).count();
        if error_count > 10 {
            findings.push(Finding {
                severity: "high".to_string(),
                category: "reliability".to_string(),
                description: format!("High error rate detected: {} errors", error_count),
                location: Some(path.display().to_string()),
                recommendation: "Investigate recurring errors and implement fixes".to_string(),
            });
        }

        // Check for security warnings
        let security_warnings = lines
            .iter()
            .filter(|l| l.contains("SECURITY") || l.contains("unauthorized"))
            .count();
        if security_warnings > 0 {
            findings.push(Finding {
                severity: "critical".to_string(),
                category: "security".to_string(),
                description: format!("Security warnings found: {}", security_warnings),
                location: Some(path.display().to_string()),
                recommendation: "Review security warnings immediately and take action".to_string(),
            });
        }

        // Check for performance issues
        if lines.iter().any(|l| l.contains("timeout") || l.contains("slow")) {
            findings.push(Finding {
                severity: "medium".to_string(),
                category: "performance".to_string(),
                description: "Performance issues detected in logs".to_string(),
                location: Some(path.display().to_string()),
                recommendation: "Profile and optimize slow operations".to_string(),
            });
        }
    }

    findings
}

fn audit_design_document(path: &PathBuf) -> Vec<Finding> {
    let mut findings = Vec::new();

    if let Ok(content) = std::fs::read_to_string(path) {
        // Check for incomplete sections
        if content.contains("TODO") || content.contains("TBD") {
            findings.push(Finding {
                severity: "low".to_string(),
                category: "completeness".to_string(),
                description: "Design document contains TODO/TBD sections".to_string(),
                location: Some(path.display().to_string()),
                recommendation: "Complete all TODO sections before implementation".to_string(),
            });
        }

        // Check for security considerations
        if !content.to_lowercase().contains("security") {
            findings.push(Finding {
                severity: "medium".to_string(),
                category: "security".to_string(),
                description: "Design lacks security considerations".to_string(),
                location: Some(path.display().to_string()),
                recommendation: "Add security section to design document".to_string(),
            });
        }

        // Check for testing strategy
        if !content.to_lowercase().contains("test") {
            findings.push(Finding {
                severity: "medium".to_string(),
                category: "quality".to_string(),
                description: "Design lacks testing strategy".to_string(),
                location: Some(path.display().to_string()),
                recommendation: "Define testing approach and coverage".to_string(),
            });
        }
    }

    findings
}

fn audit_code_file(path: &PathBuf) -> Vec<Finding> {
    let mut findings = Vec::new();

    if let Ok(content) = std::fs::read_to_string(path) {
        // Check for unsafe code (Rust)
        if content.contains("unsafe") {
            findings.push(Finding {
                severity: "high".to_string(),
                category: "security".to_string(),
                description: "Unsafe code block detected".to_string(),
                location: Some(path.display().to_string()),
                recommendation: "Review unsafe code and document why it's necessary".to_string(),
            });
        }

        // Check for hardcoded credentials
        let credential_patterns = ["password", "api_key", "secret", "token"];
        for pattern in &credential_patterns {
            if content.contains(&format!("\"{}\"", pattern)) {
                findings.push(Finding {
                    severity: "critical".to_string(),
                    category: "security".to_string(),
                    description: format!("Possible hardcoded credential: {}", pattern),
                    location: Some(path.display().to_string()),
                    recommendation: "Move credentials to environment variables".to_string(),
                });
            }
        }

        // Check for TODO comments
        let todo_count = content.matches("TODO").count() + content.matches("FIXME").count();
        if todo_count > 5 {
            findings.push(Finding {
                severity: "low".to_string(),
                category: "quality".to_string(),
                description: format!("{} TODO/FIXME comments found", todo_count),
                location: Some(path.display().to_string()),
                recommendation: "Address or track TODO items".to_string(),
            });
        }
    }

    findings
}

async fn perform_audit(target: &AuditTarget) -> AuditReport {
    info!("Auditing: {} ({})", target.path.display(), target.audit_type);

    let findings = match target.audit_type.as_str() {
        "log" => audit_log_file(&target.path),
        "design" => audit_design_document(&target.path),
        "code" => audit_code_file(&target.path),
        _ => vec![],
    };

    // Determine overall severity
    let severity = if findings.iter().any(|f| f.severity == "critical") {
        "critical"
    } else if findings.iter().any(|f| f.severity == "high") {
        "high"
    } else if findings.iter().any(|f| f.severity == "medium") {
        "medium"
    } else if findings.is_empty() {
        "clean"
    } else {
        "low"
    };

    // Generate recommendations
    let recommendations: Vec<String> = findings
        .iter()
        .filter(|f| f.severity == "critical" || f.severity == "high")
        .map(|f| f.recommendation.clone())
        .collect();

    AuditReport {
        timestamp: Utc::now().to_rfc3339(),
        audit_type: target.audit_type.clone(),
        target: target.path.display().to_string(),
        findings,
        severity: severity.to_string(),
        recommendations,
    }
}

// ============================================================================
// Background Audit Task
// ============================================================================

async fn audit_rotation_task(state: Arc<AppState>) {
    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60)); // Every minute

    loop {
        interval.tick().await;

        let targets = state.audit_targets.read().await;
        if targets.is_empty() {
            continue;
        }

        // Get next target to audit (round-robin)
        let mut index = state.audit_index.write().await;
        let target_index = *index % targets.len();
        *index += 1;
        drop(index);

        let target = &targets[target_index];

        // Perform audit
        let report = perform_audit(target).await;

        // Log findings
        if report.severity == "critical" || report.severity == "high" {
            warn!("Audit found {} issues in {}", report.severity, report.target);
        } else if report.severity == "clean" {
            info!("Audit clean: {}", report.target);
        }

        // Store report
        {
            let mut reports = state.recent_reports.write().await;
            reports.push(report.clone());

            // Keep only last 100 reports
            if reports.len() > 100 {
                reports.remove(0);
            }
        }

        // TODO: Store in database
    }
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Auditor Agent: ONLINE")
}

async fn get_recent_reports(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let reports = state.recent_reports.read().await;
    Json(reports.clone())
}

async fn get_audit_status(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let targets = state.audit_targets.read().await;
    let reports = state.recent_reports.read().await;
    let index = state.audit_index.read().await;

    Json(serde_json::json!({
        "total_targets": targets.len(),
        "audits_completed": *index,
        "recent_reports": reports.len(),
        "critical_findings": reports.iter().filter(|r| r.severity == "critical").count(),
        "high_findings": reports.iter().filter(|r| r.severity == "high").count(),
    }))
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Auditor Agent");

    // Initialize audit targets
    let mut targets = Vec::new();

    // Add log files
    let log_dir = PathBuf::from("/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/logs");
    if log_dir.exists() {
        for entry in WalkDir::new(&log_dir).max_depth(2) {
            if let Ok(entry) = entry {
                if entry.path().extension().and_then(|s| s.to_str()) == Some("log") {
                    targets.push(AuditTarget {
                        path: entry.path().to_path_buf(),
                        audit_type: "log".to_string(),
                        last_audited: None,
                        priority: 8,
                    });
                }
            }
        }
    }

    // Add design documents
    let docs_dir = PathBuf::from("/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d");
    if docs_dir.exists() {
        for entry in WalkDir::new(&docs_dir).max_depth(3) {
            if let Ok(entry) = entry {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if ext == "md" && entry.path().to_str().unwrap().contains("ARCHITECTURE") {
                        targets.push(AuditTarget {
                            path: entry.path().to_path_buf(),
                            audit_type: "design".to_string(),
                            last_audited: None,
                            priority: 5,
                        });
                    }
                }
            }
        }
    }

    // Add code files
    let agents_dir = PathBuf::from("/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo");
    if agents_dir.exists() {
        for entry in WalkDir::new(&agents_dir).max_depth(4) {
            if let Ok(entry) = entry {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if ext == "rs" {
                        targets.push(AuditTarget {
                            path: entry.path().to_path_buf(),
                            audit_type: "code".to_string(),
                            last_audited: None,
                            priority: 7,
                        });
                    }
                }
            }
        }
    }

    info!("Initialized with {} audit targets", targets.len());

    let state = Arc::new(AppState {
        audit_targets: Arc::new(RwLock::new(targets)),
        recent_reports: Arc::new(RwLock::new(Vec::new())),
        audit_index: Arc::new(RwLock::new(0)),
    });

    // Start audit rotation task
    let audit_state = Arc::clone(&state);
    tokio::spawn(async move {
        audit_rotation_task(audit_state).await;
    });

    // Build router
    let app = Router::new()
        .route("/health", get(health))
        .route("/reports", get(get_recent_reports))
        .route("/status", get(get_audit_status))
        .with_state(state);

    let addr = "127.0.0.1:9002";
    info!("Auditor Agent listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
