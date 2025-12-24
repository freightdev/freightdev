#!/usr/bin/env bash
set -e

ROOT="${HOME}/devbelt/models"
ERRORS=0

echo "🔍 Validating models inside: $ROOT"

for model_dir in "$ROOT"/*; do
  [ -d "$model_dir" ] || continue

  meta_file="$model_dir/model.json"

  if [ ! -f "$meta_file" ]; then
    echo "⚠️  Missing model.json in $model_dir"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Validate JSON syntax
  if ! jq empty "$meta_file" >/dev/null 2>&1; then
    echo "❌ Invalid JSON in $meta_file"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Required fields
  for field in id name quantization variant path source; do
    if ! jq -e ".${field}" "$meta_file" >/dev/null; then
      echo "❌ Missing field '$field' in $meta_file"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check model.gguf file exists
  path=$(jq -r '.path' "$meta_file")
  if [ ! -f "$path" ]; then
    echo "❌ model.gguf not found at: $path"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -eq 0 ]; then
  echo "✅ All models passed validation."
else
  echo "❌ Validation failed with $ERRORS issue(s)."
  exit 1
fi
