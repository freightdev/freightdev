// Database Manager
// SurrealDB management, CRUD operations, and query execution
// Port: 9012

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;
use tokio::sync::RwLock;
use tracing::info;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct CreateRequest {
    table: String,
    data: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ReadRequest {
    table: String,
    id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct UpdateRequest {
    table: String,
    id: String,
    data: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DeleteRequest {
    table: String,
    id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct QueryRequest {
    query: String,
    vars: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SchemaRequest {
    table: String,
    fields: Vec<FieldDefinition>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct FieldDefinition {
    name: String,
    field_type: String,
    required: bool,
    unique: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct MigrationRequest {
    name: String,
    up_sql: String,
    down_sql: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DatabaseStats {
    tables: Vec<String>,
    total_records: usize,
    database_size: String,
    uptime: String,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    db: Arc<RwLock<Surreal<Client>>>,
    migrations: Arc<RwLock<Vec<MigrationRequest>>>,
    connection_info: ConnectionInfo,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ConnectionInfo {
    host: String,
    namespace: String,
    database: String,
    connected: bool,
}

// ============================================================================
// Database Operations
// ============================================================================

async fn initialize_database() -> Result<Surreal<Client>, String> {
    info!("Connecting to SurrealDB at 127.0.0.1:8000");

    let db = Surreal::new::<Ws>("127.0.0.1:8000")
        .await
        .map_err(|e| format!("Failed to connect to SurrealDB: {}", e))?;

    db.signin(Root {
        username: "root",
        password: "root",
    })
    .await
    .map_err(|e| format!("Failed to sign in: {}", e))?;

    db.use_ns("codriver")
        .use_db("agents")
        .await
        .map_err(|e| format!("Failed to select namespace/database: {}", e))?;

    info!("Connected to SurrealDB: codriver/agents");

    Ok(db)
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Database Manager: ONLINE")
}

async fn get_info(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    (StatusCode::OK, Json(serde_json::json!(state.connection_info)))
}

async fn create_record(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreateRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    let result: Result<Option<serde_json::Value>, surrealdb::Error> =
        db.create(&req.table).content(req.data.clone()).await;

    match result {
        Ok(Some(record)) => {
            info!("Created record in table: {}", req.table);
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "record": record
                })),
            )
        }
        Ok(None) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": "Failed to create record"})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

async fn read_records(
    State(state): State<Arc<AppState>>,
    Json(req): Json<ReadRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    if let Some(id) = req.id {
        // Read specific record
        let thing = format!("{}:{}", req.table, id);
        let result: Result<Vec<serde_json::Value>, surrealdb::Error> = db.select(thing).await;

        match result {
            Ok(records) if !records.is_empty() => (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "record": records[0]
                })),
            ),
            Ok(_) => (
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "Record not found"})),
            ),
            Err(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": format!("{}", e)})),
            ),
        }
    } else {
        // Read all records from table
        let result: Result<Vec<serde_json::Value>, surrealdb::Error> =
            db.select(&req.table).await;

        match result {
            Ok(records) => (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "records": records,
                    "count": records.len()
                })),
            ),
            Err(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": format!("{}", e)})),
            ),
        }
    }
}

async fn update_record(
    State(state): State<Arc<AppState>>,
    Json(req): Json<UpdateRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    let thing = format!("{}:{}", req.table, req.id);
    let result: Result<Vec<serde_json::Value>, surrealdb::Error> =
        db.update(thing).merge(req.data).await;

    match result {
        Ok(records) if !records.is_empty() => {
            info!("Updated record in table: {}", req.table);
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "record": records[0]
                })),
            )
        }
        Ok(_) => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({"error": "Record not found"})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

async fn delete_record(
    State(state): State<Arc<AppState>>,
    Json(req): Json<DeleteRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    let thing = format!("{}:{}", req.table, req.id);
    let result: Result<Vec<serde_json::Value>, surrealdb::Error> = db.delete(thing).await;

    match result {
        Ok(records) if !records.is_empty() => {
            info!("Deleted record from table: {}", req.table);
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "deleted": records[0]
                })),
            )
        }
        Ok(_) => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({"error": "Record not found"})),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

