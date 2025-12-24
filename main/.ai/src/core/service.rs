// gRPC Service Implementation for Command Coordinator
// Implements AgentCoordinator service from agency.proto
// Port: 9115 (HTTP + 100)

use std::sync::Arc;
use tonic::{Request, Response, Status};
use tracing::info;

// Import generated protobuf code
pub mod proto {
    include!("proto/agency.rs");
}

use proto::{
    agent_coordinator_server::{AgentCoordinator, AgentCoordinatorServer},
    AgentRegistration, AgentRequest, AgentResponse, DiscoveryRequest,
    DiscoveryResponse, HealthCheck, HealthStatus, KeyGrant, KeyRequest, RegistrationAck,
    ValidationResult, KeyValidation,
};

use crate::AppState;

// ============================================================================
// Coordinator gRPC Service
// ============================================================================

pub struct CoordinatorService {
    state: Arc<AppState>,
}

impl CoordinatorService {
    pub fn new(state: Arc<AppState>) -> Self {
        Self { state }
    }

    pub fn into_server(self) -> AgentCoordinatorServer<Self> {
        AgentCoordinatorServer::new(self)
    }
}

#[tonic::async_trait]
impl AgentCoordinator for CoordinatorService {
    /// Register a new agent with the coordinator
    async fn register(
        &self,
        request: Request<AgentRegistration>,
    ) -> Result<Response<RegistrationAck>, Status> {
        let req = request.into_inner();

        info!(
            "Agent registration request: {} v{} with {} capabilities",
            req.agent_name,
            req.version,
            req.capabilities.len()
        );

        // TODO: Store agent registration in state/database
        // For now, accept all registrations

        let response = RegistrationAck {
            accepted: true,
            agent_id: format!("agent_{}", uuid::Uuid::new_v4().to_string()),
            coordinator_endpoint: "127.0.0.1:9115".to_string(),
            error: String::new(),
        };

        Ok(Response::new(response))
    }

    /// Send request from one agent to another
    async fn send_request(
        &self,
        request: Request<AgentRequest>,
    ) -> Result<Response<AgentResponse>, Status> {
        let req = request.into_inner();

        info!(
            "Agent request: {} -> {} (action: {})",
            req.from_agent, req.to_agent, req.action
        );

        // TODO: Route request to target agent via gRPC
        // For now, return success with empty payload

        let response = AgentResponse {
            request_id: req.request_id,
            success: true,
            result: vec![],
            error: String::new(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            duration_ms: 0,
        };

        Ok(Response::new(response))
    }

    /// Request capabilities key for an agent
    async fn request_key(
        &self,
        request: Request<KeyRequest>,
    ) -> Result<Response<KeyGrant>, Status> {
        let req = request.into_inner();

        info!(
            "Key request from {} for {} capabilities",
            req.agent_name,
            req.capabilities.len()
        );

        // TODO: Implement proper key management
        // For now, grant all requested capabilities

        let response = KeyGrant {
            key_id: format!("key_{}", uuid::Uuid::new_v4().to_string()),
            agent_name: req.agent_name,
            capabilities: req.capabilities,
            issued_at: chrono::Utc::now().timestamp_millis(),
            expires_at: 0, // Never expires for now
            revoked: false,
        };

        Ok(Response::new(response))
    }

    /// Validate a capabilities key
    async fn validate_key(
        &self,
        request: Request<KeyValidation>,
    ) -> Result<Response<ValidationResult>, Status> {
        let req = request.into_inner();

        info!("Validating key {} for capability {}", req.key_id, req.capability);

        // TODO: Implement proper key validation
        // For now, accept all keys

        let response = ValidationResult {
            valid: true,
            reason: String::new(),
        };

        Ok(Response::new(response))
    }

    /// Discover agents by capability
    async fn find_agents(
        &self,
        request: Request<DiscoveryRequest>,
    ) -> Result<Response<DiscoveryResponse>, Status> {
        let req = request.into_inner();

        info!(
            "Discovery request for capability: {} (online_only: {})",
            req.capability, req.online_only
        );

        // TODO: Query agent registry
        // For now, return empty list

        let response = DiscoveryResponse { agents: vec![] };

        Ok(Response::new(response))
    }

    /// Health check for coordinator
    async fn check_health(
        &self,
        request: Request<HealthCheck>,
    ) -> Result<Response<HealthStatus>, Status> {
        let req = request.into_inner();

        info!("Health check from {}", req.agent_name);

        let response = HealthStatus {
            agent_name: "command-coordinator".to_string(),
            healthy: true,
            status: "online".to_string(),
            uptime_seconds: 0, // TODO: Track actual uptime
            metrics: std::collections::HashMap::new(),
        };

        Ok(Response::new(response))
    }
}

// ============================================================================
// Helper: Start gRPC Server
// ============================================================================

pub async fn start_grpc_server(state: Arc<AppState>) -> anyhow::Result<()> {
    let addr = "127.0.0.1:9115".parse()?;
    let coordinator_service = CoordinatorService::new(state);

    info!("Starting gRPC server on {}", addr);
    info!("gRPC Endpoints:");
    info!("  Register - Agent registration");
    info!("  SendRequest - Agent-to-agent communication");
    info!("  RequestKey - Capability key requests");
    info!("  ValidateKey - Key validation");
    info!("  FindAgents - Agent discovery");
    info!("  CheckHealth - Health checks");

    tonic::transport::Server::builder()
        .add_service(coordinator_service.into_server())
        .serve(addr)
        .await?;

    Ok(())
}
