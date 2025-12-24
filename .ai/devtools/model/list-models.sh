#!/usr/bin/env bash
set -euo pipefail

MODELS_JSON="${HOME}/devbelt/models/models.json"

if [ ! -f "$MODELS_JSON" ]; then
  echo "❌ $MODELS_JSON not found."
  exit 1
fi

# Default options
SHOW="default"
FILTER=""

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      SHOW="id"
      shift
      ;;
    --path)
      SHOW="path"
      shift
      ;;
    --filter)
      FILTER="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "📄 Listing models in: $MODELS_JSON"
echo "────────────────────────────────────────────────────────"

# Choose jq output
case "$SHOW" in
  id)
    if [[ -n "$FILTER" ]]; then
      jq -r --arg filter "$FILTER" '.[] | select(.id | test($filter; "i")) | .id' "$MODELS_JSON"
    else
      jq -r '.[].id' "$MODELS_JSON"
    fi
    ;;
  path)
    if [[ -n "$FILTER" ]]; then
      jq -r --arg filter "$FILTER" '.[] | select(.path | test($filter; "i")) | .path' "$MODELS_JSON"
    else
      jq -r '.[].path' "$MODELS_JSON"
    fi
    ;;
  default)
    if [[ -n "$FILTER" ]]; then
      jq -r --arg filter "$FILTER" '.[] | select((.id + .name + .provider) | test($filter; "i")) | "* \(.id) — \(.name)  [\(.variant)]\n  → \(.path)"' "$MODELS_JSON"
    else
      jq -r '.[] | "* \(.id) — \(.name)  [\(.variant)]\n  → \(.path)"' "$MODELS_JSON"
    fi
    ;;
esac

echo "────────────────────────────────────────────────────────"
echo "✅ Total: $(jq --arg f "$FILTER" '.[] | select((.id + .name + .provider) | test($f; "i"))' "$MODELS_JSON" | jq -s 'length') models"
