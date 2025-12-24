// Messaging Service
// WebSocket pub/sub, email notifications, and event streaming
// Port: 9011

use axum::{
    extract::{
        State,
        ws::{WebSocket, WebSocketUpgrade, Message},
    },
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use futures_util::{stream::StreamExt, sink::SinkExt};
use lettre::{
    message::header::ContentType,
    transport::smtp::authentication::Credentials,
    Message as EmailMessage, SmtpTransport, Transport,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use tracing::info;
use uuid::Uuid;

// ============================================================================
// Types
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AgentMessage {
    id: String,
    from: String,
    to: String,
    subject: String,
    body: String,
    message_type: MessageType,
    priority: Priority,
    timestamp: chrono::DateTime<chrono::Utc>,
    metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum MessageType {
    Command,
    Query,
    Response,
    Notification,
    Alert,
    Event,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum Priority {
    Low,
    Normal,
    High,
    Urgent,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct EmailConfig {
    smtp_server: String,
    smtp_port: u16,
    username: String,
    password: String,
    from_email: String,
    from_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct EmailRequest {
    to: Vec<String>,
    subject: String,
    body: String,
    html: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PublishRequest {
    channel: String,
    message: AgentMessage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SubscribeRequest {
    channel: String,
    agent_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct EventStream {
    id: String,
    name: String,
    events: Vec<Event>,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Event {
    id: String,
    event_type: String,
    source: String,
    data: serde_json::Value,
    timestamp: chrono::DateTime<chrono::Utc>,
}

// ============================================================================
// Application State
// ============================================================================

struct AppState {
    messages: Arc<RwLock<Vec<AgentMessage>>>,
    channels: Arc<RwLock<HashMap<String, broadcast::Sender<AgentMessage>>>>,
    subscriptions: Arc<RwLock<HashMap<String, Vec<String>>>>, // channel -> agents
    event_streams: Arc<RwLock<HashMap<String, EventStream>>>,
    email_config: Arc<RwLock<Option<EmailConfig>>>,
    global_tx: broadcast::Sender<AgentMessage>,
}

// ============================================================================
// Email Functions
// ============================================================================

async fn send_email(config: &EmailConfig, req: &EmailRequest) -> Result<(), String> {
    let mut email_builder = EmailMessage::builder()
        .from(format!("{} <{}>", config.from_name, config.from_email).parse().unwrap())
        .subject(&req.subject);

    // Add recipients
    for to_addr in &req.to {
        email_builder = email_builder.to(to_addr.parse().map_err(|e| format!("Invalid email: {}", e))?);
    }

    // Add body
    let email = if req.html {
        email_builder
            .header(ContentType::TEXT_HTML)
            .body(req.body.clone())
    } else {
        email_builder
            .body(req.body.clone())
    }
    .map_err(|e| format!("Failed to build email: {}", e))?;

    // Create SMTP client
    let creds = Credentials::new(config.username.clone(), config.password.clone());
    let mailer = SmtpTransport::relay(&config.smtp_server)
        .map_err(|e| format!("Failed to connect to SMTP: {}", e))?
        .credentials(creds)
        .build();

    // Send email
    mailer
        .send(&email)
        .map_err(|e| format!("Failed to send email: {}", e))?;

    Ok(())
}

// ============================================================================
// WebSocket Handlers
// ============================================================================

async fn handle_socket(socket: WebSocket, state: Arc<AppState>, agent_id: String) {
    let mut rx = state.global_tx.subscribe();
    let (mut sender, mut receiver) = socket.split();

    // Spawn task to send messages to this client
    let send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            let json = serde_json::to_string(&msg).unwrap();
            if sender.send(Message::Text(json)).await.is_err() {
                break;
            }
        }
    });

    // Receive messages from this client
    while let Some(Ok(msg)) = receiver.next().await {
        if let Message::Text(text) = msg {
            if let Ok(agent_msg) = serde_json::from_str::<AgentMessage>(&text) {
                // Broadcast received message
                let _ = state.global_tx.send(agent_msg.clone());

                // Store message
                let mut messages = state.messages.write().await;
                messages.push(agent_msg);
            }
        }
    }

    send_task.abort();
    info!("WebSocket connection closed for agent: {}", agent_id);
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let agent_id = Uuid::new_v4().to_string();
    info!("New WebSocket connection: {}", agent_id);
    ws.on_upgrade(move |socket| handle_socket(socket, state, agent_id))
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health() -> impl IntoResponse {
    (StatusCode::OK, "Messaging Service: ONLINE")
}

async fn send_message(
    State(state): State<Arc<AppState>>,
    Json(message): Json<AgentMessage>,
) -> impl IntoResponse {
    // Store message
    let mut messages = state.messages.write().await;
    messages.push(message.clone());

    // Broadcast via WebSocket
    let _ = state.global_tx.send(message.clone());

    info!("Message sent from {} to {}", message.from, message.to);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "message_id": message.id
        })),
    )
}

async fn publish_message(
    State(state): State<Arc<AppState>>,
    Json(req): Json<PublishRequest>,
) -> impl IntoResponse {
    // Get or create channel
    let mut channels = state.channels.write().await;
    let tx = channels
        .entry(req.channel.clone())
        .or_insert_with(|| broadcast::channel(1000).0)
        .clone();

    // Publish message
    let _ = tx.send(req.message.clone());

    // Store message
    let mut messages = state.messages.write().await;
    messages.push(req.message.clone());

    info!("Message published to channel: {}", req.channel);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "channel": req.channel,
            "message_id": req.message.id
        })),
    )
}

