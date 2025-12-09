// Broker Tactics Database - Known manipulation patterns
// This is the accumulated wisdom from drivers who've been burned

use anyhow::Result;
use serde::{Deserialize, Serialize};
use crate::BrokerTactic;

#[derive(Debug, Serialize, Deserialize)]
pub struct BrokerTacticRecord {
    pub tactic: BrokerTactic,
    pub description: String,
    pub examples: Vec<String>,
    pub counter_strategy: String,
    pub severity: crate::TacticSeverity,
}

pub struct BrokerTacticDatabase {
    tactics: Vec<BrokerTacticRecord>,
}

impl BrokerTacticDatabase {
    pub fn new() -> Result<Self> {
        Ok(Self {
            tactics: Self::load_tactics(),
        })
    }
    
    pub fn get_tactic_info(&self, tactic: &BrokerTactic) -> Option<&BrokerTacticRecord> {
        self.tactics.iter().find(|t| &t.tactic == tactic)
    }
    
    fn load_tactics() -> Vec<BrokerTacticRecord> {
        vec![
            BrokerTacticRecord {
                tactic: BrokerTactic::UrgencyPressure,
                description: "Creates false urgency to prevent driver from thinking or comparing rates".to_string(),
                examples: vec![
                    "This load won't last 5 minutes!".to_string(),
                    "I need to know right now".to_string(),
                    "If you don't take it, someone else will".to_string(),
                ],
                counter_strategy: "Take your time. Real opportunities don't require split-second decisions.".to_string(),
                severity: crate::TacticSeverity::Warning,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::FalseSarcity,
                description: "Claims many drivers want the load to create competition pressure".to_string(),
                examples: vec![
                    "I have 10 other drivers calling about this".to_string(),
                    "Everyone wants this load".to_string(),
                    "This is a hot load".to_string(),
                ],
                counter_strategy: "If it's such a great load, why are they still calling? Ask yourself that.".to_string(),
                severity: crate::TacticSeverity::Warning,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::TimeDecay,
                description: "Claims rate decreases over time to force immediate acceptance".to_string(),
                examples: vec![
                    "Rate drops $50 every hour".to_string(),
                    "Price goes down if you wait".to_string(),
                ],
                counter_strategy: "Market rates don't change that fast. This is artificial pressure.".to_string(),
                severity: crate::TacticSeverity::Alert,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::Lowballing,
                description: "Offers significantly below market rate hoping driver is desperate".to_string(),
                examples: vec![
                    "Best I can do is $1.50/mile for that lane".to_string(),
                    "That's all I have in the budget".to_string(),
                ],
                counter_strategy: "Know your worth. Know the market. Don't take garbage rates.".to_string(),
                severity: crate::TacticSeverity::Alert,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::BaitAndSwitch,
                description: "Changes rate or terms after driver shows interest".to_string(),
                examples: vec![
                    "Actually, the rate is $2000, not $2500".to_string(),
                    "Sorry, I made a mistake on the rate".to_string(),
                ],
                counter_strategy: "Walk away immediately. This is a major red flag about their integrity.".to_string(),
                severity: crate::TacticSeverity::Critical,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::GuiltTrip,
                description: "Uses emotional manipulation to pressure driver into poor decision".to_string(),
                examples: vec![
                    "Come on man, help me out here".to_string(),
                    "Do me this favor, I'll remember it".to_string(),
                ],
                counter_strategy: "This is business, not friendship. Don't let emotion override logic.".to_string(),
                severity: crate::TacticSeverity::Warning,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::HiddenStops,
                description: "Fails to mention additional stops until after commitment".to_string(),
                examples: vec![
                    "Oh, by the way, there's one more stop".to_string(),
                    "Actually it's 3 stops, not 2".to_string(),
                ],
                counter_strategy: "Get FULL details before agreeing. Additional stops mean more time, fuel, and risk.".to_string(),
                severity: crate::TacticSeverity::Critical,
            },
            
            BrokerTacticRecord {
                tactic: BrokerTactic::WeekendTrap,
                description: "Friday pickup with Monday delivery ruins weekend without premium pay".to_string(),
                examples: vec![
                    "Friday afternoon pickup, Monday morning delivery".to_string(),
                ],
                counter_strategy: "Your weekend has value. Demand premium pay or pass on the load.".to_string(),
                severity: crate::TacticSeverity::Warning,
            },
        ]
    }
    
    pub fn search_by_keyword(&self, keyword: &str) -> Vec<&BrokerTacticRecord> {
        let keyword_lower = keyword.to_lowercase();
        self.tactics.iter()
            .filter(|t| {
                t.description.to_lowercase().contains(&keyword_lower) ||
                t.examples.iter().any(|e| e.to_lowercase().contains(&keyword_lower))
            })
            .collect()
    }
}
