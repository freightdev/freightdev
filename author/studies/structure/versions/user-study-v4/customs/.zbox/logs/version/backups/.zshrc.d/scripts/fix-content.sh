#!/bin/bash
# fix-content.sh - interactive recursive find & replace with previews
# Usage: ./fix-content.sh /path/to/target-dir

set -euo pipefail

# --- Args ---
TARGET_DIR="${1:-}"
if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo "Usage: $0 /path/to/target-dir"
    exit 1
fi

# --- Get search & replace strings ---
read -rp "Find what (exact text or regex): " FIND
read -rp "Replace with: " REPLACE

if [[ -z "$FIND" ]]; then
    echo "Find string cannot be empty."
    exit 1
fi

# --- Vars ---
BACKUP_DIR="${TARGET_DIR%/}-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Detect sed flavor
if sed --version >/dev/null 2>&1; then
    SED_CMD=(sed -i)
else
    SED_CMD=(sed -i '')
fi

echo "📂 Target directory: $TARGET_DIR"
echo "🔍 Find: '$FIND'"
echo "✏️ Replace: '$REPLACE'"
echo "💾 Backup directory: $BACKUP_DIR"
echo

# --- Find matching files ---
FILES=$(grep -rl "$FIND" "$TARGET_DIR")
if [[ -z "$FILES" ]]; then
    echo "No files found containing '$FIND'."
    exit 0
fi

echo "Found $(echo "$FILES" | wc -l) file(s) with matches."
echo

# --- Preview & Confirm ---
read -rp "Preview all changes and approve in one go? (y/n): " batch_ans

if [[ "$batch_ans" == "y" ]]; then
    # Show combined diff
    for file in $FILES; do
        diff --unified --color=always "$file" <(sed "s|$FIND|$REPLACE|g" "$file") || true
    done
    read -rp "Apply to ALL files? (y/n): " all_ans
    if [[ "$all_ans" == "y" ]]; then
        for file in $FILES; do
            REL_PATH="${file#$TARGET_DIR/}"
            BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
            mkdir -p "$(dirname "$BACKUP_PATH")"
            cp "$file" "$BACKUP_PATH"
            "${SED_CMD[@]}" "s|$FIND|$REPLACE|g" "$file"
            echo "✅ Updated: $REL_PATH"
        done
        echo "🎯 All done! Backups in: $BACKUP_DIR"
        exit 0
    else
        echo "❌ No changes made."
        exit 0
    fi
fi

# --- Per-file mode ---
for file in $FILES; do
    REL_PATH="${file#$TARGET_DIR/}"
    BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
    mkdir -p "$(dirname "$BACKUP_PATH")"
    cp "$file" "$BACKUP_PATH"

    echo "🔍 File: $REL_PATH"
    diff --unified --color=always "$file" <(sed "s|$FIND|$REPLACE|g" "$file") || true
    echo

    read -rp "Apply changes to $REL_PATH? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        "${SED_CMD[@]}" "s|$FIND|$REPLACE|g" "$file"
        echo "✅ Updated: $REL_PATH"
    else
        echo "⏩ Skipped: $REL_PATH"
    fi
    echo
done

echo "🎯 All done! Backups in: $BACKUP_DIR"
