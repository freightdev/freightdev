use crate::models::*;
use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;
use uuid::Uuid;

pub struct ConversationStorage {
    db: Surreal<Client>,
}

impl ConversationStorage {
    pub async fn new(url: &str, namespace: &str, database: &str, username: &str, password: &str) -> Result<Self> {
        let db = Surreal::new::<Ws>(url).await?;

        db.signin(Root {
            username,
            password,
        })
        .await?;

        db.use_ns(namespace).use_db(database).await?;

        // Initialize schema
        Self::init_schema(&db).await?;

        Ok(Self { db })
    }

    async fn init_schema(db: &Surreal<Client>) -> Result<()> {
        // Create tables and indexes
        db.query(
            r#"
            DEFINE TABLE conversations SCHEMAFULL;
            DEFINE FIELD id ON conversations TYPE string;
            DEFINE FIELD source ON conversations TYPE string;
            DEFINE FIELD model ON conversations TYPE string;
            DEFINE FIELD session_id ON conversations TYPE string;
            DEFINE FIELD timestamp ON conversations TYPE datetime;
            DEFINE FIELD title ON conversations TYPE option<string>;
            DEFINE FIELD exchanges ON conversations TYPE array;
            DEFINE FIELD metadata ON conversations TYPE object;

            DEFINE INDEX idx_source ON conversations FIELDS source;
            DEFINE INDEX idx_timestamp ON conversations FIELDS timestamp;
            DEFINE INDEX idx_session ON conversations FIELDS session_id;

            DEFINE TABLE entities SCHEMAFULL;
            DEFINE FIELD entity_type ON entities TYPE string;
            DEFINE FIELD value ON entities TYPE string;
            DEFINE FIELD confidence ON entities TYPE float;
            DEFINE FIELD first_seen ON entities TYPE datetime;
            DEFINE FIELD count ON entities TYPE int;
            DEFINE FIELD conversations ON entities TYPE array;

            DEFINE INDEX idx_entity_type ON entities FIELDS entity_type;
            DEFINE INDEX idx_entity_value ON entities FIELDS value;

            DEFINE TABLE patterns SCHEMAFULL;
            DEFINE FIELD pattern_type ON patterns TYPE string;
            DEFINE FIELD description ON patterns TYPE string;
            DEFINE FIELD occurrences ON patterns TYPE array;
            DEFINE FIELD confidence ON patterns TYPE float;

            DEFINE INDEX idx_pattern_type ON patterns FIELDS pattern_type;
            "#,
        )
        .await?;

        Ok(())
    }

    pub async fn store_conversation(&self, conversation: &Conversation) -> Result<()> {
        let _: Option<Conversation> = self
            .db
            .create(("conversations", conversation.id.to_string()))
            .content(conversation.clone())
            .await
            .context("Failed to store conversation")?;

        // Store entities separately for easier querying
        for entity in &conversation.metadata.entities {
            self.store_entity(entity, conversation.id).await?;
        }

        Ok(())
    }

    pub async fn store_conversations(&self, conversations: &[Conversation]) -> Result<()> {
        for conv in conversations {
            self.store_conversation(conv).await?;
        }
        Ok(())
    }

    async fn store_entity(&self, entity: &Entity, _conversation_id: Uuid) -> Result<()> {
        // Check if entity already exists
        let query = format!(
            "SELECT * FROM entities WHERE value = '{}' AND entity_type = '{:?}'",
            entity.value, entity.entity_type
        );

        let mut result = self.db.query(query).await?;
        let existing: Option<Entity> = result.take(0)?;

        if let Some(mut existing_entity) = existing {
            // Update count and add conversation reference
            existing_entity.count += 1;
            // In a real implementation, you'd track conversation references
            let entity_to_update = existing_entity.clone();
            self.db
                .update::<Option<Entity>>(("entities", entity.value.clone()))
                .content(entity_to_update)
                .await?;
        } else {
            // Create new entity
            let _: Option<Entity> = self
                .db
                .create(("entities", entity.value.clone()))
                .content(entity.clone())
                .await?;
        }

        Ok(())
    }

    pub async fn get_conversation(&self, id: Uuid) -> Result<Option<Conversation>> {
        let conv: Option<Conversation> = self
            .db
            .select(("conversations", id.to_string()))
            .await?;
        Ok(conv)
    }

