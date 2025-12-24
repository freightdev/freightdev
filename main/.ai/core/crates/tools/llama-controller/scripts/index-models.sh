#!/usr/bin/env bash
set -e

ROOT="${HOME}/devbelt/models"
INDEX_FILE="$ROOT/models.json"

echo "🔄 Rebuilding models.json from $ROOT/**/model.json ..."
echo "[" > "$INDEX_FILE"

FIRST=1
find "$ROOT" -mindepth 2 -maxdepth 2 -type f -name "model.json" | while read -r meta_file; do
  # Add comma between entries
  if [ $FIRST -eq 0 ]; then
    echo "," >> "$INDEX_FILE"
  fi
  cat "$meta_file" >> "$INDEX_FILE"
  FIRST=0
done

echo "]" >> "$INDEX_FILE"
echo "✅ Indexed $(jq length "$INDEX_FILE") models into $INDEX_FILE"
