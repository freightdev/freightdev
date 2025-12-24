#!/bin/zsh
#############################
# ZBOX Trash Bin System
# Safe file deletion with restore capability
#############################

# Define trash directory
export TRASH_DIR="${HOME}/.local/share/Trash"
export TRASH_FILES="${TRASH_DIR}/files"
export TRASH_INFO="${TRASH_DIR}/info"

# Initialize trash directories
_init_trash() {
    mkdir -p "$TRASH_FILES" "$TRASH_INFO"
}

# Move files to trash instead of deleting
trash() {
    _init_trash

    if [[ $# -eq 0 ]]; then
        echo "Usage: trash <file1> [file2 ...]"
        echo "       trash -l           # list trash contents"
        echo "       trash -r <file>    # restore from trash"
        echo "       trash -e           # empty trash"
        echo "       trash -h           # show this help"
        return 1
    fi

    # Handle flags
    case "$1" in
        -l|--list)
            trash-list
            return $?
            ;;
        -r|--restore)
            shift
            trash-restore "$@"
            return $?
            ;;
        -e|--empty)
            trash-empty
            return $?
            ;;
        -h|--help)
            echo "ZBOX Trash Bin System"
            echo ""
            echo "Usage:"
            echo "  trash <files...>    Move files to trash"
            echo "  trash -l            List trash contents"
            echo "  trash -r <file>     Restore file from trash"
            echo "  trash -e            Empty trash permanently"
            echo "  trash -h            Show this help"
            echo ""
            echo "Trash location: $TRASH_DIR"
            return 0
            ;;
    esac

    # Move files to trash
    local file
    for file in "$@"; do
        if [[ ! -e "$file" ]]; then
            echo "trash: $file: No such file or directory" >&2
            continue
        fi

        # Get absolute path
        local abs_path="$(realpath "$file" 2>/dev/null || readlink -f "$file")"
        local basename="$(basename "$file")"
        local timestamp="$(date +%Y%m%d_%H%M%S)"
        local trash_name="${basename}.${timestamp}"

        # Move to trash
        mv "$file" "${TRASH_FILES}/${trash_name}"

        # Create info file with original path
        cat > "${TRASH_INFO}/${trash_name}.trashinfo" <<EOF
[Trash Info]
Path=$abs_path
DeletionDate=$(date +%Y-%m-%dT%H:%M:%S)
EOF

        echo "Moved to trash: $file → ${trash_name}"
    done
}

# List trash contents
trash-list() {
    _init_trash

    if [[ ! -d "$TRASH_FILES" ]] || [[ -z "$(ls -A "$TRASH_FILES" 2>/dev/null)" ]]; then
        echo "Trash is empty"
        return 0
    fi

    echo "Trash contents ($TRASH_DIR):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local file
    for file in "$TRASH_FILES"/*; do
        if [[ -e "$file" ]]; then
            local trash_name="$(basename "$file")"
            local info_file="${TRASH_INFO}/${trash_name}.trashinfo"

            if [[ -f "$info_file" ]]; then
                local orig_path="$(grep '^Path=' "$info_file" | cut -d= -f2-)"
                local del_date="$(grep '^DeletionDate=' "$info_file" | cut -d= -f2-)"
                echo "📄 $trash_name"
                echo "   Original: $orig_path"
                echo "   Deleted:  $del_date"
                echo ""
            else
                echo "📄 $trash_name (no metadata)"
            fi
        fi
    done
}

# Restore file from trash
trash-restore() {
    _init_trash

    if [[ $# -eq 0 ]]; then
        echo "Usage: trash -r <trashed_file_name>"
        echo "Tip: Use 'trash -l' to see trash contents"
        return 1
    fi

    local search_term="$1"
    local found_files=()

    # Find matching files
    for file in "$TRASH_FILES"/*; do
        if [[ "$(basename "$file")" == *"$search_term"* ]]; then
            found_files+=("$file")
        fi
    done

    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo "No files matching '$search_term' in trash"
        return 1
    fi

    if [[ ${#found_files[@]} -gt 1 ]]; then
        echo "Multiple files match '$search_term':"
        for f in "${found_files[@]}"; do
            echo "  - $(basename "$f")"
        done
        echo "Please be more specific"
        return 1
    fi

    # Restore the file
    local trash_file="${found_files[1]}"
    local trash_name="$(basename "$trash_file")"
    local info_file="${TRASH_INFO}/${trash_name}.trashinfo"

    if [[ -f "$info_file" ]]; then
        local orig_path="$(grep '^Path=' "$info_file" | cut -d= -f2-)"
        local orig_dir="$(dirname "$orig_path")"

        # Check if original location exists
        if [[ ! -d "$orig_dir" ]]; then
            echo "Original directory no longer exists: $orig_dir"
            echo "Restore to current directory? (y/n)"
            read -r response
            if [[ "$response" != "y" ]]; then
                echo "Restore cancelled"
                return 1
            fi
            orig_path="./$(basename "$orig_path")"
        fi

        # Check if file already exists at original location
        if [[ -e "$orig_path" ]]; then
            echo "File already exists at: $orig_path"
            echo "Restore anyway? This will overwrite. (y/n)"
            read -r response
            if [[ "$response" != "y" ]]; then
                echo "Restore cancelled"
                return 1
            fi
        fi

        # Restore
        mv "$trash_file" "$orig_path"
        rm -f "$info_file"
        echo "✓ Restored: $orig_path"
    else
        echo "No metadata found for $trash_name"
        echo "Restore to current directory as '$trash_name'? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            mv "$trash_file" "./$trash_name"
            echo "✓ Restored: ./$trash_name"
        fi
    fi
}

# Empty trash permanently
trash-empty() {
    _init_trash

    if [[ -z "$(ls -A "$TRASH_FILES" 2>/dev/null)" ]]; then
        echo "Trash is already empty"
        return 0
    fi

    echo "⚠️  WARNING: This will permanently delete all files in trash!"
    trash-list
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Continue? (yes/no)"
    read -r response

    if [[ "$response" == "yes" ]]; then
        rm -rf "${TRASH_FILES:?}"/*
        rm -rf "${TRASH_INFO:?}"/*
        echo "✓ Trash emptied"
    else
        echo "Cancelled"
    fi
}

# Alias for safety (optional - user can enable)
# Uncomment to override 'rm' with trash by default
# alias rm='trash'

# Safe rm that asks before permanently deleting
safe-rm() {
    echo "⚠️  Using 'rm' will permanently delete files!"
    echo "Consider using 'trash' instead for safety."
    echo ""
    echo "Files to delete: $@"
    echo "Permanently delete? (yes/no)"
    read -r response

    if [[ "$response" == "yes" ]]; then
        command rm "$@"
    else
        echo "Cancelled. Use 'trash' for safe deletion."
    fi
}