    pub async fn query_conversations(&self, request: &QueryRequest) -> Result<QueryResponse> {
        let start = std::time::Instant::now();

        let mut query = String::from("SELECT * FROM conversations WHERE 1=1");

        if let Some(filters) = &request.filters {
            if let Some(ref source) = filters.source {
                query.push_str(&format!(" AND source = '{:?}'", source));
            }

            if let Some(ref date_range) = filters.date_range {
                query.push_str(&format!(
                    " AND timestamp >= '{}' AND timestamp <= '{}'",
                    date_range.start.to_rfc3339(),
                    date_range.end.to_rfc3339()
                ));
            }

            if let Some(ref topics) = filters.topics {
                if !topics.is_empty() {
                    let topics_str = topics.join("','");
                    query.push_str(&format!(" AND metadata.topics CONTAINSANY ['{}']", topics_str));
                }
            }
        }

        query.push_str(" ORDER BY timestamp DESC");

        if let Some(limit) = request.limit {
            query.push_str(&format!(" LIMIT {}", limit));
        }

        let mut result = self.db.query(query).await?;
        let conversations: Vec<Conversation> = result.take(0)?;

        let elapsed = start.elapsed();

        Ok(QueryResponse {
            total_found: conversations.len(),
            conversations,
            query_time_ms: elapsed.as_millis() as u64,
        })
    }

    pub async fn get_stats(&self) -> Result<StatsResponse> {
        // Get total conversations
        let mut result = self.db.query("SELECT count() FROM conversations GROUP ALL").await?;
        let total_conversations: Option<i64> = result.take((0, "count"))?;

        // Get total exchanges
        let mut result = self
            .db
            .query("SELECT math::sum(metadata.total_exchanges) FROM conversations GROUP ALL")
            .await?;
        let total_exchanges: Option<i64> = result.take(0)?;

        // Get unique topics
        let mut result = self
            .db
            .query("SELECT array::distinct(array::flatten(metadata.topics)) FROM conversations")
            .await?;
        let topics: Vec<Vec<String>> = result.take(0)?;
        let unique_topics = topics.first().map(|t| t.len()).unwrap_or(0);

        // Get unique entities
        let mut result = self.db.query("SELECT count() FROM entities GROUP ALL").await?;
        let unique_entities: Option<i64> = result.take((0, "count"))?;

        // Get top topics (simplified)
        let top_topics = vec![]; // Would require more complex aggregation

        // Get top projects
        let top_projects = vec![];

        Ok(StatsResponse {
            total_conversations: total_conversations.unwrap_or(0) as usize,
            total_exchanges: total_exchanges.unwrap_or(0) as usize,
            unique_topics,
            unique_entities: unique_entities.unwrap_or(0) as usize,
            sources: vec![],
            top_topics,
            top_projects,
        })
    }

    pub async fn search_by_text(&self, text: &str, limit: usize) -> Result<Vec<Conversation>> {
        let query = format!(
            "SELECT * FROM conversations WHERE
             string::contains(string::lowercase(title), '{}') OR
             exchanges.*.question.text CONTAINS '{}' OR
             exchanges.*.answer.text CONTAINS '{}'
             LIMIT {}",
            text.to_lowercase(),
            text,
            text,
            limit
        );

        let mut result = self.db.query(query).await?;
        let conversations: Vec<Conversation> = result.take(0)?;
        Ok(conversations)
    }

    pub async fn get_entities_by_type(&self, entity_type: EntityType) -> Result<Vec<Entity>> {
        let query = format!("SELECT * FROM entities WHERE entity_type = '{:?}' ORDER BY count DESC", entity_type);
        let mut result = self.db.query(query).await?;
        let entities: Vec<Entity> = result.take(0)?;
        Ok(entities)
    }

    pub async fn get_conversations_by_entity(&self, entity_value: &str) -> Result<Vec<Conversation>> {
        let query = format!(
            "SELECT * FROM conversations WHERE metadata.entities.*.value CONTAINS '{}'",
            entity_value
        );
        let mut result = self.db.query(query).await?;
        let conversations: Vec<Conversation> = result.take(0)?;
        Ok(conversations)
    }
}
