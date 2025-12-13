// Filter Engine - Smart filtering for loads
// Find exactly what you're looking for

use crate::{FreightLoad, LoadFilter};

pub struct FilterEngine {}

impl FilterEngine {
    pub fn new() -> Self {
        Self {}
    }
    
    pub fn filter(&self, loads: Vec<FreightLoad>, filter: LoadFilter) -> Vec<FreightLoad> {
        loads.into_iter()
            .filter(|load| self.matches_filter(load, &filter))
            .collect()
    }
    
    fn matches_filter(&self, load: &FreightLoad, filter: &LoadFilter) -> bool {
        // Origin states
        if let Some(ref states) = filter.origin_states {
            if !states.contains(&load.origin_state) {
                return false;
            }
        }
        
        // Destination states
        if let Some(ref states) = filter.destination_states {
            if !states.contains(&load.destination_state) {
                return false;
            }
        }
        
        // Equipment types
        if let Some(ref types) = filter.equipment_types {
            if !types.iter().any(|t| load.equipment_type.contains(t)) {
                return false;
            }
        }
        
        // Rate filters
        if let Some(min_rate) = filter.min_rate {
            if load.rate.unwrap_or(0.0) < min_rate {
                return false;
            }
        }
        
        if let Some(max_rate) = filter.max_rate {
            if load.rate.unwrap_or(f32::MAX) > max_rate {
                return false;
            }
        }
        
        // Rate per mile
        if let Some(min_rpm) = filter.min_rate_per_mile {
            if load.rate_per_mile.unwrap_or(0.0) < min_rpm {
                return false;
            }
        }
        
        // Distance
        if let Some(min_dist) = filter.min_distance {
            if load.distance_miles.unwrap_or(0) < min_dist {
                return false;
            }
        }
        
        if let Some(max_dist) = filter.max_distance {
            if load.distance_miles.unwrap_or(u32::MAX) > max_dist {
                return false;
            }
        }
        
        // Weight
        if let Some(min_weight) = filter.min_weight {
            if load.weight_lbs.unwrap_or(0) < min_weight {
                return false;
            }
        }
        
        if let Some(max_weight) = filter.max_weight {
            if load.weight_lbs.unwrap_or(u32::MAX) > max_weight {
                return false;
            }
        }
        
        true
    }
}

// ============================================================================
// SCORE RANKER
// ============================================================================

use crate::ScoringPreferences;

pub struct ScoreRanker {}

impl ScoreRanker {
    pub fn new() -> Self {
        Self {}
    }
    
    pub fn rank(&self, mut loads: Vec<FreightLoad>, prefs: ScoringPreferences) -> Vec<FreightLoad> {
        // Calculate score for each load
        for load in &mut loads {
            load.score = Some(self.calculate_score(load, &prefs));
        }
        
        // Sort by score (highest first)
        loads.sort_by(|a, b| {
            b.score.unwrap_or(0.0).partial_cmp(&a.score.unwrap_or(0.0)).unwrap()
        });
        
        loads
    }
    
    fn calculate_score(&self, load: &FreightLoad, prefs: &ScoringPreferences) -> f32 {
        let mut score = 0.0;
        
        // Rate score
        if let Some(rate) = load.rate {
            let rate_score = (rate / 3000.0).min(1.0); // Normalize to 0-1
            score += rate_score * prefs.rate_importance;
        }
        
        // Distance score (prefer medium distances)
        if let Some(distance) = load.distance_miles {
            let distance_score = if distance > 500 && distance < 1500 {
                1.0
            } else if distance > 300 && distance < 2000 {
                0.7
            } else {
                0.3
            };
            score += distance_score * prefs.distance_importance;
        }
        
        // Lane preference
        let lane_score = prefs.preferred_lanes.iter()
            .find(|lane| {
                lane.origin_state == load.origin_state &&
                lane.destination_state == load.destination_state
            })
            .map(|lane| lane.preference_score)
            .unwrap_or(0.5);
        
        score += lane_score * 0.3; // Lane preference weight
        
        // Normalize to 0-100
        (score * 100.0).min(100.0)
    }
}
