// Story Structurer - Turning raw experiences into narrative
// Every tale has a beginning, middle, and end. We find it.

use anyhow::Result;
use crate::{Tale, TaleEntry, TimelineEvent};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct StructuredStory {
    pub chapters: Vec<Chapter>,
    pub arc: StoryArc,
    pub key_moments: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Chapter {
    pub title: String,
    pub entries: Vec<String>, // Entry IDs
    pub summary: String,
    pub timespan: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StoryArc {
    pub setup: Vec<String>,      // Entry IDs
    pub rising_action: Vec<String>,
    pub climax: Vec<String>,
    pub falling_action: Vec<String>,
    pub resolution: Vec<String>,
}

pub struct StoryStructurer {}

impl StoryStructurer {
    pub fn new() -> Self {
        Self {}
    }
    
    pub async fn structure(&self, tale: &Tale) -> Result<StructuredStory> {
        tracing::info!("📝 Structuring tale with {} entries", tale.entries.len());
        
        // Sort entries by timestamp
        let mut sorted_entries = tale.entries.clone();
        sorted_entries.sort_by_key(|e| e.timestamp);
        
        // Identify story arc based on emotion and events
        let arc = self.identify_arc(&sorted_entries, &tale.timeline);
        
        // Create chapters from timeline
        let chapters = self.create_chapters(&sorted_entries, &tale.timeline);
        
        // Extract key moments
        let key_moments = self.extract_key_moments(&tale.timeline);
        
        Ok(StructuredStory {
            chapters,
            arc,
            key_moments,
        })
    }
    
    fn identify_arc(&self, entries: &[TaleEntry], timeline: &[TimelineEvent]) -> StoryArc {
        let total = entries.len();
        
        if total == 0 {
            return StoryArc {
                setup: vec![],
                rising_action: vec![],
                climax: vec![],
                falling_action: vec![],
                resolution: vec![],
            };
        }
        
        // Find climax - highest intensity event
        let climax_idx = timeline.iter()
            .enumerate()
            .max_by_key(|(_, e)| match e.significance {
                crate::EventSignificance::LifeChanging => 4,
                crate::EventSignificance::Critical => 3,
                crate::EventSignificance::Notable => 2,
                crate::EventSignificance::Minor => 1,
            })
            .map(|(i, _)| i)
            .unwrap_or(total / 2);
        
        // Divide into classic 5-part structure
        let setup_end = total / 5;
        let rising_end = climax_idx.min(total * 2 / 3);
        let falling_end = (climax_idx + (total - climax_idx) / 2).min(total);
        
        StoryArc {
            setup: entries[..setup_end].iter().map(|e| e.id.clone()).collect(),
            rising_action: entries[setup_end..rising_end].iter().map(|e| e.id.clone()).collect(),
            climax: if climax_idx < total {
                vec![entries[climax_idx].id.clone()]
            } else {
                vec![]
            },
            falling_action: if falling_end < total {
                entries[rising_end..falling_end].iter().map(|e| e.id.clone()).collect()
            } else {
                vec![]
            },
            resolution: if falling_end < total {
                entries[falling_end..].iter().map(|e| e.id.clone()).collect()
            } else {
                vec![]
            },
        }
    }
    
    fn create_chapters(&self, entries: &[TaleEntry], timeline: &[TimelineEvent]) -> Vec<Chapter> {
        let mut chapters = Vec::new();
        
        // Group by major events
        let mut current_chapter_entries = Vec::new();
        let mut chapter_num = 1;
        
        for (i, entry) in entries.iter().enumerate() {
            current_chapter_entries.push(entry.id.clone());
            
            // Check if this is a chapter-ending event
            let is_chapter_break = timeline.iter().any(|e| {
                (e.timestamp - entry.timestamp).num_hours().abs() < 1 &&
                matches!(e.significance, crate::EventSignificance::Critical | crate::EventSignificance::LifeChanging)
            });
            
            if is_chapter_break || i == entries.len() - 1 {
                let title = format!("Chapter {}", chapter_num);
                let summary = self.summarize_entries(&current_chapter_entries);
                
                chapters.push(Chapter {
                    title,
                    entries: current_chapter_entries.clone(),
                    summary,
                    timespan: "TODO: Calculate timespan".to_string(),
                });
                
                current_chapter_entries.clear();
                chapter_num += 1;
            }
        }
        
        if chapters.is_empty() {
            // Single chapter for small tales
            chapters.push(Chapter {
                title: "The Tale".to_string(),
                entries: entries.iter().map(|e| e.id.clone()).collect(),
                summary: "A trucker's experience on the road".to_string(),
                timespan: "One journey".to_string(),
            });
        }
        
        chapters
    }
    
    fn extract_key_moments(&self, timeline: &[TimelineEvent]) -> Vec<String> {
        timeline.iter()
            .filter(|e| !matches!(e.significance, crate::EventSignificance::Minor))
            .map(|e| e.description.clone())
            .collect()
    }
    
    fn summarize_entries(&self, _entry_ids: &[String]) -> String {
        // TODO: Generate AI summary of chapter
        "A segment of the journey".to_string()
    }
}
