# AI Query Examples

Common usage patterns for querying the conversation database.

## Basic Commands

### Search for conversations
```bash
# Search by keyword
python3 ai_query.py search "flutter"
python3 ai_query.py search "rust backend"
python3 ai_query.py search "TMS trucking"

# Search with filters
python3 ai_query.py search "authentication" --source claude --limit 10
python3 ai_query.py search "database" --start-date 2024-01-01 --end-date 2024-12-31
python3 ai_query.py search "react" --min-messages 10 --max-messages 50

# Include full message text
python3 ai_query.py search "flutter" --messages

# Different output formats
python3 ai_query.py search "flutter" --format json
python3 ai_query.py search "flutter" --format markdown
python3 ai_query.py search "flutter" --format text

# Save results for later use
python3 ai_query.py search "flutter rust backend" --messages --save "fed_project" --format json
```

### Get specific conversation
```bash
# Get by ID (full or partial)
python3 ai_query.py get d276b8c1

# Get without messages (metadata only)
python3 ai_query.py get d276b8c1 --no-messages

# Get and save
python3 ai_query.py get d276b8c1 --save "flutter_decision" --format markdown
```

### Find related conversations
```bash
# Find conversations related to a specific one
python3 ai_query.py related d276b8c1 --limit 10
```

### Extract code blocks
```bash
# Extract all code from conversations
python3 ai_query.py extract-code

# Extract specific language
python3 ai_query.py extract-code --language rust
python3 ai_query.py extract-code --language python
python3 ai_query.py extract-code --language javascript

# Extract code from filtered conversations
python3 ai_query.py extract-code --query "authentication" --language rust

# Save extracted code
python3 ai_query.py extract-code --query "TMS" --language rust --save "tms_rust_code"
```

### View query history
```bash
# See all past queries
python3 ai_query.py history

# Filter by query name
python3 ai_query.py history --query-name flutter_conversations
```

## Use Cases for Coordinator AI

### Building FED Trucking Platform

**Gather all Flutter + Rust knowledge:**
```bash
python3 ai_query.py search "flutter" --messages --save "fed_flutter_knowledge" --format json
python3 ai_query.py search "rust backend" --messages --save "fed_rust_knowledge" --format json
python3 ai_query.py search "TMS" --messages --save "fed_tms_domain" --format json
```

**Extract all relevant code:**
```bash
python3 ai_query.py extract-code --language rust --save "fed_rust_code"
python3 ai_query.py extract-code --language dart --save "fed_flutter_code"
```

**Find architecture decisions:**
```bash
python3 ai_query.py search "architecture database" --messages --save "fed_architecture"
python3 ai_query.py search "authentication authorization" --messages --save "fed_auth"
```

**Get related conversations:**
```bash
python3 ai_query.py related <conversation_id> --limit 20
```

### Project Organization Workflow

1. **Search for project keywords:**
```bash
python3 ai_query.py search "FED trucking dispatch" --messages --save "fed_project_init"
```

2. **Get related conversations:**
```bash
# Read the saved JSON to get conversation IDs
python3 ai_query.py related <id_from_results> --limit 20
```

3. **Extract specific information:**
```bash
python3 ai_query.py extract-code --query "FED" --language rust --save "fed_code_snippets"
```

4. **Check what you already queried:**
```bash
python3 ai_query.py history
```

## Advanced Filtering

### Date-based queries
```bash
# All conversations in November 2024
python3 ai_query.py search --start-date 2024-11-01 --end-date 2024-11-30 --messages

# Recent conversations only
python3 ai_query.py search --start-date 2024-12-01 --limit 50
```

### Source-specific queries
```bash
# Only Claude conversations
python3 ai_query.py search "rust" --source claude

# Only OpenAI conversations
python3 ai_query.py search "python" --source openai
```

### Message count filtering
```bash
# Long, detailed conversations (>20 messages)
python3 ai_query.py search "architecture" --min-messages 20

# Quick conversations (<10 messages)
python3 ai_query.py search --max-messages 10
```

## Output Directory Structure

Query results are saved to: `outputs/queries/<query_name>/`

Each query saves:
- `<timestamp>_result.json` - The actual query results
- `<timestamp>_metadata.json` - Query metadata (what was searched, when, filters used)

Example:
```
outputs/queries/
├── fed_project/
│   ├── 20241207_190154_result.json
│   ├── 20241207_190154_metadata.json
│   ├── 20241207_193045_result.json
│   └── 20241207_193045_metadata.json
├── flutter_conversations/
│   ├── 20241207_190154_result.json
│   └── 20241207_190154_metadata.json
└── rust_code/
    ├── 20241207_195032_result.json
    └── 20241207_195032_metadata.json
```

## JSON Output Format

Results are structured for easy parsing:

```json
[
  {
    "id": "conversation-id",
    "source": "claude",
    "title": "Conversation title",
    "created_at": "2024-11-19T18:37:59",
    "message_count": 20,
    "messages": [
      {
        "id": "message-id",
        "sender": "human",
        "text": "message text...",
        "created_at": "2024-11-19T18:38:00"
      }
    ]
  }
]
```

## Tips for Coordinator AI Integration

1. **Save all queries** with `--save <name>` to build a knowledge base
2. **Use JSON format** for programmatic parsing: `--format json`
3. **Include messages** when you need content: `--messages`
4. **Check history** before re-querying: `python3 ai_query.py history`
5. **Use specific query names** for organization: `fed_flutter`, `fed_rust`, `fed_auth`, etc.
6. **Combine filters** for precise results: `--source --start-date --min-messages`
