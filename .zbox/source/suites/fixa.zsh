###################
# FIX FUNCTIONS
###################

fixa_content() {
    local TARGET_DIR="${1:-}"
    if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
        echo "Usage: fix_content /path/to/target-dir"
        return 1
    fi

    echo "Find what (exact text or regex): "
    read FIND
    [[ -z "$FIND" ]] && { echo "Find string cannot be empty."; return 1 }

    echo "Replace with: "
    read REPLACE
    local ESC_REPLACE="${REPLACE//&/\\&}"

    local BACKUP_DIR="${TARGET_DIR%/}-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    local SED_CMD
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

    local FILES
    FILES=($(grep -rl "$FIND" "$TARGET_DIR"))
    [[ ${#FILES[@]} -eq 0 ]] && { echo "No files found containing '$FIND'."; return 0 }
    echo "Found ${#FILES[@]} file(s) with matches."
    echo

    echo "Preview all changes and approve in one go? (y/n): "
    read batch_ans

    if [[ "$batch_ans" == "y" ]]; then
        for file in $FILES; do
            diff --unified --color=always "$file" <(sed "s|$FIND|$ESC_REPLACE|g" "$file") || true
        done

        echo "Apply to ALL files? (y/n): "
        read all_ans
        if [[ "$all_ans" == "y" ]]; then
            for file in $FILES; do
                local REL_PATH="${file#$TARGET_DIR/}"
                local BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
                mkdir -p "$(dirname "$BACKUP_PATH")"
                cp "$file" "$BACKUP_PATH"
                "${SED_CMD[@]}" "s|$FIND|$ESC_REPLACE|g" "$file"
                echo "✅ Updated: $REL_PATH"
            done
            echo "🎯 All done! Backups in: $BACKUP_DIR"
            return 0
        fi
        echo "❌ No changes made."
        return 0
    fi

    for file in $FILES; do
        local REL_PATH="${file#$TARGET_DIR/}"
        local BACKUP_PATH="$BACKUP_DIR/$REL_PATH"
        mkdir -p "$(dirname "$BACKUP_PATH")"
        cp "$file" "$BACKUP_PATH"

        echo "🔍 File: $REL_PATH"
        diff --unified --color=always "$file" <(sed "s|$FIND|$ESC_REPLACE|g" "$file") || true
        echo "Apply changes to $REL_PATH? (y/n): "
        read ans
        [[ "$ans" == "y" ]] && { "${SED_CMD[@]}" "s|$FIND|$ESC_REPLACE|g" "$file"; echo "✅ Updated: $REL_PATH"; } || echo "⏩ Skipped: $REL_PATH"
        echo
    done

    echo "🎯 All done! Backups in: $BACKUP_DIR"
}

fixa_summary() {
    section "Summary"
    echo "Fix completed at: $(date)"
}

# Main fixa function
fixa() {
    case "${1}" in
        content)
            fixa_content; fixa_summary ;;
        help|--help|-h)
            cat <<EOF
Usage: fixa [option]
Options:
    content          Interative content fixer for full directory
EOF
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use 'fixa help' for usage information"
            return 1
            ;;
    esac
}
