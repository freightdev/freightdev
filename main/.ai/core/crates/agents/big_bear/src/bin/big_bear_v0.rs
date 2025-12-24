// Big Bear v0.0.1
// "The road has eyes. Big Bear sees them all."
//
// Big Bear is NOT a dispatcher. He doesn't route you.
// Big Bear WATCHES. He sees the bears, the scales, the accidents, the hazards.
// He tells you what's out there. What you do with it is up to you.
//
// Stay safe. Stay informed. Big Bear's got your back.

use anyhow::{Context, Result};
use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, warn, error};
use uuid::Uuid;

mod report_collector;
mod alert_engine;
mod weigh_station_tracker;
mod geo_mapper;
mod incident_feed;

use report_collector::ReportCollector;
use alert_engine::AlertEngine;
use weigh_station_tracker::WeighStationTracker;
use geo_mapper::GeoMapper;
use incident_feed::IncidentFeed;

// ============================================================================
// AGENT IDENTITY
// ============================================================================

const AGENT_ID: &str = "BB";
const AGENT_NAME: &str = "Big Bear";
const AGENT_VERSION: &str = "0.0.1";
const AGENT_TAGLINE: &str = "The road has eyes. Big Bear sees them all.";

// ============================================================================
// ALERT TYPES - WHAT BIG BEAR SEES
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum AlertType {
    // Law Enforcement
    BearSighting,          // Smokey on the road
    SpeedTrap,             // Speed enforcement zone
    ScaleOpen,             // Weigh station is OPEN
    ScaleClosed,           // Weigh station is CLOSED
    DOTInspection,         // DOT doing inspections
    
    // Hazards
    Accident,              // Traffic accident
    RoadClosure,           // Road closed
    Construction,          // Construction zone
    WeatherHazard,         // Ice, snow, fog, etc.
    Debris,                // Debris on road
    
    // Traffic
    HeavyTraffic,          // Congestion
    Slowdown,              // Traffic slowing
    Backup,                // Major backup
    
    // Other
    ParkingAvailable,      // Truck parking available
    ParkingFull,           // Truck parking full
    FuelPrice,             // Notable fuel prices
    RestArea,              // Rest area status
}

impl AlertType {
    pub fn icon(&self) -> &'static str {
        match self {
            AlertType::BearSighting => "🚓",
            AlertType::SpeedTrap => "📡",
            AlertType::ScaleOpen => "⚖️",
            AlertType::ScaleClosed => "✅",
            AlertType::DOTInspection => "🔍",
            AlertType::Accident => "💥",
            AlertType::RoadClosure => "🚧",
            AlertType::Construction => "👷",
            AlertType::WeatherHazard => "⚠️",
            AlertType::Debris => "🪨",
            AlertType::HeavyTraffic => "🐌",
            AlertType::Slowdown => "⏰",
            AlertType::Backup => "🚗🚗🚗",
            AlertType::ParkingAvailable => "🅿️",
            AlertType::ParkingFull => "🚫",
            AlertType::FuelPrice => "⛽",
            AlertType::RestArea => "🛏️",
        }
    }
}

