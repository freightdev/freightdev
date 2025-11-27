#!/usr/bin/env bash
# validate-ui.sh — validates component structure in a given target directory

set -e

MODE="check"
ROOT_DIR=""

REQUIRED_EXTS=("tsx" "props.ts" "variants.ts")
INDEX_FILE="index.ts"

usage() {
  echo "Usage: ./validate-ui.sh -T path/to/components [--fix]"
  exit 1
}

# Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target)
      ROOT_DIR="$2"
      shift 2
      ;;
    --fix)
      MODE="fix"
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      usage
      ;;
  esac
done

if [[ -z "$ROOT_DIR" ]]; then
  echo "❌ Missing required target path"
  usage
fi

echo "🔎 Validating components in: $ROOT_DIR"
echo "🛠️  Mode: $MODE"

TOTAL=0
MISSING=0

for dir in $(find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d); do
  COMPONENT=$(basename "$dir")
  TOTAL=$((TOTAL + 1))

  echo "— $COMPONENT"
  ALL_FOUND=true

  for ext in "${REQUIRED_EXTS[@]}"; do
    FILE="$dir/$COMPONENT.$ext"
    if [[ ! -f "$FILE" ]]; then
      echo "   ❌ Missing: $COMPONENT.$ext"
      ALL_FOUND=false
      if [[ "$MODE" == "fix" ]]; then
        echo "   🧪 Scaffolding missing $COMPONENT.$ext..."
        ./scripts/create/create-ui.sh "$COMPONENT.tsx" -T "$ROOT_DIR" --no-index
        break
      fi
    fi
  done

  INDEX_PATH="$dir/$INDEX_FILE"
  if [[ ! -f "$INDEX_PATH" ]]; then
    echo "   ⚠️ Missing: index.ts"
    if [[ "$MODE" == "fix" ]]; then
      echo "export * from './$COMPONENT'" > "$INDEX_PATH"
      echo "   ✅ index.ts created"
    fi
  fi

  if [[ "$ALL_FOUND" == false ]]; then
    MISSING=$((MISSING + 1))
  fi
done

echo "✅ Validation complete: $TOTAL components scanned, $MISSING with issues."

# Future OpenAI hook
# if [[ "$MODE" == "fix" && $MISSING -gt 0 ]]; then
#   python3 scripts/agents/fix-agent.py --target "$ROOT_DIR"
# fi
