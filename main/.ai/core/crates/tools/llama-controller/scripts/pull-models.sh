#!/usr/bin/env bash
# 🛰️ scripts/tools/pull-all.sh — bulk-download GGUF models if missing

MODELS_INDEX="${HOME}/devbelt/models/models.json"
ROOT_DIR="${HOME}/devbelt/models"

echo "📦 Pulling models listed in: $MODELS_INDEX"
missing_count=0

jq -c '.[]' "$MODELS_INDEX" | while read -r model; do
  id=$(echo "$model" | jq -r '.id')
  path=$(echo "$model" | jq -r '.path')
  source=$(echo "$model" | jq -r '.source')

  if [[ ! -f "$path" ]]; then
    echo "⬇️  Downloading: $id"
    mkdir -p "$(dirname "$path")"
    curl -L "$source/resolve/main/$(basename "$path")" -o "$path"
    if [[ $? -ne 0 ]]; then
      echo "❌ Failed to download: $id"
      ((missing_count++))
    fi
  else
    echo "✅ Already exists: $id"
  fi
done

if [[ $missing_count -gt 0 ]]; then
  echo "⚠️  $missing_count models failed to download."
else
  echo "✅ All model files are present."
fi
