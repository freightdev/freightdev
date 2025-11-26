#!/usr/bin/env bash
# Create a global prompts_index.json from all *.prompt.json files

set -euo pipefail

PROMPT_DIR="${HOME}/devbelt/archives/memory/prompts"
INDEX_FILE="$PROMPT_DIR/prompts.json"

echo "📚 Indexing all prompt.json files in $PROMPT_DIR..."

prompt_files=$(find "$PROMPT_DIR" -type f -name "*.prompt.json")

echo "[" > "$INDEX_FILE"
first=true
for file in $prompt_files; do
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$INDEX_FILE"
  fi
  cat "$file" >> "$INDEX_FILE"
done
echo "]" >> "$INDEX_FILE"

echo "✅ Created global index → $INDEX_FILE"
