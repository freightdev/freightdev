#!/bin/bash
# whitespace-cleaner.sh - Remove excessive whitespace from files
# Usage: ./whitespace-cleaner.sh [file|directory] [options]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
VERBOSE=false
BACKUP=true
MODIFIED_COUNT=0

usage() {
    cat << EOF
Usage: $0 [file|directory] [options]

Options:
    -d, --dry-run       Show what would be changed without modifying files
    -v, --verbose       Show detailed output
    -n, --no-backup     Don't create .bak files
    -h, --help          Show this help message

Examples:
    $0 script.sh                    # Clean single file
    $0 .                            # Clean all files in current directory
    $0 src/ --dry-run               # Preview changes in src/
    $0 main.go --no-backup          # Clean without backup

What it fixes:
    • Multiple consecutive blank lines → Single blank line
    • Trailing whitespace at end of lines
    • No newline at end of file → Adds one
    • Multiple newlines at end of file → Single newline
EOF
    exit 0
}

log() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

clean_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false

    if [[ ! -f "$file" ]]; then
        error "Not a file: $file"
        return 1
    fi

    # Skip binary files
    if file "$file" | grep -q "binary"; then
        log "Skipping binary file: $file"
        return 0
    fi

    # Create backup if enabled
    if [[ "$BACKUP" == true ]] && [[ "$DRY_RUN" == false ]]; then
        cp "$file" "${file}.bak"
    fi

    # Process the file
    log "Processing: $file"

    # Read file and apply transformations
    if [[ "$DRY_RUN" == true ]]; then
        # Dry run: just check for issues
        local trailing_spaces=$(grep -n " $" "$file" | wc -l)
        local blank_lines=$(grep -c "^$" "$file" || true)
        local multi_blank=$(awk 'BEGIN{blanks=0} /^$/{blanks++; if(blanks>1) found=1} /./{blanks=0} END{print found}' "$file")

        if [[ $trailing_spaces -gt 0 ]] || [[ $multi_blank -eq 1 ]]; then
            warn "$file would be modified:"
            [[ $trailing_spaces -gt 0 ]] && echo "    - Remove trailing spaces from $trailing_spaces lines"
            [[ $multi_blank -eq 1 ]] && echo "    - Collapse multiple blank lines"
            return 2
        else
            log "$file is clean"
            return 0
        fi
    else
        # Actual cleaning
        awk '
        BEGIN { blank_count = 0; lines = 0 }
        {
            # Remove trailing whitespace
            gsub(/[ \t]+$/, "")

            # Track consecutive blank lines
            if (length($0) == 0) {
                blank_count++
                if (blank_count == 1) {
                    buffer[lines++] = ""
                }
            } else {
                blank_count = 0
                buffer[lines++] = $0
            }
        }
        END {
            # Output all lines
            for (i = 0; i < lines; i++) {
                print buffer[i]
            }
            # Ensure file ends with single newline (print adds it)
        }
        ' "$file" > "$temp_file"

        # Check if file was actually changed
        if ! cmp -s "$file" "$temp_file"; then
            mv "$temp_file" "$file"
            success "Cleaned: $file"
            ((MODIFIED_COUNT++))
            return 2
        else
            rm "$temp_file"
            log "No changes needed: $file"
            return 0
        fi
    fi
}

process_path() {
    local path="$1"

    if [[ -f "$path" ]]; then
        clean_file "$path"
        return
    elif [[ -d "$path" ]]; then
        log "Processing directory: $path"

        # Common code file extensions
        local extensions=(
            "sh" "bash" "py" "js" "ts" "jsx" "tsx" "go" "rs" "c" "cpp" "h" "hpp"
            "java" "kt" "swift" "rb" "php" "css" "scss" "html" "xml" "json" "yaml" "yml"
            "md" "txt" "sql" "r" "R" "lua" "vim" "dart" "makefile" "gradle"
        )

        # Build find command with all extensions
        local find_cmd="find \"$path\" -type f \\( "
        for i in "${!extensions[@]}"; do
            if [[ $i -eq 0 ]]; then
                find_cmd+="-name \"*.${extensions[$i]}\""
            else
                find_cmd+=" -o -name \"*.${extensions[$i]}\""
            fi
        done
        find_cmd+=" -o -name Makefile -o -name Dockerfile \\)"

        # Execute find and process files
        while IFS= read -r file; do
            clean_file "$file" || true
        done < <(eval "$find_cmd")
    else
        error "Path not found: $path"
        exit 1
    fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
fi

TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--no-backup)
            BACKUP=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            usage
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    error "No target file or directory specified"
    usage
fi

# Main execution
echo "Whitespace Cleaner"
echo "=================="
[[ "$DRY_RUN" == true ]] && warn "DRY RUN MODE - No files will be modified"
[[ "$BACKUP" == true ]] && log "Backups enabled (.bak files)"
echo

process_path "$TARGET"

echo
echo "Summary:"
echo "--------"
if [[ "$DRY_RUN" == true ]]; then
    echo "Files that would be modified: Check output above"
else
    echo "Files modified: $MODIFIED_COUNT"
    if [[ "$BACKUP" == true ]] && [[ $MODIFIED_COUNT -gt 0 ]]; then
        echo "Backups created with .bak extension"
        echo "To remove backups: find . -name '*.bak' -delete"
    fi
fi
