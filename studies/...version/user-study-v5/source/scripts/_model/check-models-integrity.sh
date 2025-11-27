#!/usr/bin/env bash
# 🔍 scripts/tools/check-integrity.sh — verify model.gguf files exist and are non-zero

MODELS_INDEX="${HOME}/devbelt/models/models.json"
total=0
missing=0
empty=0

echo "🧪 Checking model file integrity..."
echo

jq -c '.[]' "$MODELS_INDEX" | while read -r model; do
  id=$(echo "$model" | jq -r '.id')
  path=$(echo "$model" | jq -r '.path')

  ((total++))

  if [[ ! -f "$path" ]]; then
    echo "❌ MISSING: $id — $path"
    ((missing++))
    continue
  fi

  size=$(stat -c%s "$path")
  if [[ "$size" -eq 0 ]]; then
    echo "⚠️  EMPTY: $id — $path"
    ((empty++))
  else
    echo "✅ OK: $id — $(basename "$path") (${size} bytes)"
  fi
done

echo
echo "📊 Summary:"
echo "Total models listed: $total"
echo "Missing files      : $missing"
echo "Empty files        : $empty"

if [[ $missing -gt 0 || $empty -gt 0 ]]; then
  echo "⚠️  Some issues found with model files."
  exit 1
else
  echo "🎉 All model files are valid."
  exit 0
fi
