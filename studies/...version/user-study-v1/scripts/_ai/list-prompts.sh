#!/usr/bin/env bash
# Lists all available prompts from memory/prompts/prompts_index.json
# Optional: pass a filter string to search prompt id or label

set -euo pipefail

INDEX_FILE="${HOME}/devbelt/archives/memory/prompts/prompts.json"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "❌ prompts.json not found."
  exit 1
fi

FILTER="${1:-}"

echo "Available Prompts:"
if [[ -n "$FILTER" ]]; then
  jq -r --arg filter "$FILTER" '.[] | select(.id | test($filter; "i")) + select(.label | test($filter; "i")) | "- \(.id): \(.label)"' "$INDEX_FILE"
else
  jq -r '.[] | "- \(.id): \(.label)"' "$INDEX_FILE"
fi
