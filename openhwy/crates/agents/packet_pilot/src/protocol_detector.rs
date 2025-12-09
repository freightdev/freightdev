// Protocol detection for different brokers

use anyhow::Result;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BrokerProtocol {
    pub name: String,
    pub broker: String,
    pub submission_method: SubmissionMethod,
    pub field_mappings: HashMap<String, String>,
    pub packet_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum SubmissionMethod {
    Email,
    OnlinePortal,
    Fax,
    API,
}

pub struct ProtocolDetector {
    known_protocols: HashMap<String, BrokerProtocol>,
}

impl ProtocolDetector {
    pub fn new() -> Self {
        let mut known_protocols = HashMap::new();
        
        // CH Robinson protocol
        known_protocols.insert(
            "ch robinson".to_lowercase(),
            BrokerProtocol {
                name: "CH Robinson Standard Packet".to_string(),
                broker: "CH Robinson".to_string(),
                submission_method: SubmissionMethod::Email,
                field_mappings: Self::ch_robinson_fields(),
                packet_url: Some("https://www.chrobinson.com/carrier-packet".to_string()),
            },
        );
        
        // TQL protocol
        known_protocols.insert(
            "tql".to_lowercase(),
            BrokerProtocol {
                name: "TQL Carrier Setup".to_string(),
                broker: "TQL".to_string(),
                submission_method: SubmissionMethod::OnlinePortal,
                field_mappings: Self::tql_fields(),
                packet_url: Some("https://carrier.tql.com/setup".to_string()),
            },
        );
        
        // Coyote protocol
        known_protocols.insert(
            "coyote".to_lowercase(),
            BrokerProtocol {
                name: "Coyote Logistics Packet".to_string(),
                broker: "Coyote".to_string(),
                submission_method: SubmissionMethod::Email,
                field_mappings: Self::coyote_fields(),
                packet_url: None,
            },
        );
        
        Self { known_protocols }
    }
    
    pub async fn detect(&self, broker_name: &str) -> Result<BrokerProtocol> {
        let normalized = broker_name.to_lowercase();
        
        if let Some(protocol) = self.known_protocols.get(&normalized) {
            tracing::info!("✓ Found protocol for: {}", broker_name);
            Ok(protocol.clone())
        } else {
            tracing::warn!("⚠️  No protocol found for: {}", broker_name);
            // Return generic protocol
            Ok(BrokerProtocol {
                name: "Generic Broker Packet".to_string(),
                broker: broker_name.to_string(),
                submission_method: SubmissionMethod::Email,
                field_mappings: Self::generic_fields(),
                packet_url: None,
            })
        }
    }
    
    // Field mappings for different brokers
    fn ch_robinson_fields() -> HashMap<String, String> {
        let mut fields = HashMap::new();
        fields.insert("carrier_name".to_string(), "Fast & Easy Dispatching LLC".to_string());
        fields.insert("mc_number".to_string(), "MC123456".to_string());
        fields.insert("dot_number".to_string(), "DOT789012".to_string());
        fields.insert("contact_name".to_string(), "John Dispatcher".to_string());
        fields.insert("contact_email".to_string(), "dispatch@fed.com".to_string());
        fields.insert("contact_phone".to_string(), "+15551234567".to_string());
        fields
    }
    
    fn tql_fields() -> HashMap<String, String> {
        let mut fields = HashMap::new();
        fields.insert("company_name".to_string(), "Fast & Easy Dispatching LLC".to_string());
        fields.insert("mc".to_string(), "MC123456".to_string());
        fields.insert("dot".to_string(), "DOT789012".to_string());
        fields
    }
    
    fn coyote_fields() -> HashMap<String, String> {
        let mut fields = HashMap::new();
        fields.insert("legal_name".to_string(), "Fast & Easy Dispatching LLC".to_string());
        fields.insert("mc_authority".to_string(), "MC123456".to_string());
        fields
    }
    
    fn generic_fields() -> HashMap<String, String> {
        let mut fields = HashMap::new();
        fields.insert("carrier_name".to_string(), "Fast & Easy Dispatching LLC".to_string());
        fields.insert("mc_number".to_string(), "MC123456".to_string());
        fields.insert("dot_number".to_string(), "DOT789012".to_string());
        fields
    }
}