// ============================================================================
// ALERT STRUCTURE
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoadAlert {
    pub id: String,
    pub alert_type: AlertType,
    pub location: GeoLocation,
    pub description: String,
    pub source: AlertSource,
    pub confidence: f32,         // 0.0 - 1.0
    pub severity: AlertSeverity,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub verified: bool,
    pub report_count: u32,       // Number of reports for this alert
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeoLocation {
    pub latitude: f64,
    pub longitude: f64,
    pub road: Option<String>,     // e.g., "I-80"
    pub mile_marker: Option<f64>, // e.g., "Mile 245.3"
    pub direction: Option<String>, // e.g., "Eastbound"
    pub city: Option<String>,
    pub state: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AlertSource {
    UserReport,           // Driver reported it
    Government,           // Official DOT/State data
    TrafficFeed,          // Traffic data provider
    WeighStation,         // Direct from scale system
    Verified,             // Multiple confirmed reports
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AlertSeverity {
    Info,       // FYI - parking, fuel prices
    Low,        // Scale closed, light traffic
    Medium,     // Scale open, construction
    High,       // Bear sighting, accident
    Critical,   // Road closure, major hazard
}

// ============================================================================
// USER REPORTS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserReport {
    pub id: String,
    pub user_id: Option<String>,  // Anonymous allowed
    pub alert_type: AlertType,
    pub location: GeoLocation,
    pub description: String,
    pub photo_url: Option<String>,
    pub timestamp: DateTime<Utc>,
}

// ============================================================================
// WEIGH STATION STATUS
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeighStationStatus {
    pub id: String,
    pub name: String,
    pub location: GeoLocation,
    pub status: StationStatus,
    pub last_updated: DateTime<Utc>,
    pub typical_hours: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum StationStatus {
    Open,
    Closed,
    Unknown,
}

// ============================================================================
// BIG BEAR AGENT
// ============================================================================

pub struct BigBear {
    report_collector: ReportCollector,
    alert_engine: AlertEngine,
    weigh_station_tracker: WeighStationTracker,
    geo_mapper: GeoMapper,
    incident_feed: IncidentFeed,
    
    // Active alerts cache
    alerts: Arc<RwLock<HashMap<String, RoadAlert>>>,
    
    // Weigh stations
    weigh_stations: Arc<RwLock<HashMap<String, WeighStationStatus>>>,
    
    // Configuration
    config: BigBearConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BigBearConfig {
    pub enable_user_reports: bool,
    pub enable_gov_feed: bool,
    pub alert_expiry_hours: i64,
    pub min_confidence_threshold: f32,
    pub require_verification: bool,
}

impl Default for BigBearConfig {
    fn default() -> Self {
        Self {
            enable_user_reports: true,
            enable_gov_feed: true,
            alert_expiry_hours: 2, // Alerts expire after 2 hours
            min_confidence_threshold: 0.5,
            require_verification: false,
        }
    }
}

impl BigBear {
    pub async fn new(config: BigBearConfig) -> Result<Self> {
        info!("🐻 Initializing {} v{}", AGENT_NAME, AGENT_VERSION);
        info!("👁️  {}", AGENT_TAGLINE);
        info!("");
        info!("Big Bear is watching...");
        info!("");
        
        let mut bear = Self {
            report_collector: ReportCollector::new(),
            alert_engine: AlertEngine::new(),
            weigh_station_tracker: WeighStationTracker::new().await?,
            geo_mapper: GeoMapper::new(),
            incident_feed: IncidentFeed::new().await?,
            alerts: Arc::new(RwLock::new(HashMap::new())),
            weigh_stations: Arc::new(RwLock::new(HashMap::new())),
            config,
        };
        
        // Load initial data
        bear.bootstrap().await?;
        
        Ok(bear)
    }
    
    async fn bootstrap(&mut self) -> Result<()> {
        info!("🔄 Bootstrapping Big Bear...");
        
        // Load weigh stations
        if self.config.enable_gov_feed {
            let stations = self.weigh_station_tracker.fetch_all_stations().await?;
            let mut ws = self.weigh_stations.write().await;
            for station in stations {
                ws.insert(station.id.clone(), station);
            }
            info!("✅ Loaded {} weigh stations", ws.len());
        }
        
        // Load active incidents
        let incidents = self.incident_feed.fetch_incidents().await?;
        let mut alerts = self.alerts.write().await;
        for alert in incidents {
            alerts.insert(alert.id.clone(), alert);
        }
        info!("✅ Loaded {} active alerts", alerts.len());
        
        Ok(())
    }
    
    // ========================================================================
    // SUBMIT USER REPORT
    // ========================================================================
    
    pub async fn submit_report(&mut self, report: UserReport) -> Result<String> {
        info!("📍 New report: {:?} at {}, {}", 
              report.alert_type, 
              report.location.latitude, 
              report.location.longitude);
        
        if !self.config.enable_user_reports {
            anyhow::bail!("User reports are disabled");
        }
        
        // Check if there's already a similar alert nearby
        let existing = self.find_nearby_alert(
            &report.alert_type,
            &report.location,
            0.5, // Within 0.5 miles
        ).await;
        
        if let Some(mut alert) = existing {
            // Update existing alert
            alert.report_count += 1;
            alert.confidence = (alert.confidence + 0.2).min(1.0);
            
            if alert.report_count >= 3 {
                alert.verified = true;
                alert.source = AlertSource::Verified;
            }
            
            let alert_id = alert.id.clone();
            let mut alerts = self.alerts.write().await;
            alerts.insert(alert_id.clone(), alert);
            
            info!("✅ Updated existing alert (now {} reports)", alert.report_count);
            Ok(alert_id)
        } else {
            // Create new alert
            let alert = RoadAlert {
                id: Uuid::new_v4().to_string(),
                alert_type: report.alert_type.clone(),
                location: report.location.clone(),
                description: report.description,
                source: AlertSource::UserReport,
                confidence: 0.7, // Single report starts at 70%
                severity: Self::calculate_severity(&report.alert_type),
                created_at: Utc::now(),
                expires_at: Utc::now() + Duration::hours(self.config.alert_expiry_hours),
                verified: false,
                report_count: 1,
            };
            
            let alert_id = alert.id.clone();
            let mut alerts = self.alerts.write().await;
            alerts.insert(alert_id.clone(), alert);
            
            info!("✅ Created new alert: {}", alert_id);
            Ok(alert_id)
        }
    }
    
    async fn find_nearby_alert(
        &self,
        alert_type: &AlertType,
        location: &GeoLocation,
        radius_miles: f64,
    ) -> Option<RoadAlert> {
        let alerts = self.alerts.read().await;
        
        for alert in alerts.values() {
            if &alert.alert_type == alert_type {
                let distance = self.geo_mapper.distance_miles(
                    location.latitude,
                    location.longitude,
                    alert.location.latitude,
                    alert.location.longitude,
                );
                
                if distance <= radius_miles {
                    return Some(alert.clone());
                }
            }
        }
        
        None
    }
    
    fn calculate_severity(alert_type: &AlertType) -> AlertSeverity {
        match alert_type {
            AlertType::BearSighting => AlertSeverity::High,
            AlertType::SpeedTrap => AlertSeverity::High,
            AlertType::ScaleOpen => AlertSeverity::Medium,
            AlertType::ScaleClosed => AlertSeverity::Low,
            AlertType::DOTInspection => AlertSeverity::High,
            AlertType::Accident => AlertSeverity::High,
            AlertType::RoadClosure => AlertSeverity::Critical,
            AlertType::Construction => AlertSeverity::Medium,
            AlertType::WeatherHazard => AlertSeverity::High,
            AlertType::Debris => AlertSeverity::Medium,
            AlertType::HeavyTraffic => AlertSeverity::Medium,
            AlertType::Slowdown => AlertSeverity::Low,
            AlertType::Backup => AlertSeverity::Medium,
            AlertType::ParkingAvailable => AlertSeverity::Info,
            AlertType::ParkingFull => AlertSeverity::Info,
            AlertType::FuelPrice => AlertSeverity::Info,
            AlertType::RestArea => AlertSeverity::Info,
        }
    }
    
    // ========================================================================
    // GET ALERTS IN AREA
    // ========================================================================
    
    pub async fn get_alerts_in_area(
        &self,
        latitude: f64,
        longitude: f64,
        radius_miles: f64,
    ) -> Vec<RoadAlert> {
        let alerts = self.alerts.read().await;
        
        alerts.values()
            .filter(|alert| {
                let distance = self.geo_mapper.distance_miles(
                    latitude,
                    longitude,
                    alert.location.latitude,
                    alert.location.longitude,
                );
                
                distance <= radius_miles && alert.expires_at > Utc::now()
            })
            .cloned()
            .collect()
    }
    
    // ========================================================================
    // GET ALERTS ON ROUTE
    // ========================================================================
    
    pub async fn get_alerts_on_route(
        &self,
        route_points: Vec<(f64, f64)>,
        buffer_miles: f64,
    ) -> Vec<RoadAlert> {
        let alerts = self.alerts.read().await;
        
        alerts.values()
            .filter(|alert| {
                // Check if alert is near any point on the route
                route_points.iter().any(|(lat, lon)| {
                    let distance = self.geo_mapper.distance_miles(
                        *lat,
                        *lon,
                        alert.location.latitude,
                        alert.location.longitude,
                    );
                    distance <= buffer_miles
                }) && alert.expires_at > Utc::now()
            })
            .cloned()
            .collect()
    }
    
    // ========================================================================
    // WEIGH STATION OPERATIONS
    // ========================================================================
    
    pub async fn get_weigh_stations_on_route(
        &self,
        route_points: Vec<(f64, f64)>,
        buffer_miles: f64,
    ) -> Vec<WeighStationStatus> {
        let stations = self.weigh_stations.read().await;
        
        stations.values()
            .filter(|station| {
                route_points.iter().any(|(lat, lon)| {
                    let distance = self.geo_mapper.distance_miles(
                        *lat,
                        *lon,
                        station.location.latitude,
                        station.location.longitude,
                    );
                    distance <= buffer_miles
                })
            })
            .cloned()
            .collect()
    }
    
    pub async fn update_weigh_station_status(
        &mut self,
        station_id: &str,
        status: StationStatus,
    ) -> Result<()> {
        let mut stations = self.weigh_stations.write().await;
        
        if let Some(station) = stations.get_mut(station_id) {
            station.status = status.clone();
            station.last_updated = Utc::now();
            
            // Create an alert for this status change
            let alert_type = match status {
                StationStatus::Open => AlertType::ScaleOpen,
                StationStatus::Closed => AlertType::ScaleClosed,
                StationStatus::Unknown => return Ok(()),
            };
            
            let alert = RoadAlert {
                id: Uuid::new_v4().to_string(),
                alert_type,
                location: station.location.clone(),
                description: format!("{} is now {:?}", station.name, status),
                source: AlertSource::WeighStation,
                confidence: 1.0,
                severity: Self::calculate_severity(&alert_type),
                created_at: Utc::now(),
                expires_at: Utc::now() + Duration::hours(4),
                verified: true,
                report_count: 1,
            };
            
            let mut alerts = self.alerts.write().await;
            alerts.insert(alert.id.clone(), alert);
            
            info!("✅ Updated station {}: {:?}", station.name, status);
        }
        
        Ok(())
    }
    
    // ========================================================================
    // MAINTENANCE
    // ========================================================================
    
    pub async fn expire_old_alerts(&mut self) -> usize {
        let mut alerts = self.alerts.write().await;
        let before_count = alerts.len();
        
        alerts.retain(|_, alert| alert.expires_at > Utc::now());
        
        let expired = before_count - alerts.len();
        if expired > 0 {
            info!("🗑️  Expired {} old alerts", expired);
        }
        
        expired
    }
    
    pub async fn refresh_feeds(&mut self) -> Result<()> {
        info!("🔄 Refreshing data feeds...");
        
        // Refresh incidents
        if self.config.enable_gov_feed {
            let incidents = self.incident_feed.fetch_incidents().await?;
            let mut alerts = self.alerts.write().await;
            
            for alert in incidents {
                alerts.insert(alert.id.clone(), alert);
            }
        }
        
        // Refresh weigh stations
        let station_updates = self.weigh_station_tracker.fetch_status_updates().await?;
        for (id, status) in station_updates {
            self.update_weigh_station_status(&id, status).await?;
        }
        
        info!("✅ Feeds refreshed");
        Ok(())
    }
    
    // ========================================================================
    // STATISTICS
    // ========================================================================
    
    pub async fn get_stats(&self) -> BearStats {
        let alerts = self.alerts.read().await;
        let stations = self.weigh_stations.read().await;
        
        let active_bears = alerts.values()
            .filter(|a| matches!(a.alert_type, AlertType::BearSighting | AlertType::SpeedTrap))
            .count();
        
        let open_scales = stations.values()
            .filter(|s| s.status == StationStatus::Open)
            .count();
        
        let active_hazards = alerts.values()
            .filter(|a| matches!(a.severity, AlertSeverity::High | AlertSeverity::Critical))
            .count();
        
        BearStats {
            total_alerts: alerts.len(),
            active_bears,
            open_scales,
            active_hazards,
            verified_alerts: alerts.values().filter(|a| a.verified).count(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BearStats {
    pub total_alerts: usize,
    pub active_bears: usize,
    pub open_scales: usize,
    pub active_hazards: usize,
    pub verified_alerts: usize,
}

// ============================================================================
// MAIN
// ============================================================================

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    
    info!("🐻 {} v{} starting...", AGENT_NAME, AGENT_VERSION);
    info!("👁️  {}", AGENT_TAGLINE);
    info!("");
    info!("Big Bear is watching the roads...");
    info!("Monitoring law enforcement, weigh stations, and hazards.");
    info!("");
    
    let config = BigBearConfig::default();
    let mut bear = BigBear::new(config).await?;
    
    // Example: Submit a report
    let report = UserReport {
        id: Uuid::new_v4().to_string(),
        user_id: Some("driver-001".to_string()),
        alert_type: AlertType::BearSighting,
        location: GeoLocation {
            latitude: 41.8781,
            longitude: -87.6298,
            road: Some("I-80".to_string()),
            mile_marker: Some(155.5),
            direction: Some("Eastbound".to_string()),
            city: Some("Chicago".to_string()),
            state: Some("IL".to_string()),
        },
        description: "State trooper in median with radar".to_string(),
        photo_url: None,
        timestamp: Utc::now(),
    };
    
    let alert_id = bear.submit_report(report).await?;
    info!("✅ Report submitted: {}", alert_id);
    
    // Get stats
    let stats = bear.get_stats().await;
    info!("");
    info!("📊 Big Bear Stats:");
    info!("   Total alerts: {}", stats.total_alerts);
    info!("   Active bears: {}", stats.active_bears);
    info!("   Open scales: {}", stats.open_scales);
    info!("   Active hazards: {}", stats.active_hazards);
    info!("");
    
    Ok(())
}
