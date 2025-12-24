use crate::models::{Entity, EntityType};
use chrono::Utc;
use regex::Regex;

pub struct EntityExtractor {
    file_path_regex: Regex,
    url_regex: Regex,
    command_regex: Regex,
}

impl EntityExtractor {
    pub fn new() -> Self {
        Self {
            file_path_regex: Regex::new(r"(?:/|~/|\./)[\w\-\./_]+\.\w+").unwrap(),
            url_regex: Regex::new(r"https?://[^\s]+").unwrap(),
            command_regex: Regex::new(r"`([^`]+)`").unwrap(),
        }
    }

    pub fn extract(&self, text: &str) -> Vec<Entity> {
        let mut entities = Vec::new();

        // Extract file paths
        for capture in self.file_path_regex.captures_iter(text) {
            if let Some(path) = capture.get(0) {
                entities.push(Entity {
                    entity_type: EntityType::FilePath,
                    value: path.as_str().to_string(),
                    confidence: 0.9,
                    first_seen: Utc::now(),
                    count: 1,
                });
            }
        }

        // Extract URLs
        for capture in self.url_regex.captures_iter(text) {
            if let Some(url) = capture.get(0) {
                entities.push(Entity {
                    entity_type: EntityType::URL,
                    value: url.as_str().to_string(),
                    confidence: 1.0,
                    first_seen: Utc::now(),
                    count: 1,
                });
            }
        }

        // Extract commands/code
        for capture in self.command_regex.captures_iter(text) {
            if let Some(cmd) = capture.get(1) {
                let cmd_str = cmd.as_str();
                if self.looks_like_command(cmd_str) {
                    entities.push(Entity {
                        entity_type: EntityType::Command,
                        value: cmd_str.to_string(),
                        confidence: 0.8,
                        first_seen: Utc::now(),
                        count: 1,
                    });
                }
            }
        }

        // Extract project names
        entities.extend(self.extract_projects(text));

        // Extract technologies
        entities.extend(self.extract_technologies(text));

        // Extract concepts
        entities.extend(self.extract_concepts(text));

        entities
    }

    fn extract_projects(&self, text: &str) -> Vec<Entity> {
        let mut projects = Vec::new();
        let project_indicators = vec![
            "codriver",
            "coordinator",
            "data-collector",
            "web-scraper",
            "documentation-agent",
        ];

        let lower = text.to_lowercase();
        for project in project_indicators {
            if lower.contains(project) {
                projects.push(Entity {
                    entity_type: EntityType::Project,
                    value: project.to_string(),
                    confidence: 0.85,
                    first_seen: Utc::now(),
                    count: 1,
                });
            }
        }

        // Look for patterns like "my-project" or "the FooBar project"
        let project_pattern = Regex::new(r"\b([a-z]+[-_][a-z]+(?:[-_][a-z]+)*)\b").unwrap();
        for capture in project_pattern.captures_iter(&lower) {
            if let Some(name) = capture.get(1) {
                let name_str = name.as_str();
                // Filter out common phrases that aren't projects
                if name_str.len() > 5
                    && !name_str.contains("can")
                    && !name_str.contains("will")
                    && !name_str.contains("would")
                {
                    projects.push(Entity {
                        entity_type: EntityType::Project,
                        value: name_str.to_string(),
                        confidence: 0.6,
                        first_seen: Utc::now(),
                        count: 1,
                    });
                }
            }
        }

        projects
    }

    fn extract_technologies(&self, text: &str) -> Vec<Entity> {
        let mut technologies = Vec::new();
        let tech_keywords = vec![
            "rust",
            "python",
            "javascript",
            "typescript",
            "node.js",
            "react",
            "vue",
            "docker",
            "kubernetes",
            "postgres",
            "postgresql",
            "mysql",
            "mongodb",
            "redis",
            "kafka",
            "rabbitmq",
            "nginx",
            "apache",
            "aws",
            "azure",
            "gcp",
            "terraform",
            "ansible",
            "jenkins",
            "github actions",
            "gitlab ci",
            "surrealdb",
            "axum",
            "tokio",
            "actix",
            "flask",
            "django",
            "fastapi",
            "express",
            "grpc",
            "graphql",
            "rest api",
            "websocket",
            "llm",
            "gpt",
            "claude",
            "ollama",
        ];

        let lower = text.to_lowercase();
        for tech in tech_keywords {
            if lower.contains(tech) {
                technologies.push(Entity {
                    entity_type: EntityType::Technology,
                    value: tech.to_string(),
                    confidence: 0.9,
                    first_seen: Utc::now(),
                    count: 1,
                });
            }
        }

        technologies
    }

    fn extract_concepts(&self, text: &str) -> Vec<Entity> {
        let mut concepts = Vec::new();
        let concept_keywords = vec![
            "microservices",
            "agent",
            "ai agent",
            "coordinator",
            "architecture",
            "design pattern",
            "state machine",
            "event driven",
            "message queue",
            "api gateway",
            "load balancer",
            "caching",
            "authentication",
            "authorization",
            "jwt",
            "oauth",
            "rate limiting",
            "circuit breaker",
            "saga pattern",
            "cqrs",
            "event sourcing",
            "domain driven design",
            "clean architecture",
            "hexagonal architecture",
            "test driven development",
            "continuous integration",
            "continuous deployment",
        ];

        let lower = text.to_lowercase();
        for concept in concept_keywords {
            if lower.contains(concept) {
                concepts.push(Entity {
                    entity_type: EntityType::Concept,
                    value: concept.to_string(),
                    confidence: 0.85,
                    first_seen: Utc::now(),
                    count: 1,
                });
            }
        }

        concepts
    }

    fn looks_like_command(&self, text: &str) -> bool {
        let command_indicators = vec!["cargo", "npm", "git", "docker", "kubectl", "cd", "ls", "cat", "grep"];

        let words: Vec<&str> = text.split_whitespace().collect();
        if words.is_empty() {
            return false;
        }

        command_indicators.contains(&words[0])
    }
}
