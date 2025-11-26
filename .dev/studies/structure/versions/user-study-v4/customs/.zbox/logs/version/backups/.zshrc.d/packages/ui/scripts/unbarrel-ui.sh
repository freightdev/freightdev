#!/usr/bin/env bash
# unbarrel-ui.sh — Remove all index.ts barrel files from a target UI folder

set -e

TARGET=""
DRY=false

# Flag parser
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target)
      TARGET="$2"
      shift 2
      ;;
    --dry)
      DRY=true
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: ./unbarrel-ui.sh -T path/to/components [--dry]"
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "❌ Missing required target path"
  echo "Usage: ./unbarrel-ui.sh -T path/to/components [--dry]"
  exit 1
fi

echo "🧹 Unbarreling index.ts files in: $TARGET"
FOUND=0

# Delete root index.ts
ROOT_INDEX="$TARGET/index.ts"
if [[ -f "$ROOT_INDEX" ]]; then
  echo "🗑️  Removing root index.ts"
  if [[ "$DRY" = false ]]; then
    rm "$ROOT_INDEX"
  fi
  FOUND=$((FOUND + 1))
fi

# Delete sub index.ts in all 2-level-deep component folders
for dir in $(find "$TARGET" -mindepth 2 -maxdepth 2 -type d); do
  SUB_INDEX="$dir/index.ts"
  if [[ -f "$SUB_INDEX" ]]; then
    echo "🗑️  Removing $SUB_INDEX"
    if [[ "$DRY" = false ]]; then
      rm "$SUB_INDEX"
    fi
    FOUND=$((FOUND + 1))
  fi
done

echo "✅ Done. $FOUND index.ts files removed."
if [[ "$DRY" = true ]]; then
  echo "🔍 Dry run only — no files deleted."
fi
