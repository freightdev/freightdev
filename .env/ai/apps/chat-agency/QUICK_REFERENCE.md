# Quick Reference Cheat Sheet

## Most Common Commands

### Search & Save
```bash
# Basic search with save
python3 ai_query.py search "topic" --messages --save "topic_research"

# Advanced search
python3 ai_query.py search "keyword" \
  --source claude \
  --start-date 2024-01-01 \
  --min-messages 10 \
  --messages \
  --save "filtered_search"
```

### Code Extraction
```bash
# Extract all Rust code
python3 ai_query.py extract-code --language rust --save "rust_code"

# Extract code from specific topic
python3 ai_query.py extract-code \
  --query "authentication" \
  --language python \
  --save "auth_code"
```

### Batch Processing (Recommended)
```bash
# 1. Create template
python3 query_templates.py project-kickoff \
  --name "my_project" \
  --keywords flutter rust backend \
  --output project.json

# 2. Process
python3 batch_query.py process project.json

# Results in: outputs/queries/batch_results/my_project/
```

### Analytics
```bash
# Quick stats
python3 analytics.py stats

# Full report
python3 analytics.py report --output monthly_report

# Top topics
python3 analytics.py topics --limit 50

# Programming languages used
python3 analytics.py languages
```

### Get Specific Conversation
```bash
# By ID (partial works)
python3 ai_query.py get d276b8c1 --messages

# Save it
python3 ai_query.py get d276b8c1 --messages --save "important_convo"
```

### Query History
```bash
# See what you've queried
python3 ai_query.py history

# Filter by name
python3 ai_query.py history --query-name flutter_research
```

## Templates

### FED Trucking Platform
```bash
# Generate comprehensive queries
python3 query_templates.py project-kickoff \
  --name fed_trucking \
  --keywords flutter rust TMS trucking dispatch driver broker \
  --output fed_project.json

python3 batch_query.py process fed_project.json
```

### Learn a Technology
```bash
python3 query_templates.py language-dive \
  --language rust \
  --output rust_learning.json

python3 batch_query.py process rust_learning.json
```

### Debug an Issue
```bash
python3 query_templates.py debug \
  --keywords "connection timeout database error" \
  --output debug_db.json

python3 batch_query.py process debug_db.json
```

### Architecture Review
```bash
python3 query_templates.py architecture \
  --keywords microservices API database \
  --output arch_review.json

python3 batch_query.py process arch_review.json
```

## Output Locations

```
outputs/
├── conversations.duckdb                              # Main database
├── queries/                                          # Individual queries
│   ├── topic_research/
│   │   └── 20241207_120000_result.json              # Your saved query
│   └── batch_results/                               # Batch results
│       └── project_name/
│           ├── query1/
│           │   └── 20241207_140000_result.json
│           └── 20241207_140000_batch_summary.json   # Summary
```

## File Formats

### Batch Query JSON
```json
{
  "project_name": "my_project",
  "queries": [
    {
      "name": "query_name",
      "search": "keywords here",
      "include_messages": true,
      "filters": {
        "source": "claude",
        "min_messages": 5,
        "limit": 100
      }
    },
    {
      "name": "code_query",
      "search": "topic",
      "extract_code": true,
      "code_language": "rust"
    }
  ]
}
```

### Query Result JSON
```json
[
  {
    "id": "conv-id",
    "source": "claude",
    "title": "Title",
    "created_at": "2024-11-19T18:37:59",
    "message_count": 20,
    "messages": [
      {
        "sender": "human",
        "text": "Message text...",
        "created_at": "2024-11-19T18:38:00"
      }
    ]
  }
]
```

## Tips

1. **Use batch queries** for project work - more organized
2. **Always save important queries** - Use `--save` flag
3. **JSON for AI parsing** - Use `--format json`
4. **Check history first** - `python3 ai_query.py history`
5. **Start broad, then narrow** - Use filters progressively
6. **Extract code separately** - Use `extract-code` command
7. **Regular analytics** - Weekly reports to track trends

## One-Liners for Common Tasks

```bash
# "Get all Flutter knowledge"
python3 ai_query.py search "flutter" --messages --save "flutter_all"

# "Find all Rust code"
python3 ai_query.py extract-code --language rust --save "rust_snippets"

# "What did I talk about this week?"
python3 ai_query.py search --start-date 2024-12-01 --end-date 2024-12-07

# "Full project knowledge base"
python3 query_templates.py project-kickoff --name PROJECT --keywords KEY WORDS --output p.json && python3 batch_query.py process p.json

# "Monthly report"
python3 analytics.py report --output report_$(date +%Y%m)

# "Show me conversations about X"
python3 ai_query.py search "X" --messages | less

# "Get conversation by ID"
python3 ai_query.py get CONV_ID --messages --format markdown

# "Find similar conversations"
python3 ai_query.py related CONV_ID --limit 20
```

## For Your Coordinator AI

Your coordinator should use:

1. **Batch queries** for project initialization
2. **Saved results** in `outputs/queries/batch_results/PROJECT_NAME/`
3. **JSON format** for easy parsing
4. **Query history** to avoid duplicate queries
5. **Analytics** for understanding conversation patterns

### Coordinator Workflow

```bash
# 1. Initialize project knowledge
python3 query_templates.py project-kickoff \
  --name fed_trucking \
  --keywords flutter rust TMS \
  --output fed.json

# 2. Process batch
python3 batch_query.py process fed.json

# 3. Coordinator reads from:
# outputs/queries/batch_results/fed_trucking/flutter_knowledge/TIMESTAMP_result.json
# outputs/queries/batch_results/fed_trucking/rust_backend/TIMESTAMP_result.json
# etc.

# 4. Get analytics
python3 analytics.py report --output fed_insights

# 5. Coordinator references saved knowledge when building
```
