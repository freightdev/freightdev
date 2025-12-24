use crate::models::*;
use crate::entities::EntityExtractor;
use crate::patterns::PatternDetector;
use anyhow::Result;
use tracing::{info, debug};
use uuid::Uuid;

pub struct ConversationAnalyzer {
    entity_extractor: EntityExtractor,
    pattern_detector: PatternDetector,
}

impl ConversationAnalyzer {
    pub fn new() -> Self {
        Self {
            entity_extractor: EntityExtractor::new(),
            pattern_detector: PatternDetector::new(),
        }
    }

    /// Run multi-pass analysis on conversations
    pub async fn analyze(
        &self,
        conversations: &mut [Conversation],
        request: &AnalyzeRequest,
    ) -> Result<AnalyzeResponse> {
        let start = std::time::Instant::now();
        let mut entities_found = 0;
        let mut patterns_found = 0;
        let mut topics_found = 0;

        info!(
            "Starting analysis of {} conversations with {} passes at {:?} depth",
            conversations.len(),
            request.passes.len(),
            request.depth
        );

        for pass in &request.passes {
            match pass {
                AnalysisPass::EntityExtraction => {
                    debug!("Running EntityExtraction pass");
                    entities_found += self.entity_extraction_pass(conversations).await?;
                }
                AnalysisPass::TopicModeling => {
                    debug!("Running TopicModeling pass");
                    topics_found += self.topic_modeling_pass(conversations).await?;
                }
                AnalysisPass::IntentDetection => {
                    debug!("Running IntentDetection pass");
                    self.intent_detection_pass(conversations).await?;
                }
                AnalysisPass::PatternAnalysis => {
                    debug!("Running PatternAnalysis pass");
                    patterns_found += self.pattern_analysis_pass(conversations).await?;
                }
                AnalysisPass::CrossReferencing => {
                    debug!("Running CrossReferencing pass");
                    self.cross_referencing_pass(conversations).await?;
                }
                AnalysisPass::KnowledgeSynthesis => {
                    debug!("Running KnowledgeSynthesis pass");
                    self.knowledge_synthesis_pass(conversations).await?;
                }
            }
        }

        let elapsed = start.elapsed();
        info!("Analysis completed in {:?}", elapsed);

        Ok(AnalyzeResponse {
            analyzed: conversations.len(),
            entities_found,
            patterns_found,
            topics_found,
            summary: self.generate_summary(conversations, entities_found, patterns_found, topics_found),
        })
    }

    /// Pass 1: Entity Extraction
    async fn entity_extraction_pass(&self, conversations: &mut [Conversation]) -> Result<usize> {
        let mut total_entities = 0;

        for conv in conversations.iter_mut() {
            let mut all_entities = Vec::new();

            for exchange in &mut conv.exchanges {
                // Extract from question
                let q_entities = self.entity_extractor.extract(&exchange.question.text);
                // Extract from answer
                let a_entities = self.entity_extractor.extract(&exchange.answer.text);

                let mut exchange_entities = Vec::new();
                exchange_entities.extend(q_entities.clone());
                exchange_entities.extend(a_entities);

                exchange.metadata.entities = exchange_entities.clone();
                all_entities.extend(exchange_entities);

                // Set flags
                exchange.metadata.has_code = self.has_code_blocks(&exchange.answer.text);
                exchange.metadata.has_urls = self.has_urls(&exchange.answer.text);
            }

            // Deduplicate and aggregate entities at conversation level
            conv.metadata.entities = self.aggregate_entities(all_entities);
            total_entities += conv.metadata.entities.len();
        }

        Ok(total_entities)
    }

    /// Pass 2: Topic Modeling
    async fn topic_modeling_pass(&self, conversations: &mut [Conversation]) -> Result<usize> {
        let mut total_topics = 0;

        for conv in conversations.iter_mut() {
            let mut all_topics = Vec::new();

            for exchange in &mut conv.exchanges {
                let topics = self.extract_topics(&exchange.question.text, &exchange.answer.text);
                exchange.metadata.topics = topics.clone();
                all_topics.extend(topics);
            }

            // Deduplicate topics
            all_topics.sort();
            all_topics.dedup();
            conv.metadata.topics = all_topics.clone();
            total_topics += all_topics.len();
        }

        Ok(total_topics)
    }

    /// Pass 3: Intent Detection
    async fn intent_detection_pass(&self, conversations: &mut [Conversation]) -> Result<()> {
        for conv in conversations.iter_mut() {
            for exchange in &mut conv.exchanges {
                exchange.metadata.intent = Some(self.detect_intent(&exchange.question.text));
            }
        }
        Ok(())
    }

    /// Pass 4: Pattern Analysis
    async fn pattern_analysis_pass(&self, conversations: &mut [Conversation]) -> Result<usize> {
        let patterns = self.pattern_detector.detect_patterns(conversations);
        let pattern_count = patterns.len();

        // Distribute patterns back to conversations
        for conv in conversations.iter_mut() {
            conv.metadata.patterns = patterns
                .iter()
                .filter(|p| {
                    p.occurrences
                        .iter()
                        .any(|_occ_id| conv.exchanges.iter().any(|_| true)) // Simplified
                })
                .cloned()
                .collect();
        }

        Ok(pattern_count)
    }