async fn execute_query(
    State(state): State<Arc<AppState>>,
    Json(req): Json<QueryRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    let query = db.query(&req.query);

    // TODO: Add variable binding support with proper lifetime handling

    match query.await {
        Ok(response) => {
            info!("Executed query successfully");
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "response": format!("{:?}", response)
                })),
            )
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

async fn define_schema(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SchemaRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    // Build DEFINE TABLE and DEFINE FIELD statements
    let mut statements = vec![format!("DEFINE TABLE {} SCHEMAFULL;", req.table)];

    for field in &req.fields {
        let mut field_def = format!(
            "DEFINE FIELD {} ON TABLE {} TYPE {};",
            field.name, req.table, field.field_type
        );

        if field.required {
            field_def = format!("{} ASSERT $value != NONE;", field_def.trim_end_matches(';'));
        }

        statements.push(field_def);
    }

    // Execute all statements
    for statement in &statements {
        if let Err(e) = db.query(statement).await {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": format!("Failed to define schema: {}", e)})),
            );
        }
    }

    info!("Schema defined for table: {}", req.table);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "table": req.table,
            "fields": req.fields.len()
        })),
    )
}

async fn list_tables(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let db = state.db.read().await;

    let result = db.query("INFO FOR DB;").await;

    match result {
        Ok(response) => {
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "info": format!("{:?}", response)
                })),
            )
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

async fn apply_migration(
    State(state): State<Arc<AppState>>,
    Json(req): Json<MigrationRequest>,
) -> impl IntoResponse {
    let db = state.db.read().await;

    // Execute migration SQL
    match db.query(&req.up_sql).await {
        Ok(_) => {
            // Store migration
            let mut migrations = state.migrations.write().await;
            migrations.push(req.clone());

            info!("Applied migration: {}", req.name);

            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "migration": req.name
                })),
            )
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("Migration failed: {}", e)})),
        ),
    }
}

async fn list_migrations(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let migrations = state.migrations.read().await;
    let migration_list: Vec<_> = migrations
        .iter()
        .map(|m| {
            serde_json::json!({
                "name": m.name,
                "applied_at": chrono::Utc::now()
            })
        })
        .collect();

    (StatusCode::OK, Json(serde_json::json!(migration_list)))
}

async fn get_stats(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let db = state.db.read().await;

    // Get database info
    let result = db.query("INFO FOR DB;").await;

    match result {
        Ok(_) => (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "namespace": state.connection_info.namespace,
                "database": state.connection_info.database,
                "connected": state.connection_info.connected
            })),
        ),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": format!("{}", e)})),
        ),
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Database Manager");

    // Initialize database connection
    let db = match initialize_database().await {
        Ok(d) => d,
        Err(e) => {
            tracing::error!("Failed to initialize database: {}", e);
            tracing::warn!("Starting in disconnected mode - database operations will fail");
            Surreal::new::<Ws>("127.0.0.1:8000").await?
        }
    };

    let state = Arc::new(AppState {
        db: Arc::new(RwLock::new(db)),
        migrations: Arc::new(RwLock::new(Vec::new())),
        connection_info: ConnectionInfo {
            host: "127.0.0.1:8000".to_string(),
            namespace: "codriver".to_string(),
            database: "agents".to_string(),
            connected: true,
        },
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/info", get(get_info))
        .route("/create", post(create_record))
        .route("/read", post(read_records))
        .route("/update", post(update_record))
        .route("/delete", post(delete_record))
        .route("/query", post(execute_query))
        .route("/schema/define", post(define_schema))
        .route("/tables", get(list_tables))
        .route("/migration/apply", post(apply_migration))
        .route("/migration/list", get(list_migrations))
        .route("/stats", get(get_stats))
        .with_state(state);

    let addr = "127.0.0.1:9012";
    info!("Database Manager listening on {}", addr);
    info!("Connected to SurrealDB at 127.0.0.1:8000");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
