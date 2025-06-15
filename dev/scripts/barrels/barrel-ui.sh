#!/usr/bin/env bash
# barrel-ui.sh — Recursively creates index.ts files for UI components

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
      echo "Usage: ./barrel-ui.sh -T path/to/components [--dry]"
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "❌ Missing required target path"
  echo "Usage: ./barrel-ui.sh -T path/to/components [--dry]"
  exit 1
fi

ROOT_INDEX="$TARGET/index.ts"
EXPORT_LINES=()

echo "📦 Scanning $TARGET..."

# Loop over all 2-level-deep folders like visual/display/Icon
for dir in $(find "$TARGET" -mindepth 2 -maxdepth 2 -type d); do
  [ -d "$dir" ] || continue

  comp=$(basename "$dir")  # Component name = folder name
  files=$(find "$dir" -type f \( -name "$comp.tsx" -o -name "$comp.ts" \))

  # Skip if main component file is missing or empty
  if [[ -z "$files" || ! -s "$files" ]]; then
    echo "⚠️  $comp/ skipped — missing or empty main file"
    continue
  fi

  # Create sub index.ts if missing
  SUB_INDEX="$dir/index.ts"
  if [[ ! -f "$SUB_INDEX" || ! -s "$SUB_INDEX" ]]; then
    echo "  🧩 Creating $comp/index.ts"
    if [[ "$DRY" = false ]]; then
      echo "export * from './$comp'" > "$SUB_INDEX"
    fi
  fi

  # Add export for this component to root index
  RELATIVE=$(realpath --relative-to="$TARGET" "$dir")
  EXPORT_LINES+=("export * from './$RELATIVE'")
done

# Write root index.ts with all exports
echo -e "\n🗂️  Writing index.ts for $TARGET"

if [[ "$DRY" = false ]]; then
  {
    for line in "${EXPORT_LINES[@]}"; do
      echo "$line"
    done | sort
  } > "$ROOT_INDEX"

  echo "✅ Barrel complete: $ROOT_INDEX"
else
  for line in "${EXPORT_LINES[@]}"; do
    echo "[Dry] $line"
  done
  echo "✅ Dry barrel preview complete."
fi
