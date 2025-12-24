#!/bin/bash
# Conversation Intelligence Agent - Example Usage

BASE_URL="http://localhost:9020"

echo "=== Conversation Intelligence Agent Examples ==="
echo ""

# 1. Health Check
echo "1. Health Check"
curl -s ${BASE_URL}/health | jq
echo ""

# 2. Parse ChatGPT Export
echo "2. Parse ChatGPT conversations"
curl -s -X POST ${BASE_URL}/parse \
  -H "Content-Type: application/json" \
  -d '{
    "source": "ChatGPT",
    "file_path": "/home/admin/Downloads/chatgpt-conversations.json"
  }' | jq
echo ""

# 3. Parse Claude Export
echo "3. Parse Claude conversations"
curl -s -X POST ${BASE_URL}/parse \
  -H "Content-Type: application/json" \
  -d '{
    "source": "Claude",
    "file_path": "/home/admin/Downloads/claude-conversations.json"
  }' | jq
echo ""

# 4. Analyze Everything (All Passes)
echo "4. Run full analysis"
curl -s -X POST ${BASE_URL}/analyze \
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
  }' | jq
echo ""

# 5. Get Statistics
echo "5. Get statistics"
curl -s ${BASE_URL}/stats | jq
echo ""

# 6. Search for Agency-Forge
echo "6. Search for 'agency-forge'"
curl -s ${BASE_URL}/search/agency-forge | jq '.[] | {id, title, timestamp, total_exchanges: .metadata.total_exchanges}'
echo ""

# 7. Query with Filters
echo "7. Query conversations from 2024 about Rust"
curl -s -X POST ${BASE_URL}/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "rust",
    "filters": {
      "date_range": {
        "start": "2024-01-01T00:00:00Z",
        "end": "2024-12-31T23:59:59Z"
      },
      "topics": ["Rust Programming"]
    },
    "limit": 10
  }' | jq '.conversations | length'
echo ""

# 8. Get All Projects
echo "8. Get all projects discussed"
curl -s ${BASE_URL}/entities/project | jq '.[] | {value, count, confidence}'
echo ""

# 9. Get All Technologies
echo "9. Get all technologies mentioned"
curl -s ${BASE_URL}/entities/technology | jq '.[] | {value, count}'
echo ""

# 10. Find TODOs
echo "10. Find conversations with TODOs"
curl -s -X POST ${BASE_URL}/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "todo need to should",
    "limit": 20
  }' | jq '.conversations | length'
echo ""

# 11. Export to JSON
echo "11. Export filtered conversations to JSON"
curl -s -X POST ${BASE_URL}/export/json \
  -H "Content-Type: application/json" \
  -d '{
    "query": "agency-forge",
    "limit": 5
  }' | jq '.[:2] | .[] | {title, timestamp}'
echo ""

echo "=== Examples Complete ==="
