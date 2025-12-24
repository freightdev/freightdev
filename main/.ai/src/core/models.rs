use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Conversation {
    pub id: Uuid,
    pub source: ConversationSource,
    pub model: String,
    pub session_id: String,
    pub timestamp: DateTime<Utc>,
    pub title: Option<String>,
    pub exchanges: Vec<Exchange>,
    pub metadata: ConversationMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ConversationSource {
    ChatGPT,
    Claude,
    Other(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Exchange {
    pub question: Message,
    pub answer: Message,
    pub metadata: ExchangeMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub text: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExchangeMetadata {
    pub topics: Vec<String>,
    pub entities: Vec<Entity>,
    pub intent: Option<String>,
    pub projects_mentioned: Vec<String>,
    pub sentiment: Option<String>,
    pub has_code: bool,
    pub has_urls: bool,
}

impl Default for ExchangeMetadata {
    fn default() -> Self {
        Self {
            topics: Vec::new(),
            entities: Vec::new(),
            intent: None,
            projects_mentioned: Vec::new(),
            sentiment: None,
            has_code: false,
            has_urls: false,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationMetadata {
    pub total_exchanges: usize,
    pub topics: Vec<String>,
    pub entities: Vec<Entity>,
    pub patterns: Vec<Pattern>,
    pub related_conversations: Vec<Uuid>,
    pub tags: Vec<String>,
}

impl Default for ConversationMetadata {
    fn default() -> Self {
        Self {
            total_exchanges: 0,
            topics: Vec::new(),
            entities: Vec::new(),
            patterns: Vec::new(),
            related_conversations: Vec::new(),
            tags: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entity {
    pub entity_type: EntityType,
    pub value: String,
    pub confidence: f32,
    pub first_seen: DateTime<Utc>,
    pub count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum EntityType {
    Project,
    Technology,
    Person,
    Concept,
    FilePath,
    Command,
    URL,
    Code,
    Other(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Pattern {
    pub pattern_type: PatternType,
    pub description: String,
    pub occurrences: Vec<Uuid>, // Exchange IDs
    pub confidence: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PatternType {
    LearningProgression,
    ProjectLifecycle,
    RecurringProblem,
    DesignEvolution,
    InterestShift,
    BuildRequest,
    Todo,
    UnfinishedIdea,
}

// Analysis requests and responses

#[derive(Debug, Deserialize)]
pub struct ParseRequest {
    pub source: ConversationSource,
    pub file_path: Option<String>,
    pub content: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ParseResponse {
    pub conversations: Vec<Conversation>,
    pub total_parsed: usize,
    pub errors: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct AnalyzeRequest {
    pub conversation_ids: Option<Vec<Uuid>>,
    pub passes: Vec<AnalysisPass>,
    pub depth: AnalysisDepth,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AnalysisPass {
    EntityExtraction,
    TopicModeling,
    IntentDetection,
    PatternAnalysis,
    CrossReferencing,
    KnowledgeSynthesis,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AnalysisDepth {
    Quick,
    Standard,
    Thorough,
    Deep,
}

#[derive(Debug, Serialize)]
pub struct AnalyzeResponse {
    pub analyzed: usize,
    pub entities_found: usize,
    pub patterns_found: usize,
    pub topics_found: usize,
    pub summary: String,
}

#[derive(Debug, Deserialize)]
pub struct QueryRequest {
    pub query: String,
    pub filters: Option<QueryFilters>,
    pub limit: Option<usize>,
}

#[derive(Debug, Deserialize)]
pub struct QueryFilters {
    pub source: Option<ConversationSource>,
    pub date_range: Option<DateRange>,
    pub topics: Option<Vec<String>>,
    pub projects: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct DateRange {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct QueryResponse {
    pub conversations: Vec<Conversation>,
    pub total_found: usize,
    pub query_time_ms: u64,
}

#[derive(Debug, Serialize)]
pub struct StatsResponse {
    pub total_conversations: usize,
    pub total_exchanges: usize,
    pub unique_topics: usize,
    pub unique_entities: usize,
    pub sources: Vec<SourceStats>,
    pub top_topics: Vec<(String, usize)>,
    pub top_projects: Vec<(String, usize)>,
}

#[derive(Debug, Serialize)]
pub struct SourceStats {
    pub source: ConversationSource,
    pub count: usize,
    pub date_range: (DateTime<Utc>, DateTime<Utc>),
}
