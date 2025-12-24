use crate::models::{Conversation, Pattern, PatternType};
use uuid::Uuid;

pub struct PatternDetector;

impl PatternDetector {
    pub fn new() -> Self {
        Self
    }

    pub fn detect_patterns(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();

        // Detect various pattern types
        patterns.extend(self.detect_learning_progressions(conversations));
        patterns.extend(self.detect_project_lifecycles(conversations));
        patterns.extend(self.detect_recurring_problems(conversations));
        patterns.extend(self.detect_design_evolutions(conversations));
        patterns.extend(self.detect_todos(conversations));
        patterns.extend(self.detect_build_requests(conversations));
        patterns.extend(self.detect_unfinished_ideas(conversations));

        patterns
    }

    fn detect_learning_progressions(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let mut tech_timeline: std::collections::HashMap<String, Vec<(chrono::DateTime<chrono::Utc>, Uuid)>> =
            std::collections::HashMap::new();

        // Build timeline of technology mentions
        for conv in conversations {
            for entity in &conv.metadata.entities {
                if matches!(entity.entity_type, crate::models::EntityType::Technology) {
                    tech_timeline
                        .entry(entity.value.clone())
                        .or_default()
                        .push((conv.timestamp, conv.id));
                }
            }
        }

        // Look for technologies with multiple mentions over time
        for (tech, mut timeline) in tech_timeline {
            if timeline.len() >= 3 {
                timeline.sort_by_key(|t| t.0);
                let time_span = timeline.last().unwrap().0 - timeline.first().unwrap().0;

                // If mentions span more than a week, it's a learning progression
                if time_span.num_days() > 7 {
                    patterns.push(Pattern {
                        pattern_type: PatternType::LearningProgression,
                        description: format!("Learning progression in {}: {} conversations over {} days",
                            tech, timeline.len(), time_span.num_days()),
                        occurrences: timeline.iter().map(|t| t.1).collect(),
                        confidence: 0.8,
                    });
                }
            }
        }

        patterns
    }

    fn detect_project_lifecycles(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let mut project_timeline: std::collections::HashMap<String, Vec<(chrono::DateTime<chrono::Utc>, Uuid, String)>> =
            std::collections::HashMap::new();

        // Build timeline of project mentions with intent
        for conv in conversations {
            for entity in &conv.metadata.entities {
                if matches!(entity.entity_type, crate::models::EntityType::Project) {
                    // Get dominant intent from exchanges
                    let intents: Vec<String> = conv
                        .exchanges
                        .iter()
                        .filter_map(|e| e.metadata.intent.clone())
                        .collect();
                    let intent = intents.first().cloned().unwrap_or_else(|| "general".to_string());

                    project_timeline
                        .entry(entity.value.clone())
                        .or_default()
                        .push((conv.timestamp, conv.id, intent));
                }
            }
        }

        // Look for project lifecycle patterns (idea -> design -> build -> iterate)
        for (project, mut timeline) in project_timeline {
            if timeline.len() >= 4 {
                timeline.sort_by_key(|t| t.0);

                let lifecycle_stages = vec!["understand", "build", "debug", "optimize"];
                let intents: Vec<String> = timeline.iter().map(|t| t.2.clone()).collect();

                // Check if intents match lifecycle progression
                let matches_lifecycle = lifecycle_stages.iter().any(|stage| intents.contains(&stage.to_string()));

                if matches_lifecycle {
                    patterns.push(Pattern {
                        pattern_type: PatternType::ProjectLifecycle,
                        description: format!("Project lifecycle for {}: {} conversations from idea to implementation",
                            project, timeline.len()),
                        occurrences: timeline.iter().map(|t| t.1).collect(),
                        confidence: 0.75,
                    });
                }
            }
        }

        patterns
    }