async fn subscribe_channel(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SubscribeRequest>,
) -> impl IntoResponse {
    // Get or create channel
    let mut channels = state.channels.write().await;
    if !channels.contains_key(&req.channel) {
        channels.insert(req.channel.clone(), broadcast::channel(1000).0);
    }

    // Add subscription
    let mut subscriptions = state.subscriptions.write().await;
    subscriptions
        .entry(req.channel.clone())
        .or_insert_with(Vec::new)
        .push(req.agent_id.clone());

    info!("Agent {} subscribed to channel {}", req.agent_id, req.channel);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "channel": req.channel,
            "agent_id": req.agent_id
        })),
    )
}

async fn list_channels(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let channels = state.channels.read().await;
    let subscriptions = state.subscriptions.read().await;

    let channel_list: Vec<serde_json::Value> = channels
        .keys()
        .map(|channel| {
            let sub_count = subscriptions.get(channel).map(|v| v.len()).unwrap_or(0);
            serde_json::json!({
                "name": channel,
                "subscribers": sub_count
            })
        })
        .collect();

    (StatusCode::OK, Json(serde_json::json!(channel_list)))
}

async fn list_messages(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let messages = state.messages.read().await;
    let recent: Vec<&AgentMessage> = messages.iter().rev().take(100).collect();
    (StatusCode::OK, Json(serde_json::json!(recent)))
}

async fn send_email_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<EmailRequest>,
) -> impl IntoResponse {
    let config_lock = state.email_config.read().await;
    let config = match config_lock.as_ref() {
        Some(c) => c,
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(serde_json::json!({"error": "Email not configured"})),
            )
        }
    };

    match send_email(config, &req).await {
        Ok(_) => {
            info!("Email sent to {:?}", req.to);
            (
                StatusCode::OK,
                Json(serde_json::json!({
                    "success": true,
                    "recipients": req.to.len()
                })),
            )
        }
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": e})),
        ),
    }
}

async fn configure_email(
    State(state): State<Arc<AppState>>,
    Json(config): Json<EmailConfig>,
) -> impl IntoResponse {
    let mut email_config = state.email_config.write().await;
    *email_config = Some(config);

    info!("Email configuration updated");

    (
        StatusCode::OK,
        Json(serde_json::json!({"success": true})),
    )
}

async fn create_event_stream(
    State(state): State<Arc<AppState>>,
    Json(req): Json<serde_json::Value>,
) -> impl IntoResponse {
    let stream = EventStream {
        id: Uuid::new_v4().to_string(),
        name: req["name"].as_str().unwrap_or("default").to_string(),
        events: Vec::new(),
        created_at: chrono::Utc::now(),
    };

    let mut streams = state.event_streams.write().await;
    streams.insert(stream.id.clone(), stream.clone());

    info!("Event stream created: {}", stream.id);

    (
        StatusCode::OK,
        Json(serde_json::json!({
            "success": true,
            "stream_id": stream.id,
            "name": stream.name
        })),
    )
}

async fn add_event(
    State(state): State<Arc<AppState>>,
    Json(req): Json<serde_json::Value>,
) -> impl IntoResponse {
    let stream_id = req["stream_id"].as_str().unwrap_or("");
    let event = Event {
        id: Uuid::new_v4().to_string(),
        event_type: req["event_type"].as_str().unwrap_or("").to_string(),
        source: req["source"].as_str().unwrap_or("").to_string(),
        data: req["data"].clone(),
        timestamp: chrono::Utc::now(),
    };

    let mut streams = state.event_streams.write().await;
    if let Some(stream) = streams.get_mut(stream_id) {
        stream.events.push(event.clone());
        (
            StatusCode::OK,
            Json(serde_json::json!({
                "success": true,
                "event_id": event.id
            })),
        )
    } else {
        (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({"error": "Stream not found"})),
        )
    }
}

async fn get_events(
    State(state): State<Arc<AppState>>,
    Json(req): Json<serde_json::Value>,
) -> impl IntoResponse {
    let stream_id = req["stream_id"].as_str().unwrap_or("");
    let streams = state.event_streams.read().await;

    if let Some(stream) = streams.get(stream_id) {
        (StatusCode::OK, Json(serde_json::json!(stream.events)))
    } else {
        (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({"error": "Stream not found"})),
        )
    }
}

// ============================================================================
// Main
// ============================================================================

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    info!("Starting Messaging Service");

    let (tx, _rx) = broadcast::channel(1000);

    let state = Arc::new(AppState {
        messages: Arc::new(RwLock::new(Vec::new())),
        channels: Arc::new(RwLock::new(HashMap::new())),
        subscriptions: Arc::new(RwLock::new(HashMap::new())),
        event_streams: Arc::new(RwLock::new(HashMap::new())),
        email_config: Arc::new(RwLock::new(None)),
        global_tx: tx,
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/message/send", post(send_message))
        .route("/message/list", get(list_messages))
        .route("/channel/publish", post(publish_message))
        .route("/channel/subscribe", post(subscribe_channel))
        .route("/channel/list", get(list_channels))
        .route("/email/send", post(send_email_handler))
        .route("/email/configure", post(configure_email))
        .route("/event/stream/create", post(create_event_stream))
        .route("/event/add", post(add_event))
        .route("/event/get", post(get_events))
        .route("/ws", get(ws_handler))
        .with_state(state);

    let addr = "127.0.0.1:9011";
    info!("Messaging Service listening on {}", addr);
    info!("WebSocket available at ws://127.0.0.1:9011/ws");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
