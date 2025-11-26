#!/usr/bin/env bash
# barrel-ui.sh — Creates index.ts barrels (∞ depth or shallow mode)

set -e

TARGET=""
DEPTH="deep"
DRY=false

# Parse flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target) TARGET="$2"; shift 2 ;;
    --depth) DEPTH="$2"; shift 2 ;;
    --dry) DRY=true; shift ;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: ./barrel-ui.sh -T path/to/components [--depth shallow|deep] [--dry]"
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "❌ Missing required target path"
  echo "Usage: ./barrel-ui.sh -T path/to/components [--depth shallow|deep] [--dry]"
  exit 1
fi

ROOT_INDEX="$TARGET/index.ts"
EXPORT_LINES=()

echo "📦 Scanning $TARGET with --depth $DEPTH..."

if [[ "$DEPTH" == "shallow" ]]; then
  # ────── SHALLOW ──────
  for dir in "$TARGET"/*/; do
    [ -d "$dir" ] || continue
    comp=$(basename "$dir")

    has_code=$(find "$dir" -maxdepth 1 -type f \( -iname "*.ts" -o -iname "*.tsx" \) ! -iname "*.d.ts" | head -n 1)

    if [[ -z "$has_code" ]]; then
      echo "⚠️  $comp/ skipped — no .ts/.tsx files"
      continue
    fi

    echo "  📄 Exporting: $comp"
    EXPORT_LINES+=("export * from './$comp'")
  done

else
  # ────── DEEP ──────
  while IFS= read -r -d '' dir; do
    [ -d "$dir" ] || continue
    comp=$(basename "$dir")

    has_code=$(find "$dir" -maxdepth 1 -type f \( -iname "*.ts" -o -iname "*.tsx" \) ! -iname "*.d.ts" | head -n 1)
    if [[ -z "$has_code" ]]; then
      echo "⚠️  $comp/ skipped — no .ts/.tsx files"
      continue
    fi

    # Create index.ts inside the subfolder
    if [[ ! -f "$dir/index.ts" || ! -s "$dir/index.ts" ]]; then
      echo "  🧩 Creating $dir/index.ts"
      [[ "$DRY" == false ]] && echo "export * from './$comp'" > "$dir/index.ts"
    fi

    RELATIVE=$(realpath --relative-to="$TARGET" "$dir")
    EXPORT_LINES+=("export * from './$RELATIVE'")
  done < <(find "$TARGET" -mindepth 1 -type d -print0)
fi

# ────── WRITE ROOT INDEX.TS ──────
echo -e "\n🗂️  Writing $ROOT_INDEX"

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
  echo "✅ Dry run finished."
fi
