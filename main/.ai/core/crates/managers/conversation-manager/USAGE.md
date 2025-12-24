# Quick Start Guide

## Step 1: Export Your Conversations

### ChatGPT
1. Go to https://chat.openai.com/
2. Click your profile → Settings → Data controls
3. Click "Export data"
4. Wait for email with download link
5. Download and extract `conversations.json`

### Claude
1. Go to https://claude.ai/
2. Click Settings (gear icon)
3. Go to "Data & Privacy"
4. Click "Export conversations"
5. Download the JSON file

## Step 2: Start the Agent

```bash
cd ~/WORKSPACE/.ai/agency-forge/arsenal/ai-agents/conversation-intelligence

# Build
cargo build --release

# Run (make sure SurrealDB is running!)
cargo run --release
```

## Step 3: Parse Your Exports

### Parse ChatGPT
```bash
curl -X POST http://localhost:9020/parse \
  -H "Content-Type: application/json" \
  -d '{
    "source": "ChatGPT",
    "file_path": "/home/admin/Downloads/conversations.json"
  }'
```

### Parse Claude
```bash
curl -X POST http://localhost:9020/parse \
  -H "Content-Type: application/json" \
  -d '{
    "source": "Claude",
    "file_path": "/home/admin/Downloads/claude-export.json"
  }'
```

## Step 4: Analyze Everything

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

This will run all 6 analysis passes:
- **Pass 1**: Extract entities (projects, technologies, concepts)
- **Pass 2**: Model topics and themes
- **Pass 3**: Detect intent (learn, build, debug, etc.)
- **Pass 4**: Find patterns (learning progressions, TODOs, etc.)
- **Pass 5**: Cross-reference related conversations
- **Pass 6**: Synthesize knowledge and tag conversations

## Step 5: Explore Your Data

### Get Statistics
```bash
curl http://localhost:9020/stats | jq
```

### Find All Projects
```bash
curl http://localhost:9020/entities/project | jq
```

### Search for Specific Topic
```bash
curl http://localhost:9020/search/agency-forge | jq
```

### Find All TODOs
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "todo need should implement"}' | jq
```

### Get Conversations About Rust
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "rust",
    "filters": {
      "topics": ["Rust Programming"]
    },
    "limit": 50
  }' | jq
```

## Common Queries

### "What projects have I discussed?"
```bash
curl http://localhost:9020/entities/project | jq '.[] | {project: .value, mentions: .count}'
```

### "What technologies do I use most?"
```bash
curl http://localhost:9020/entities/technology | jq '.[] | {tech: .value, mentions: .count}' | head -10
```

### "Show me all build requests"
```bash
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "build create implement"}' | jq '.conversations[] | {title, timestamp}'
```

### "Find conversations from last month"
```bash
START_DATE=$(date -d "1 month ago" -I)T00:00:00Z
END_DATE=$(date -I)T23:59:59Z

curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"\",
    \"filters\": {
      \"date_range\": {
        \"start\": \"$START_DATE\",
        \"end\": \"$END_DATE\"
      }
    }
  }" | jq '.total_found'
```

### "What was I learning 6 months ago?"
```bash
START=$(date -d "6 months ago" -I)T00:00:00Z
END=$(date -d "5 months ago" -I)T23:59:59Z

curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"how to learn\",
    \"filters\": {
      \"date_range\": {
        \"start\": \"$START\",
        \"end\": \"$END\"
      }
    }
  }" | jq
```

## Python Client Example

```python
import requests
import json

BASE_URL = "http://localhost:9020"

# Parse conversations
def parse_conversations(source, file_path):
    response = requests.post(f"{BASE_URL}/parse", json={
        "source": source,
        "file_path": file_path
    })
    return response.json()

# Analyze
def analyze_all():
    response = requests.post(f"{BASE_URL}/analyze", json={
        "passes": [
            "EntityExtraction",
            "TopicModeling",
            "IntentDetection",
            "PatternAnalysis",
            "CrossReferencing",
            "KnowledgeSynthesis"
        ],
        "depth": "thorough"
    })
    return response.json()

# Query
def search(query_text):
    response = requests.get(f"{BASE_URL}/search/{query_text}")
    return response.json()

# Usage
if __name__ == "__main__":
    # Parse
    result = parse_conversations("ChatGPT", "/path/to/export.json")
    print(f"Parsed {result['total_parsed']} conversations")

    # Analyze
    analysis = analyze_all()
    print(f"Analysis: {analysis['summary']}")

    # Search
    results = search("agency-forge")
    print(f"Found {len(results)} conversations about agency-forge")
```

## Integration with Other Agents

### Use with Documentation Agent
```bash
# Get all conversations about a project
curl -X POST http://localhost:9020/query \
  -H "Content-Type: application/json" \
  -d '{"query": "", "filters": {"projects": ["agency-forge"]}}' > project_history.json

# Feed to documentation agent for comprehensive docs
```

### Context Building for New Sessions
```bash
# Before starting new conversation, get relevant context
TOPIC="authentication"
curl http://localhost:9020/search/$TOPIC | jq '.[] | {title, key_points: .metadata.topics}' > context.json
```

## Troubleshooting

### Agent won't start
- Check if SurrealDB is running: `ps aux | grep surreal`
- Check port 9020 is available: `lsof -i :9020`

### Parse fails
- Verify file path is absolute
- Check file format matches source type
- Ensure file is valid JSON

### No results in queries
- Make sure you ran the analyze step
- Check that conversations were successfully parsed
- Try broader search terms

## Next Steps

1. Set up regular parsing of new conversations
2. Create custom queries for your workflows
3. Integrate with other agency-forge agents
4. Build dashboards using the API
5. Export insights to documentation

See `README.md` for full API documentation.
