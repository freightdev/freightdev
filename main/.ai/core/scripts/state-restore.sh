#!/bin/bash
# CoDriver State Restoration Script
# Loads last known state from SurrealDB

SURREAL_URL="http://192.168.12.66:9000"
NAMESPACE="workspace"
DATABASE="codriver_state"

echo "🔍 Fetching last state from SurrealDB..."

# Get latest snapshot
LATEST=$(curl -s -X POST "$SURREAL_URL/sql" \
  -H "Content-Type: application/json" \
  -H "NS: $NAMESPACE" \
  -H "DB: $DATABASE" \
  -d '{"query": "SELECT * FROM session_snapshot ORDER BY timestamp DESC LIMIT 1"}')

echo "$LATEST" | jq -r '
  .result[0].result[0] |
  "
  📅 Last Session: \(.timestamp)
  📂 Working Dir: \(.working_dir)
  🌿 Git Branch: \(.git_branch)
  📝 Git Commit: \(.git_commit)

  Modified Files:
  \(.modified_files | join("\n  "))

  Last Command: \(.context.last_command // "none")
  Notes: \(.context.notes // "none")
  "
'

echo ""
echo "💡 TIP: You can restore by running:"
echo "   cd \$(echo \$LATEST | jq -r '.result[0].result[0].working_dir')"
