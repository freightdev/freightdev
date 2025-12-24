#!/bin/bash
# CoDriver State Synchronization Script
# Saves conversation context and file changes to SurrealDB

SURREAL_URL="http://192.168.12.66:9000"
NAMESPACE="workspace"
DATABASE="codriver_state"

# Get current session info
SESSION_ID="${CODRIVER_SESSION_ID:-$(date +%s)}"
TIMESTAMP=$(date -Iseconds)

# Save to SurrealDB
curl -X POST "$SURREAL_URL/sql" \
  -H "Content-Type: application/json" \
  -H "NS: $NAMESPACE" \
  -H "DB: $DATABASE" \
  -d @- <<EOF
{
  "query": "
    CREATE session_snapshot SET
      session_id = '$SESSION_ID',
      timestamp = '$TIMESTAMP',
      working_dir = '$(pwd)',
      git_branch = '$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")',
      git_commit = '$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")',
      modified_files = $(git status --porcelain 2>/dev/null | jq -R -s -c 'split("\n")[:-1]' || echo '[]'),
      context = {
        last_command: '$1',
        notes: '$2'
      }
  "
}
EOF

echo "✅ State synced to SurrealDB at $TIMESTAMP"
