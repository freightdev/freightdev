#!/bin/zsh
# check-dops.zsh
# Usage: ./check-dups.zsh path/to/dir

set -euo pipefail

TARGET_DIR="${1:-.}"
BACKUP_DIR="./duplicate-ckecker-backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔍 Scanning: $TARGET_DIR"
echo "💾 Backup will be stored in: $BACKUP_DIR"

# Pattern to detect duplicates (case-insensitive, trims leading/trailing spaces)
typeset -A seen

# Find .zsh files
zsh_files=($(find "$TARGET_DIR" -type f \( -name "*.zsh" -o -name "*.sh" \)))

for file in "${zsh_files[@]}"; do
    lineno=0
    while IFS= read -r line; do
        (( lineno++ ))
        clean_line=$(echo "$line" | sed 's/#.*//; s/^[ \t]*//; s/[ \t]*$//' )
        [[ -z "$clean_line" ]] && continue

        key="${clean_line:l}"  # lowercase for matching

        if [[ -n "${seen[$key]-}" ]]; then
            echo "⚠️ Duplicate found:"
            echo "   First:  ${seen[$key]}"
            echo "   Repeat: $file:$lineno  →  $clean_line"

            read "ans?Remove from $file:$lineno? (y/N): "
            if [[ "$ans" == [yY] ]]; then
                cp "$file" "$BACKUP_DIR/$(basename "$file")"
                # Delete the duplicate line
                sed -i.bak "${lineno}d" "$file"
                echo "   ✅ Removed. Backup saved in $BACKUP_DIR"
            fi
        else
            seen[$key]="$file:$lineno"
        fi
    done < "$file"
done

echo "✅ Scan complete."
