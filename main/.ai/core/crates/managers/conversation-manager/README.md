# Conversation Intelligence Agent

A sophisticated AI agent that analyzes, indexes, and extracts insights from your ChatGPT and Claude conversation histories.

## Overview

This agent transforms your exported AI chat histories into a searchable, analyzable knowledge base. It performs multi-pass analysis to extract entities, detect patterns, identify learning progressions, track project lifecycles, and mine TODOs from your conversations.

## Features

### 1. **Multi-Format Parser**
- Parses ChatGPT HTML and JSON exports
- Parses Claude JSON exports
- Normalizes conversations into structured format

### 2. **Multi-Pass Analysis Engine**

#### Pass 1: Entity Extraction
- **Projects**: codriver, coordinator, custom projects
- **Technologies**: Rust, Python, Docker, databases, frameworks
- **Concepts**: microservices, design patterns, architectures
- **File Paths**: `/path/to/file.rs`, `~/workspace/...`
- **Commands**: `cargo build`, `docker run`, etc.
- **URLs**: Links and references

#### Pass 2: Topic Modeling
- Identifies recurring themes
- Clusters related conversations
- Tracks topic evolution over time

#### Pass 3: Intent Detection
- **Learn**: "How do I...", "What is..."
- **Build**: "Create", "Implement", "Build me..."
- **Debug**: "Fix", "Error", "Not working"
- **Understand**: "Explain", "Why does..."
- **Optimize**: "Improve", "Better way"

#### Pass 4: Pattern Analysis
- **Learning Progressions**: Technologies you dove into over time
- **Project Lifecycles**: Idea → Design → Build → Iterate
- **Recurring Problems**: Issues that keep coming up
- **Design Evolutions**: How your architecture changed
- **Build Requests**: "Build me X" moments
- **TODOs**: Unfinished ideas and action items
- **Unfinished Ideas**: Conversations with future plans

#### Pass 5: Cross-Referencing
- Links related conversations
- Finds when you revisited topics
- Builds relationship graph

#### Pass 6: Knowledge Synthesis
- Auto-tags conversations
- Generates summaries
- Creates timelines

### 3. **Powerful Query System**
- Full-text search across all conversations
- Filter by date range, source, topics, projects
- Entity-based queries
- Pattern-based queries

### 4. **Export Capabilities**
- Export to JSON
- Export to YAML
- Generate timeline reports
- Create project documentation

## Architecture

```
conversation-intelligence/
├── src/
│   ├── main.rs           # HTTP API server
│   ├── models.rs         # Data structures
│   ├── parser.rs         # HTML/JSON parsers
│   ├── analyzer.rs       # Multi-pass analyzer
│   ├── entities.rs       # Entity extraction
│   ├── patterns.rs       # Pattern detection
│   └── storage.rs        # SurrealDB integration
├── configs/
│   └── config.toml       # Configuration
└── Cargo.toml            # Dependencies
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Parse Conversations
```bash
POST /parse
{
  "source": "ChatGPT" | "Claude",
  "file_path": "/path/to/export.json",
  "content": "..." # or provide content directly
}
```

### Analyze Conversations
```bash
POST /analyze
{
  "conversation_ids": ["uuid1", "uuid2"], # optional, analyzes all if not provided
  "passes": [
    "EntityExtraction",
    "TopicModeling",
    "IntentDetection",
    "PatternAnalysis",
    "CrossReferencing",
    "KnowledgeSynthesis"
  ],
  "depth": "quick" | "standard" | "thorough" | "deep"
}
```

### Query Conversations
```bash
POST /query
{
  "query": "search text",
  "filters": {
    "source": "ChatGPT",
    "date_range": {
      "start": "2024-01-01T00:00:00Z",
      "end": "2024-12-31T23:59:59Z"
    },
    "topics": ["Rust", "API Development"],
    "projects": ["codriver"]
  },
  "limit": 50
}
```

### Search by Text
```bash
GET /search/{text}
```

### Get Statistics
```bash
GET /stats
```

### Get Conversation by ID
```bash
GET /conversation/{uuid}
```

### Get Entities by Type
```bash
GET /entities/{type}
# Types: project, technology, person, concept, filepath, command, url, code
```

### Export to JSON
```bash
POST /export/json
{
  "query": "",
  "filters": {...}
}
```

### Export to YAML
```bash
POST /export/yaml
{
  "query": "",
  "filters": {...}
}
```

## Usage Workflow

### 1. Export Your Conversations

**ChatGPT:**
1. Go to Settings > Data Controls > Export
2. Download your data
3. Extract `conversations.json`

**Claude:**
1. Go to Settings > Export Conversations
2. Download JSON export

### 2. Parse Your Exports

```bash
curl -X POST http://localhost:9020/parse \
  -H "Content-Type: application/json" \
  -d '{
    "source": "ChatGPT",
    "file_path": "/path/to/conversations.json"
  }'
