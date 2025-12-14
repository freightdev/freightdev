#!/usr/bin/env zsh
# fix-content-noninteractive.sh
# Non-interactive recursive find & replace

set -euo pipefail

usage() {
    echo "Usage: $0 -T <target> -C <find>::<replace> [-C <find>::<replace> ...] [-F]"
    exit 1
}

TARGET=""
REPLACEMENTS=()
FORCE=0

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -T)
            TARGET="$2"
            shift 2
            ;;
        -C)
            REPLACEMENTS+=("$2")
            shift 2
            ;;
        -F)
            FORCE=1
            shift
            ;;
        *)
            usage
            ;;
    esac
done

[[ -z "$TARGET" || ! -e "$TARGET" ]] && echo "Target not found: $TARGET" && usage
[[ ${#REPLACEMENTS[@]} -eq 0 ]] && echo "No replacements specified" && usage

# --- Backup ---
BACKUP="${TARGET}-backup-$(date +%Y%m%d_%H%M%S)"
cp -r "$TARGET" "$BACKUP"
echo "Backup created at: $BACKUP"

# --- Detect sed flavor ---
if sed --version >/dev/null 2>&1; then
    SED_CMD=(sed -i)
else
    SED_CMD=(sed -i '')
fi

# --- Apply replacements ---
for repl in "${REPLACEMENTS[@]}"; do
    IFS='::' read -r FIND REPLACE <<< "$repl"
    [[ -z "$FIND" || -z "$REPLACE" ]] && continue
    echo "Replacing '$FIND' → '$REPLACE' in $TARGET"
    
    if [[ -d "$TARGET" ]]; then
        grep -rl "$FIND" "$TARGET" | while read -r file; do
            "${SED_CMD[@]}" "s|$FIND|$REPLACE|g" "$file"
        done
    else
        "${SED_CMD[@]}" "s|$FIND|$REPLACE|g" "$TARGET"
    fi
done

echo "✅ All replacements applied."