    fn detect_recurring_problems(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let mut problem_keywords: std::collections::HashMap<String, Vec<Uuid>> =
            std::collections::HashMap::new();

        let error_indicators = vec![
            "error", "bug", "issue", "problem", "fail", "broken", "not working", "crash"
        ];

        for conv in conversations {
            for exchange in &conv.exchanges {
                let lower = exchange.question.text.to_lowercase();

                for indicator in &error_indicators {
                    if lower.contains(indicator) {
                        problem_keywords
                            .entry(indicator.to_string())
                            .or_default()
                            .push(conv.id);
                        break;
                    }
                }
            }
        }

        // Find recurring problem types
        for (keyword, occurrences) in problem_keywords {
            if occurrences.len() >= 3 {
                patterns.push(Pattern {
                    pattern_type: PatternType::RecurringProblem,
                    description: format!("Recurring problem pattern: '{}' appears in {} conversations",
                        keyword, occurrences.len()),
                    occurrences,
                    confidence: 0.7,
                });
            }
        }

        patterns
    }

    fn detect_design_evolutions(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let design_keywords = vec![
            "design", "architecture", "refactor", "redesign", "change approach", "better way"
        ];

        let mut design_discussions: Vec<Uuid> = Vec::new();

        for conv in conversations {
            for exchange in &conv.exchanges {
                let text = format!("{} {}", exchange.question.text, exchange.answer.text).to_lowercase();

                if design_keywords.iter().any(|kw| text.contains(kw)) {
                    design_discussions.push(conv.id);
                    break;
                }
            }
        }

        if design_discussions.len() >= 3 {
            patterns.push(Pattern {
                pattern_type: PatternType::DesignEvolution,
                description: format!("Design evolution pattern: {} architecture/design discussions",
                    design_discussions.len()),
                occurrences: design_discussions,
                confidence: 0.75,
            });
        }

        patterns
    }

    fn detect_todos(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let todo_patterns = vec!["todo", "to do", "need to", "should", "must", "have to"];

        for conv in conversations {
            let mut todo_exchanges = Vec::new();

            for exchange in &conv.exchanges {
                let text = format!("{} {}", exchange.question.text, exchange.answer.text).to_lowercase();

                if todo_patterns.iter().any(|pat| text.contains(pat)) {
                    // Check if it's actually a TODO (not just casual usage)
                    if text.contains("next") || text.contains("later") || text.contains("implement")
                        || text.contains("add") || text.contains("fix") {
                        todo_exchanges.push(conv.id);
                        break;
                    }
                }
            }

            if !todo_exchanges.is_empty() {
                patterns.push(Pattern {
                    pattern_type: PatternType::Todo,
                    description: format!("TODO items found in conversation"),
                    occurrences: todo_exchanges,
                    confidence: 0.8,
                });
            }
        }

        patterns
    }

    fn detect_build_requests(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let build_keywords = vec![
            "build", "create", "make", "implement", "develop", "write", "code"
        ];

        for conv in conversations {
            for exchange in &conv.exchanges {
                let lower = exchange.question.text.to_lowercase();

                // Check if question is a build request
                if build_keywords.iter().any(|kw| lower.contains(kw)) {
                    // Verify it's an imperative/request
                    if lower.contains("can you") || lower.contains("could you")
                        || lower.contains("help me") || lower.contains("i need")
                        || lower.starts_with("build") || lower.starts_with("create") {
                        patterns.push(Pattern {
                            pattern_type: PatternType::BuildRequest,
                            description: format!("Build request: {}",
                                exchange.question.text.chars().take(60).collect::<String>()),
                            occurrences: vec![conv.id],
                            confidence: 0.85,
                        });
                        break;
                    }
                }
            }
        }

        patterns
    }

    fn detect_unfinished_ideas(&self, conversations: &[Conversation]) -> Vec<Pattern> {
        let mut patterns = Vec::new();
        let continuation_indicators = vec![
            "later", "next time", "eventually", "in the future", "come back to",
            "for now", "temporary", "placeholder"
        ];

        for conv in conversations {
            for exchange in &conv.exchanges {
                let lower = exchange.answer.text.to_lowercase();

                if continuation_indicators.iter().any(|ind| lower.contains(ind)) {
                    patterns.push(Pattern {
                        pattern_type: PatternType::UnfinishedIdea,
                        description: format!("Unfinished idea: conversation ended with future plans"),
                        occurrences: vec![conv.id],
                        confidence: 0.7,
                    });
                    break;
                }
            }
        }

        patterns
    }
}