```

### 3. Analyze Everything

```bash
curl -X POST http://localhost:9020/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "passes": [
      "EntityExtraction",
      "TopicModeling",
      "IntentDetection",
      "PatternAnalysis",
      "CrossReferencing",
      "KnowledgeSynthesis"
    ],
    "depth": "thorough"
  }'
```

### 4. Query Your Knowledge Base

```bash
# Find all conversations about codriver
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "codriver",
    "limit": 50
  }'

# Get all projects you've discussed
curl http://localhost:9020/entities/project

# Search for specific topics
curl http://localhost:9020/search/rust%20async
```

### 5. Get Insights

```bash
# View statistics
curl http://localhost:9020/stats

# This will show:
# - Total conversations
# - Total exchanges
# - Unique topics
# - Unique entities
# - Top projects
# - Learning progressions
```

## Building & Running

### Build
```bash
cd /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo/core/managers/conversation-manager
cargo build --release
```

### Run
```bash
# Make sure SurrealDB is running first
# (it should be running as part of codriver)

# Set environment variables (optional)
export PORT=9020
export DATABASE_URL=ws://127.0.0.1:8000

# Run the agent
cargo run --release
```

### Or use the CoDriver scripts
```bash
cd /home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo/src/scripts
./start-agency.sh  # Starts all agents including this one
./status-check.sh  # Check if running
```

## Configuration

Edit `configs/config.toml`:

```toml
[server]
host = "127.0.0.1"
port = 9020

[database]
url = "ws://127.0.0.1:8000"
namespace = "agency"
database = "conversations"

[analysis]
default_depth = "standard"
default_passes = [
    "EntityExtraction",
    "TopicModeling",
    "IntentDetection",
    "PatternAnalysis",
    "CrossReferencing",
    "KnowledgeSynthesis"
]
```

## Use Cases

### 1. Project Documentation
Find all conversations about a project and generate timeline:
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "", "filters": {"projects": ["codriver"]}}' \
  | jq '.conversations | sort_by(.timestamp)'
```

### 2. Learning Path Analysis
See what technologies you learned and when:
```bash
curl http://localhost:9020/entities/technology | jq
```

### 3. TODO Mining
Find all unfinished ideas:
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "todo need to should implement"}'
```

### 4. Design History
Track how a design evolved:
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "design architecture", "filters": {"topics": ["System Design"]}}'
```

### 5. Context for New Conversations
Before starting a new AI conversation, query relevant history:
```bash
curl http://localhost:9020/search/authentication
```

## Data Structure

### Conversation
```json
{
  "id": "uuid",
  "source": "ChatGPT" | "Claude",
  "model": "gpt-4",
  "session_id": "session-uuid",
  "timestamp": "2024-11-06T00:00:00Z",
  "title": "Building a documentation agent",
  "exchanges": [...],
  "metadata": {
    "total_exchanges": 42,
    "topics": ["Rust", "AI Agents"],
    "entities": [...],
    "patterns": [...],
    "related_conversations": ["uuid1", "uuid2"],
    "tags": ["build-request", "has-todos", "technical"]
  }
}
```

### Entity
```json
{
  "entity_type": "Project" | "Technology" | "Concept" | ...,
  "value": "codriver",
  "confidence": 0.85,
  "first_seen": "2024-01-15T00:00:00Z",
  "count": 47
}
```

### Pattern
```json
{
  "pattern_type": "LearningProgression" | "ProjectLifecycle" | ...,
  "description": "Learning progression in Rust: 47 conversations over 180 days",
  "occurrences": ["uuid1", "uuid2", ...],
  "confidence": 0.8
}
```

## Integration with Other Agents

This agent integrates seamlessly with your existing CoDriver agents:

- **Documentation Agent**: Use conversation history to generate comprehensive docs
- **Project Manager**: Track project evolution from conversations
- **Context Builder**: Provide relevant history for new AI sessions
- **Learning Tracker**: Monitor skill development over time

## Future Enhancements

- [ ] Vector embeddings for semantic search
- [ ] LLM-powered summaries using Ollama
- [ ] Automatic report generation
- [ ] Slack/Discord notifications for patterns
- [ ] Web UI for visualization
- [ ] Export to Notion/Obsidian
- [ ] Real-time conversation streaming
- [ ] Multi-user support

## Troubleshooting

### SurrealDB Connection Issues
```bash
# Check if SurrealDB is running
ps aux | grep surreal

# Start SurrealDB if needed
surreal start --log trace --user root --pass root file:///tmp/agency.db
```

### Port Already in Use
```bash
# Change port in config or environment
export PORT=9021
```

### Parser Errors
- Ensure export files are valid JSON/HTML
- Check file size limits
- Verify source type matches actual format

## License

Part of the CoDriver project.

## Contact

Issues and feature requests: Create an issue in the CoDriver repository
