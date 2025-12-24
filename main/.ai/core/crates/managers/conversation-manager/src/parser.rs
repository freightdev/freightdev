use crate::models::*;
use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use scraper::{Html, Selector};
use std::fs;
use uuid::Uuid;

pub struct ConversationParser;

impl ConversationParser {
    pub fn new() -> Self {
        Self
    }

    /// Parse conversations from file or content
    pub async fn parse(&self, request: ParseRequest) -> Result<ParseResponse> {
        let content = if let Some(path) = request.file_path {
            fs::read_to_string(&path)
                .with_context(|| format!("Failed to read file: {}", path))?
        } else if let Some(content) = request.content {
            content
        } else {
            anyhow::bail!("Either file_path or content must be provided");
        };

        match request.source {
            ConversationSource::ChatGPT => self.parse_chatgpt(&content),
            ConversationSource::Claude => self.parse_claude(&content),
            ConversationSource::Other(ref source) => {
                anyhow::bail!("Unsupported source: {}", source)
            }
        }
    }

    /// Parse ChatGPT HTML export format
    fn parse_chatgpt(&self, content: &str) -> Result<ParseResponse> {
        let mut conversations = Vec::new();
        let mut errors = Vec::new();

        // Try parsing as HTML first
        if content.trim_start().starts_with('<') {
            match self.parse_chatgpt_html(content) {
                Ok(convos) => conversations.extend(convos),
                Err(e) => errors.push(format!("HTML parse error: {}", e)),
            }
        }

        // Try parsing as JSON
        if content.trim_start().starts_with('{') || content.trim_start().starts_with('[') {
            match self.parse_chatgpt_json(content) {
                Ok(convos) => conversations.extend(convos),
                Err(e) => errors.push(format!("JSON parse error: {}", e)),
            }
        }

        Ok(ParseResponse {
            total_parsed: conversations.len(),
            conversations,
            errors,
        })
    }

    /// Parse ChatGPT HTML format
    fn parse_chatgpt_html(&self, html: &str) -> Result<Vec<Conversation>> {
        let document = Html::parse_document(html);
        let mut conversations = Vec::new();

        // ChatGPT exports typically have conversation blocks
        let conversation_selector = Selector::parse("div.conversation").ok();
        let message_selector = Selector::parse("div.message").ok();

        if let (Some(conv_sel), Some(msg_sel)) = (conversation_selector, message_selector) {
            for conv_elem in document.select(&conv_sel) {
                let mut exchanges = Vec::new();
                let messages: Vec<_> = conv_elem.select(&msg_sel).collect();

                // Group messages into Q&A pairs
                for chunk in messages.chunks(2) {
                    if chunk.len() == 2 {
                        let question_text = chunk[0].text().collect::<String>();
                        let answer_text = chunk[1].text().collect::<String>();

                        exchanges.push(Exchange {
                            question: Message {
                                text: question_text.trim().to_string(),
                                timestamp: Utc::now(),
                            },
                            answer: Message {
                                text: answer_text.trim().to_string(),
                                timestamp: Utc::now(),
                            },
                            metadata: ExchangeMetadata::default(),
                        });
                    }
                }

                if !exchanges.is_empty() {
                    conversations.push(Conversation {
                        id: Uuid::new_v4(),
                        source: ConversationSource::ChatGPT,
                        model: "unknown".to_string(),
                        session_id: Uuid::new_v4().to_string(),
                        timestamp: Utc::now(),
                        title: None,
                        metadata: ConversationMetadata {
                            total_exchanges: exchanges.len(),
                            ..Default::default()
                        },
                        exchanges,
                    });
                }
            }
        }

        Ok(conversations)
    }

