# Conversation Indexer & Query System

A comprehensive system for indexing, querying, and analyzing Claude AI and OpenAI conversation exports. Built for AI coordinators to efficiently retrieve and organize conversation knowledge.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Tools](#tools)
- [Use Cases](#use-cases)
- [Configuration](#configuration)
- [Output Structure](#output-structure)

## 🎯 Overview

This system provides:
1. **Indexing**: Import Claude & OpenAI exports into DuckDB
2. **Querying**: Rich search with filters, full-text, code extraction
3. **Batch Processing**: Process multiple queries organized by project
4. **Analytics**: Deep insights into conversation patterns and topics
5. **Templates**: Pre-built query configurations for common scenarios

## ✨ Features

### Core Capabilities
- ✅ Index unlimited conversation exports (Claude & OpenAI)
- ✅ Full-text search across all messages
- ✅ Advanced filtering (date range, source, message count, keywords)
- ✅ Code extraction by language
- ✅ Related conversation discovery
- ✅ Query result persistence with metadata
- ✅ Multiple output formats (JSON, Markdown, Text)
- ✅ Batch query processing
- ✅ Project-based organization
- ✅ Conversation analytics
- ✅ Topic extraction
- ✅ Query templates
- ✅ Token estimation & chunking

### Advanced Features
- Context window management
- Query history tracking
- Conversation similarity analysis
- Programming language statistics
- Activity timeline analysis
- Topic co-occurrence mapping

## 🚀 Installation

### Prerequisites
```bash
# Python 3.8+
python3 --version

# Install dependencies
pip install duckdb toml
```

### Setup
```bash
cd /path/to/conversation-indexer

# Index your exports (first time)
python3 conversation_indexer.py

# Or specify exports directory
python3 conversation_indexer.py /path/to/ai-exports
```

## 🏃 Quick Start

### 1. Index Your Conversations

Place your exports in `ai-exports/`:
```
ai-exports/
├── claude-ai/
│   ├── export-2024-01.zip
│   └── export-2024-02.zip
└── openai-ai/
    └── export-2024-01.zip
```

Run the indexer:
```bash
python3 conversation_indexer.py
```

### 2. Basic Query

Search for conversations:
```bash
# Simple search
python3 ai_query.py search "flutter"

# Search with full messages
python3 ai_query.py search "flutter rust backend" --messages

# Save results
python3 ai_query.py search "TMS trucking" --messages --save "tms_knowledge"
```

### 3. Extract Code

```bash
# All Rust code
python3 ai_query.py extract-code --language rust

# Code from specific topic
python3 ai_query.py extract-code --query "authentication" --language python --save "auth_code"
```

### 4. Batch Processing (Recommended for AI Coordinators)

Create a batch query file or use a template:
```bash
# Generate template
python3 query_templates.py project-kickoff \
  --name "fed_trucking" \
  --keywords flutter rust TMS trucking \
  --output fed_project.json

# Process batch
python3 batch_query.py process fed_project.json
```

Results are organized in `outputs/queries/batch_results/fed_trucking/`

## 🔧 Tools

### 1. `conversation_indexer.py`
**Purpose**: Index conversation exports into DuckDB

```bash
# Index all exports in default directory
python3 conversation_indexer.py

# Index from custom directory
python3 conversation_indexer.py /custom/path/to/exports

# With artifact extraction
# (Edit config.toml: extract_artifacts = true)
python3 conversation_indexer.py
```

**Output**: `outputs/conversations.duckdb`

---

### 2. `ai_query.py`
**Purpose**: Query indexed conversations

#### Commands

**Search**
```bash
python3 ai_query.py search [QUERY] [OPTIONS]

Options:
  --source {claude,openai}    Filter by source
  --start-date YYYY-MM-DD     Start date
  --end-date YYYY-MM-DD       End date
  --min-messages N            Minimum message count
  --max-messages N            Maximum message count
  --limit N                   Result limit (default: 50)
  --messages                  Include full message text
  --format {json,markdown,text}
  --save NAME                 Save results to outputs/queries/NAME/

Examples:
  python3 ai_query.py search "flutter rust"
  python3 ai_query.py search "database" --source claude --min-messages 10
  python3 ai_query.py search "TMS" --messages --save "tms_research"
```

**Get Conversation**
```bash
python3 ai_query.py get [CONVERSATION_ID] [OPTIONS]

Options:
  --no-messages              Exclude messages (metadata only)
  --format {json,markdown,text}
  --save NAME                Save result

Examples:
  python3 ai_query.py get d276b8c1
  python3 ai_query.py get d276b8c1 --format markdown --save "flutter_decision"
```

**Extract Code**
```bash
python3 ai_query.py extract-code [OPTIONS]

Options:
  --query TEXT               Filter conversations
  --language LANG            Filter by language (rust, python, dart, etc.)
  --format {json,markdown,text}
  --save NAME                Save results

Examples:
  python3 ai_query.py extract-code --language rust
  python3 ai_query.py extract-code --query "auth" --language python --save "auth_code"
```

**Find Related**
```bash
python3 ai_query.py related [CONVERSATION_ID] [OPTIONS]

Options:
  --limit N                  Number of results (default: 10)

Examples:
  python3 ai_query.py related d276b8c1 --limit 20
```

**Query History**
```bash
python3 ai_query.py history [OPTIONS]

Options:
  --query-name NAME          Filter by query name

Examples:
  python3 ai_query.py history
  python3 ai_query.py history --query-name flutter_research
```

---

### 3. `batch_query.py`
**Purpose**: Process multiple queries at once

#### Commands

**Process Batch File**
```bash
python3 batch_query.py process [BATCH_FILE]

Examples:
  python3 batch_query.py process templates/fed_project_example.json
  python3 batch_query.py process my_queries.json
```

**Batch File Format**:
```json
{
  "project_name": "my_project",
  "queries": [
    {
      "name": "query1",
      "search": "keyword1 keyword2",
      "include_messages": true,
      "filters": {
        "source": "claude",
        "min_messages": 5,
        "limit": 100
      }
    },
    {
      "name": "code_extraction",
      "search": "authentication",
      "extract_code": true,
      "code_language": "rust"
    }
  ]
}
```

**Create Project Index**
```bash
python3 batch_query.py index [PROJECT_NAME]

Examples:
  python3 batch_query.py index fed_trucking_platform
```

**Merge Query Results**
```bash
python3 batch_query.py merge [PROJECT_NAME] [QUERY_NAMES...] [OPTIONS]

Options:
  --output NAME              Output filename (default: merged)

Examples:
  python3 batch_query.py merge fed_trucking flutter_knowledge rust_backend --output combined
```

---

### 4. `query_templates.py`
**Purpose**: Generate pre-built query configurations

#### Templates

**Project Kickoff**
```bash
python3 query_templates.py project-kickoff \
  --name "my_project" \
  --keywords flutter rust backend \
  --output my_project.json
```

**Tech Stack Research**
```bash
python3 query_templates.py tech-stack \
  --name rust \
  --output rust_research.json
```

**Language Deep Dive**
```bash
python3 query_templates.py language-dive \
  --language rust \
  --output rust_deep_dive.json
```

**Feature Implementation**
```bash
python3 query_templates.py feature \
  --name authentication \
  --keywords auth JWT session token \
  --output auth_feature.json
```

**Debugging Session**
```bash
python3 query_templates.py debug \
  --keywords "connection refused" timeout database \
  --output debug_connection.json
```

**Domain Expertise**
```bash
python3 query_templates.py domain \
  --name "trucking logistics" \
  --output trucking_domain.json
```

**Architecture Review**
```bash
python3 query_templates.py architecture \
  --keywords microservices database API \
  --output architecture_review.json
```

**Timeline Analysis**
```bash
python3 query_templates.py timeline \
  --keywords flutter TMS \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --output timeline_2024.json
```

**Code Migration**
```bash
python3 query_templates.py migration \
  --from-tech javascript \
  --to-tech rust \
  --output js_to_rust.json
```

---

### 5. `analytics.py`
**Purpose**: Analyze conversation patterns and trends

#### Commands

**Statistics**
```bash
python3 analytics.py stats
```

**Activity Timeline**
```bash
python3 analytics.py timeline [OPTIONS]

Options:
  --granularity {day,week,month}    Default: month

Examples:
  python3 analytics.py timeline
  python3 analytics.py timeline --granularity day
```

**Topic Extraction**
```bash
python3 analytics.py topics [OPTIONS]

Options:
  --limit N                  Number of topics (default: 50)

Examples:
  python3 analytics.py topics
  python3 analytics.py topics --limit 100
```

**Conversation Patterns**
```bash
python3 analytics.py patterns
```

**Programming Languages**
```bash
python3 analytics.py languages
```

**Similar Conversations**
```bash
python3 analytics.py similar [CONVERSATION_ID] [OPTIONS]

Options:
  --limit N                  Number of results (default: 10)

Examples:
  python3 analytics.py similar d276b8c1 --limit 20
```

**Full Report**
```bash
python3 analytics.py report [OPTIONS]

Options:
  --output FILENAME          Output filename (default: analytics_report)

Examples:
  python3 analytics.py report
  python3 analytics.py report --output monthly_report_2024_12
```

Generates both JSON and Markdown reports.

---

### 6. `query_conversations.py` & `query_artifacts.py`
**Purpose**: Original query tools (still functional)

See `EXAMPLES.md` for usage.

## 💡 Use Cases

### For AI Coordinators

#### Building FED Trucking Platform

**Step 1: Gather all relevant knowledge**
```bash
# Use template
python3 query_templates.py project-kickoff \
  --name fed_trucking \
  --keywords flutter rust TMS trucking dispatch \
  --output fed_project.json

# Process batch
python3 batch_query.py process fed_project.json
```

Results in `outputs/queries/batch_results/fed_trucking/`:
- `flutter_knowledge/` - All Flutter discussions
- `rust_backend/` - All Rust backend info
- `tms_domain_knowledge/` - Domain expertise
- `architecture_decisions/` - Design choices
- And more...

**Step 2: Get analytics**
```bash
python3 analytics.py report --output fed_project_insights
```

**Step 3: Reference saved queries**
Your coordinator can now read from:
- `outputs/queries/batch_results/fed_trucking/flutter_knowledge/[timestamp]_result.json`
- Each file contains full conversations with all messages

#### Debugging Specific Issues

```bash
# Template for finding solutions
python3 query_templates.py debug \
  --keywords "async rust tokio error" \
  --output debug_async.json

python3 batch_query.py process debug_async.json
```

#### Learning New Technology

```bash
# Deep dive into Rust
python3 query_templates.py language-dive \
  --language rust \
  --output rust_learning.json

python3 batch_query.py process rust_learning.json
```

### For Developers

#### Finding Architecture Decisions

```bash
python3 ai_query.py search "architecture decision why chose" \
  --min-messages 10 \
  --messages \
  --save architecture_rationale
```

#### Code Examples

```bash
# All authentication code
python3 ai_query.py extract-code \
  --query "authentication" \
  --save auth_examples

# Specific language
python3 ai_query.py extract-code \
  --query "database migration" \
  --language rust \
  --save rust_migrations
```

#### Project Timeline

```bash
python3 ai_query.py search "TMS platform" \
  --start-date 2024-01-01 \
  --end-date 2024-06-30 \
  --messages \
  --save tms_h1_2024
```

## ⚙️ Configuration

Edit `config.toml`:

```toml
[paths]
exports_dir = "ai-exports"
output_dir = "outputs"
database_name = "conversations.duckdb"

[indexing]
extract_artifacts = false  # Set true to extract images/files
artifacts_dir = "extracted_artifacts"

[sources]
index_claude = true
index_openai = true
```

## 📁 Output Structure

```
outputs/
├── conversations.duckdb          # Main database
├── queries/                      # Individual queries
│   ├── flutter_research/
│   │   ├── 20241207_120000_result.json
│   │   └── 20241207_120000_metadata.json
│   └── batch_results/            # Batch query results
│       └── fed_trucking_platform/
│           ├── flutter_knowledge/
│           │   ├── 20241207_140000_result.json
│           │   └── 20241207_140000_metadata.json
│           ├── rust_backend/
│           ├── tms_domain_knowledge/
│           └── 20241207_140000_batch_summary.json
└── analytics_report.json         # Analytics reports
```

## 🎓 Examples

### Example 1: Complete Project Knowledge Base

```bash
# 1. Create batch query for your project
cat > my_project.json << 'EOF'
{
  "project_name": "my_saas_platform",
  "queries": [
    {
      "name": "nextjs_knowledge",
      "search": "nextjs react frontend",
      "include_messages": true
    },
    {
      "name": "backend_api",
      "search": "API backend REST GraphQL",
      "include_messages": true
    },
    {
      "name": "database_schema",
      "search": "database schema PostgreSQL migration",
      "include_messages": true
    },
    {
      "name": "all_code",
      "search": "saas platform",
      "extract_code": true
    }
  ]
}
EOF

# 2. Process
python3 batch_query.py process my_project.json

# 3. Create index
python3 batch_query.py index my_saas_platform

# 4. Your coordinator reads from:
# outputs/queries/batch_results/my_saas_platform/
```

### Example 2: Daily Workflow

```bash
# Morning: What did I work on yesterday?
python3 ai_query.py search --start-date 2024-12-06 --end-date 2024-12-06

# Found interesting conversation, get related ones
python3 ai_query.py related abc123 --limit 10

# Extract code from that topic
python3 ai_query.py extract-code --query "topic name" --save daily_code

# Weekly analytics
python3 analytics.py timeline --granularity week
```

### Example 3: Learning from Past Mistakes

```bash
# Find all error discussions
python3 ai_query.py search "error bug problem issue" \
  --min-messages 5 \
  --messages \
  --save debugging_knowledge

# Analyze patterns
python3 analytics.py patterns

# Find common topics in errors
python3 analytics.py topics --limit 100 > common_issues.txt
```

## 🔍 Tips for AI Coordinators

1. **Always save queries** - Use `--save` to build persistent knowledge base
2. **Use batch processing** - More organized than individual queries
3. **Leverage templates** - Faster than writing batch files manually
4. **Check query history** - Avoid re-querying: `python3 ai_query.py history`
5. **JSON format for parsing** - Use `--format json` for programmatic access
6. **Include messages when needed** - `--messages` flag for full content
7. **Use specific query names** - Easier to find later: `fed_flutter`, `fed_rust`, etc.
8. **Merge related queries** - Combine multiple query results into one file
9. **Regular analytics** - Run weekly to track conversation trends
10. **Token awareness** - Use chunking features for large conversations

## 📊 Query Result Format

All saved queries are JSON:

```json
[
  {
    "id": "conversation-uuid",
    "source": "claude",
    "title": "Conversation title",
    "created_at": "2024-11-19T18:37:59",
    "updated_at": "2024-11-19T19:55:09",
    "message_count": 20,
    "summary": "...",
    "messages": [
      {
        "id": "message-uuid",
        "sender": "human",
        "text": "Full message text...",
        "created_at": "2024-11-19T18:38:00",
        "has_attachments": false
      },
      {
        "id": "message-uuid",
        "sender": "assistant",
        "text": "Full response text...",
        "created_at": "2024-11-19T18:38:15",
        "has_attachments": false
      }
    ]
  }
]
```

## 🚧 Troubleshooting

### Database locked
```bash
# Close all connections
pkill -f python3.*query

# Or specify different database
python3 ai_query.py --db outputs/conversations.duckdb search "test"
```

### No results found
```bash
# Check what's indexed
python3 conversation_indexer.py  # Look at statistics

# Try broader search
python3 ai_query.py search "single keyword"

# Check date ranges
python3 analytics.py timeline
```

### Slow queries
```bash
# Use limits
python3 ai_query.py search "term" --limit 20

# Avoid --messages for exploratory searches
python3 ai_query.py search "term"  # Just titles

# Then get specific conversations
python3 ai_query.py get abc123 --messages
```

## 📝 License

This is a personal utility tool. Use as needed for your conversation analysis.

## 🤝 Contributing

This is a personal project, but feel free to adapt and extend for your needs.

## 📮 Support

Check the examples in `EXAMPLES.md` for detailed usage patterns.