    /// Pass 5: Cross-Referencing
    async fn cross_referencing_pass(&self, conversations: &mut [Conversation]) -> Result<()> {
        // Build entity -> conversation index with IDs
        let mut entity_index: std::collections::HashMap<String, Vec<Uuid>> =
            std::collections::HashMap::new();

        for conv in conversations.iter() {
            for entity in &conv.metadata.entities {
                entity_index
                    .entry(entity.value.clone())
                    .or_default()
                    .push(conv.id);
            }
        }

        // Cross-reference conversations with shared entities
        for conv in conversations.iter_mut() {
            let mut related = std::collections::HashSet::new();

            for entity in &conv.metadata.entities {
                if let Some(related_ids) = entity_index.get(&entity.value) {
                    for &related_id in related_ids {
                        if related_id != conv.id {
                            related.insert(related_id);
                        }
                    }
                }
            }

            conv.metadata.related_conversations = related.into_iter().collect();
        }

        Ok(())
    }

    /// Pass 6: Knowledge Synthesis
    async fn knowledge_synthesis_pass(&self, conversations: &mut [Conversation]) -> Result<()> {
        // Add tags based on content analysis
        for conv in conversations.iter_mut() {
            let mut tags = Vec::new();

            // Tag by entity types
            if conv.metadata.entities.iter().any(|e| matches!(e.entity_type, EntityType::Project)) {
                tags.push("project-discussion".to_string());
            }
            if conv.metadata.entities.iter().any(|e| matches!(e.entity_type, EntityType::Technology)) {
                tags.push("technical".to_string());
            }

            // Tag by patterns
            if conv.metadata.patterns.iter().any(|p| matches!(p.pattern_type, PatternType::BuildRequest)) {
                tags.push("build-request".to_string());
            }
            if conv.metadata.patterns.iter().any(|p| matches!(p.pattern_type, PatternType::Todo)) {
                tags.push("has-todos".to_string());
            }

            // Tag by content
            let has_code = conv.exchanges.iter().any(|e| e.metadata.has_code);
            if has_code {
                tags.push("contains-code".to_string());
            }

            conv.metadata.tags = tags;
        }

        Ok(())
    }

    // Helper methods

    fn aggregate_entities(&self, entities: Vec<Entity>) -> Vec<Entity> {
        let mut entity_map: std::collections::HashMap<String, Entity> = std::collections::HashMap::new();

        for entity in entities {
            entity_map
                .entry(entity.value.clone())
                .and_modify(|e| e.count += 1)
                .or_insert(entity);
        }

        let mut result: Vec<_> = entity_map.into_values().collect();
        result.sort_by(|a, b| b.count.cmp(&a.count));
        result
    }

    fn extract_topics(&self, question: &str, answer: &str) -> Vec<String> {
        let mut topics = Vec::new();
        let text = format!("{} {}", question, answer).to_lowercase();

        // Simple keyword-based topic extraction
        let topic_keywords = vec![
            ("rust", "Rust Programming"),
            ("python", "Python"),
            ("database", "Database"),
            ("api", "API Development"),
            ("agent", "AI Agents"),
            ("docker", "Docker/Containers"),
            ("kubernetes", "Kubernetes"),
            ("security", "Security"),
            ("performance", "Performance"),
            ("testing", "Testing"),
            ("deployment", "Deployment"),
            ("design", "System Design"),
            ("architecture", "Architecture"),
            ("frontend", "Frontend"),
            ("backend", "Backend"),
        ];

        for (keyword, topic) in topic_keywords {
            if text.contains(keyword) {
                topics.push(topic.to_string());
            }
        }

        topics
    }

    fn detect_intent(&self, question: &str) -> String {
        let lower = question.to_lowercase();

        if lower.contains("how do i") || lower.contains("how to") || lower.contains("how can") {
            "learn".to_string()
        } else if lower.contains("build") || lower.contains("create") || lower.contains("make") {
            "build".to_string()
        } else if lower.contains("fix") || lower.contains("debug") || lower.contains("error") {
            "debug".to_string()
        } else if lower.contains("explain") || lower.contains("what is") || lower.contains("why") {
            "understand".to_string()
        } else if lower.contains("optimize") || lower.contains("improve") || lower.contains("better") {
            "optimize".to_string()
        } else {
            "general".to_string()
        }
    }

    fn has_code_blocks(&self, text: &str) -> bool {
        text.contains("```") || text.contains("    ") && text.lines().count() > 3
    }

    fn has_urls(&self, text: &str) -> bool {
        text.contains("http://") || text.contains("https://")
    }

    fn generate_summary(&self, conversations: &[Conversation], entities: usize, patterns: usize, topics: usize) -> String {
        format!(
            "Analyzed {} conversations with {} total exchanges. Found {} unique entities, {} patterns, and {} topics.",
            conversations.len(),
            conversations.iter().map(|c| c.metadata.total_exchanges).sum::<usize>(),
            entities,
            patterns,
            topics
        )
    }
}
