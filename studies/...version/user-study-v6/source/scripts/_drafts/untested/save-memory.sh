#!/bin/bash
# save_memory.sh

MEMORY_DIR="~/ai-workspace/memory"
CHAT_ID=$1
CONTENT=$2

# Save to session memory
echo "$CONTENT" >> "$MEMORY_DIR/sessions/chat_$CHAT_ID.json"

# Update personal context
jq --arg content "$CONTENT" '.context += [$content]' "$MEMORY_DIR/personal/jesse_context.json" > tmp.json && mv tmp.json "$MEMORY_DIR/personal/jesse_context.json"