    /// Parse ChatGPT JSON export format
    fn parse_chatgpt_json(&self, json: &str) -> Result<Vec<Conversation>> {
        #[derive(serde::Deserialize)]
        struct ChatGPTExport {
            #[serde(default)]
            conversations: Vec<ChatGPTConversation>,
        }

        #[derive(serde::Deserialize)]
        struct ChatGPTConversation {
            title: Option<String>,
            #[serde(default)]
            create_time: Option<i64>,
            mapping: std::collections::HashMap<String, ChatGPTNode>,
        }

        #[derive(serde::Deserialize)]
        struct ChatGPTNode {
            message: Option<ChatGPTMessage>,
            children: Vec<String>,
        }

        #[derive(serde::Deserialize)]
        struct ChatGPTMessage {
            author: ChatGPTAuthor,
            content: ChatGPTContent,
            #[serde(default)]
            create_time: Option<f64>,
        }

        #[derive(serde::Deserialize)]
        struct ChatGPTAuthor {
            role: String,
        }

        #[derive(serde::Deserialize)]
        struct ChatGPTContent {
            parts: Vec<String>,
        }

        let export: ChatGPTExport = serde_json::from_str(json)?;
        let mut conversations = Vec::new();

        for conv in export.conversations {
            let mut exchanges = Vec::new();
            let mut messages = Vec::new();

            // Flatten the tree structure
            for (_id, node) in &conv.mapping {
                if let Some(msg) = &node.message {
                    let text = msg.content.parts.join("\n");
                    let timestamp = msg
                        .create_time
                        .map(|t| {
                            DateTime::from_timestamp(t as i64, 0)
                                .unwrap_or_else(|| Utc::now())
                        })
                        .unwrap_or_else(|| Utc::now());

                    messages.push((msg.author.role.clone(), text, timestamp));
                }
            }

            // Sort by timestamp
            messages.sort_by_key(|m| m.2);

            // Pair user/assistant messages
            let mut i = 0;
            while i < messages.len() {
                if messages[i].0 == "user" && i + 1 < messages.len() && messages[i + 1].0 == "assistant" {
                    exchanges.push(Exchange {
                        question: Message {
                            text: messages[i].1.clone(),
                            timestamp: messages[i].2,
                        },
                        answer: Message {
                            text: messages[i + 1].1.clone(),
                            timestamp: messages[i + 1].2,
                        },
                        metadata: ExchangeMetadata::default(),
                    });
                    i += 2;
                } else {
                    i += 1;
                }
            }

            if !exchanges.is_empty() {
                let timestamp = conv
                    .create_time
                    .and_then(|t| DateTime::from_timestamp(t, 0))
                    .unwrap_or_else(|| Utc::now());

                conversations.push(Conversation {
                    id: Uuid::new_v4(),
                    source: ConversationSource::ChatGPT,
                    model: "gpt-unknown".to_string(),
                    session_id: Uuid::new_v4().to_string(),
                    timestamp,
                    title: conv.title,
                    metadata: ConversationMetadata {
                        total_exchanges: exchanges.len(),
                        ..Default::default()
                    },
                    exchanges,
                });
            }
        }

        Ok(conversations)
    }

    /// Parse Claude export format (similar structure)
    fn parse_claude(&self, content: &str) -> Result<ParseResponse> {
        let mut conversations = Vec::new();
        let mut errors = Vec::new();

        // Try JSON first
        if content.trim_start().starts_with('{') || content.trim_start().starts_with('[') {
            match self.parse_claude_json(content) {
                Ok(convos) => conversations.extend(convos),
                Err(e) => errors.push(format!("JSON parse error: {}", e)),
            }
        }

        Ok(ParseResponse {
            total_parsed: conversations.len(),
            conversations,
            errors,
        })
    }

    /// Parse Claude JSON export
    fn parse_claude_json(&self, json: &str) -> Result<Vec<Conversation>> {
        // Claude export structure (simplified - adjust based on actual format)
        #[derive(serde::Deserialize)]
        struct ClaudeExport {
            conversations: Vec<ClaudeConversation>,
        }

        #[derive(serde::Deserialize)]
        struct ClaudeConversation {
            uuid: String,
            name: Option<String>,
            created_at: String,
            chat_messages: Vec<ClaudeMessage>,
        }

        #[derive(serde::Deserialize)]
        struct ClaudeMessage {
            uuid: String,
            text: String,
            sender: String,
            created_at: String,
        }

        let export: ClaudeExport = serde_json::from_str(json)?;
        let mut conversations = Vec::new();

        for conv in export.conversations {
            let mut exchanges = Vec::new();
            let messages: Vec<_> = conv.chat_messages;

            let mut i = 0;
            while i < messages.len() {
                if messages[i].sender == "human" && i + 1 < messages.len() && messages[i + 1].sender == "assistant" {
                    let q_time = chrono::DateTime::parse_from_rfc3339(&messages[i].created_at)
                        .ok()
                        .map(|dt| dt.with_timezone(&Utc))
                        .unwrap_or_else(|| Utc::now());

                    let a_time = chrono::DateTime::parse_from_rfc3339(&messages[i + 1].created_at)
                        .ok()
                        .map(|dt| dt.with_timezone(&Utc))
                        .unwrap_or_else(|| Utc::now());

                    exchanges.push(Exchange {
                        question: Message {
                            text: messages[i].text.clone(),
                            timestamp: q_time,
                        },
                        answer: Message {
                            text: messages[i + 1].text.clone(),
                            timestamp: a_time,
                        },
                        metadata: ExchangeMetadata::default(),
                    });
                    i += 2;
                } else {
                    i += 1;
                }
            }

            if !exchanges.is_empty() {
                let timestamp = chrono::DateTime::parse_from_rfc3339(&conv.created_at)
                    .ok()
                    .map(|dt| dt.with_timezone(&Utc))
                    .unwrap_or_else(|| Utc::now());

                conversations.push(Conversation {
                    id: Uuid::new_v4(),
                    source: ConversationSource::Claude,
                    model: "claude-unknown".to_string(),
                    session_id: conv.uuid,
                    timestamp,
                    title: conv.name,
                    metadata: ConversationMetadata {
                        total_exchanges: exchanges.len(),
                        ..Default::default()
                    },
                    exchanges,
                });
            }
        }

        Ok(conversations)
    }
}
