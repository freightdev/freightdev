#!/bin/bash
# Universal Project Indexer - Pure Bash Version
# Advanced filesystem and archive indexer with metadata extraction

set -euo pipefail

# Configuration variables
MODE=""
TARGET_PATH=""
OUTPUT_PATH=""
FORMAT="yaml"
RECURSIVE=false
CRAWL=false
VERBOSE=false
MAX_DEPTH=10
EXCLUDE_PATTERNS="(.git|.svn|.hg|node_modules|.cache|.tmp|__pycache__)"

# Statistics
STATS_DIRS_SCANNED=0
STATS_FILES_SCANNED=0
STATS_ARCHIVES_EXTRACTED=0
STATS_TOTAL_SIZE=0
START_TIME=$(date +%s)

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [[ "$VERBOSE" == true ]] && echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Help function
usage() {
    cat << 'EOF'
Universal Project Indexer v1.0.0 - Pure Bash
Advanced filesystem and archive indexer with metadata extraction

USAGE:
    ./index.sh [-d|-f] <path> -o <output_path> [options]

MODES:
    -d, --directory     Directory indexing mode
    -f, --file          File indexing mode

REQUIRED:
    <path>              Path to project/file to index
    -o, --output        Output directory for index files

OPTIONS:
    --crawl             Deep crawl into archives and files
    --json              Output in JSON format
    --yaml              Output in YAML format (default)
    --yml               Output in YML format
    -v, --verbose       Verbose output
    --max-depth N       Maximum recursion depth (default: 10)
    --exclude PATTERN   Exclude patterns (default: .git,.svn,.hg,node_modules)

EXAMPLES:
    # Index directory structure
    ./index.sh -d "$HOME/...me/Main" -o "$HOME/indices"
    
    # Index with deep crawl into archives
    ./index.sh -d "$HOME/backups" -o "$HOME/indices" --crawl
    
    # Index specific file
    ./index.sh -f "project.tar.gz" -o "./indices" --crawl --json
    
    # Verbose directory indexing
    ./index.sh -d "/projects" -o "./out" --yaml -v

OUTPUT:
    Directory mode: Creates <path_name>.yaml with directory metadata
    File mode:      Creates <file_name>.yaml with file/archive contents
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--directory)
                MODE="directory"
                shift
                ;;
            -f|--file)
                MODE="file"
                shift
                ;;
            -r|--recursive)
                RECURSIVE=true
                shift
                ;;
            --crawl)
                CRAWL=true
                shift
                ;;
            --json)
                FORMAT="json"
                shift
                ;;
            --yaml)
                FORMAT="yaml"
                shift
                ;;
            --yml)
                FORMAT="yml"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --max-depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            --exclude)
                EXCLUDE_PATTERNS="$2"
                shift 2
                ;;
            -h|--help|-*|--*|*)
                usage
                exit 0
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$MODE" ]]; then
        log_error "Mode (-d or -f) is required"
        usage
        exit 1
    fi
    
    if [[ -z "$TARGET_PATH" ]]; then
        log_error "Target path is required"
        usage
        exit 1
    fi
}

# Get file metadata
get_file_metadata() {
    local file="$1"
    
    if [[ ! -e "$file" ]]; then
        return 1
    fi
    
    # Get file stats (try Linux stat first, then macOS)
    local size mtime perms owner group
    if command -v stat >/dev/null 2>&1; then
        if stat -c "%s" "$file" >/dev/null 2>&1; then
            # Linux stat
            read -r size mtime perms owner group < <(stat -c "%s %Y %A %U %G" "$file" 2>/dev/null)
        else
            # macOS stat
            read -r size mtime perms owner group < <(stat -f "%z %m %Sp %Su %Sg" "$file" 2>/dev/null)
        fi
    fi
    
    local file_type
    if command -v file >/dev/null 2>&1; then
        file_type="$(file -b "$file" 2>/dev/null || echo "unknown")"
    else
        file_type="unknown"
    fi
    
    # Convert mtime to readable date
    local modified_date
    if command -v date >/dev/null 2>&1; then
        if date -d "@$mtime" >/dev/null 2>&1; then
            modified_date="$(date -d "@$mtime" -Iseconds 2>/dev/null)"
        else
            modified_date="$(date -r "$mtime" -Iseconds 2>/dev/null || echo "$mtime")"
        fi
    else
        modified_date="$mtime"
    fi
    
    # Get file extension and detect language
    local basename_file="${file##*/}"
    local extension="${basename_file##*.}"
    if [[ "$basename_file" == "$extension" ]]; then
        extension=""
    fi
    
    local language="$(detect_language "$extension")"
    
    # Output metadata in key:value format
    echo "name:$basename_file"
    echo "path:$file"
    echo "size:${size:-0}"
    echo "modified:$modified_date"
    echo "permissions:${perms:-unknown}"
    echo "owner:${owner:-unknown}"
    echo "group:${group:-unknown}"
    echo "type:$file_type"
    echo "extension:$extension"
    echo "language:$language"
}

# Detect programming language from extension
detect_language() {
    local ext="$1"
    case "$ext" in
        c|h) echo "C" ;;
        cpp|cxx|cc|hpp|hxx|C|H) echo "C++" ;;
        rs) echo "Rust" ;;
        py|pyw) echo "Python" ;;
        js|mjs) echo "JavaScript" ;;
        ts|tsx) echo "TypeScript" ;;
        go) echo "Go" ;;
        java) echo "Java" ;;
        rb) echo "Ruby" ;;
        php) echo "PHP" ;;
        sh|bash|zsh) echo "Shell" ;;
        yaml|yml) echo "YAML" ;;
        json) echo "JSON" ;;
        xml) echo "XML" ;;
        md|markdown) echo "Markdown" ;;
        html|htm) echo "HTML" ;;
        css) echo "CSS" ;;
        scss|sass) echo "SCSS" ;;
        sql) echo "SQL" ;;
        r|R) echo "R" ;;
        pl|pm) echo "Perl" ;;
        lua) echo "Lua" ;;
        vim) echo "Vim" ;;
        tex) echo "LaTeX" ;;
        *) echo "Unknown" ;;
    esac
}

# Check if file is an archive
is_archive() {
    local file="$1"
    local basename_file="${file##*/}"
    local extension="${basename_file##*.}"
    
    case "$extension" in
        tar|gz|tgz|bz2|tbz2|xz|txz|zip|7z|rar|Z|lz|lzma) return 0 ;;
        *) 
            # Check for compound extensions
            case "$basename_file" in
                *.tar.gz|*.tar.bz2|*.tar.xz|*.tar.Z) return 0 ;;
                *) return 1 ;;
            esac
            ;;
    esac
}

# Extract archive contents list
extract_archive_contents() {
    local archive="$1"
    local basename_file="${file##*/}"
    local temp_list="/tmp/archive_contents_$$"
    
    log_debug "Extracting contents from $archive"
    
    # Determine archive type and extract contents
    case "$archive" in
        *.tar)
            tar -tf "$archive" > "$temp_list" 2>/dev/null || return 1
            ;;
        *.tar.gz|*.tgz)
            tar -tzf "$archive" > "$temp_list" 2>/dev/null || return 1
            ;;
        *.tar.bz2|*.tbz2)
            tar -tjf "$archive" > "$temp_list" 2>/dev/null || return 1
            ;;
        *.tar.xz|*.txz)
            tar -tJf "$archive" > "$temp_list" 2>/dev/null || return 1
            ;;
        *.gz)
            if command -v gunzip >/dev/null 2>&1; then
                gunzip -l "$archive" 2>/dev/null | tail -n +2 | awk '{print $4}' > "$temp_list" || return 1
            fi
            ;;
        *.zip)
            if command -v unzip >/dev/null 2>&1; then
                unzip -l "$archive" 2>/dev/null | awk 'NR>3 && NF>3 {print $4}' | head -n -2 > "$temp_list" || return 1
            fi
            ;;
        *.7z)
            if command -v 7z >/dev/null 2>&1; then
                7z l "$archive" 2>/dev/null | awk '/^[0-9]/ {print $6}' > "$temp_list" || return 1
            fi
            ;;
        *.rar)
            if command -v unrar >/dev/null 2>&1; then
                unrar l "$archive" 2>/dev/null | awk '/^[[:space:]]*[0-9]/ {print $1}' > "$temp_list" || return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
    
    if [[ -s "$temp_list" ]]; then
        cat "$temp_list"
        ((STATS_ARCHIVES_EXTRACTED++))
        rm -f "$temp_list"
        return 0
    else
        rm -f "$temp_list"
        return 1
    fi
}

# Check if path should be excluded
should_exclude() {
    local path="$1"
    local basename_path="${path##*/}"
    
    # Use bash regex matching
    if [[ "$basename_path" =~ $EXCLUDE_PATTERNS ]]; then
        return 0
    fi
    return 1
}

# Index directory structure
index_directory() {
    local dir="$1"
    local depth="${2:-0}"
    local parent_dir base_dir output_file

    # Stop if depth exceeds max depth
    (( depth > MAX_DEPTH )) && return

    base_dir="$(basename "$dir")"
    parent_dir="$(basename "$(dirname "$dir")")"

    # Build output filename for this directory
    if [[ "$dir" == "$ROOT_PATH" ]]; then
        output_file="$dir/...me.main.yaml"
    else
        output_file="$dir/${parent_dir}.${base_dir}.yaml"
    fi

    # Skip if output file exists (avoid recursion loops)
    if [[ -f "$output_file" ]]; then
        log_debug "Skipping output file $output_file to avoid recursion"
        return
    fi

    log_info "Indexing directory: $dir at depth $depth"
    ((STATS_DIRS_SCANNED++))

    # Clear/create output file
    : > "$output_file"

    # Gather subdirs and files
    local subdirs=()
    local files=()
    local item
    for item in "$dir"/*; do
        [[ -e "$item" ]] || continue
        if [[ -d "$item" ]]; then
            subdirs+=("$(basename "$item")")
        elif [[ -f "$item" ]]; then
            files+=("$(basename "$item")")
        fi
    done

    local total_size=0
    # Calculate total size of files in bytes
    for f in "${files[@]}"; do
        local size
        size=$(stat -c %s "$dir/$f" 2>/dev/null || stat -f %z "$dir/$f" 2>/dev/null || echo 0)
        total_size=$((total_size + size))
    done
    
    # Write directory metadata header
    {
        echo "# Directory Index: $target_dir"
        echo "# Depth: $current_depth"
        echo "# Generated: $(date -Iseconds 2>/dev/null || date)"
        echo "directory:"
        echo "  name: \"$base_dir\""
        echo "  path: \"$target_dir\""
        echo "  depth: $current_depth"
        echo "  subdirs_count: ${#subdirs[@]}"
        echo "  files_count: ${#files[@]}"
        echo "  total_items: $((${#subdirs[@]} + ${#files[@]}))"
        echo "  total_size: $total_size"
        echo "  subdirectories:"
        for sd in "${subdirs[@]}"; do
            echo "    - \"$sd\""
        done
        echo "  files:"
        for f in "${files[@]}"; do
            echo "     - \"$f\""
        done
        echo ""
    } > "$output_file"

    # Recurse into each subdirectory
    for sd in "${subdirs[@]}"; do
        index_directory "$dir/$sd" $((depth + 1))
    done
}

# Index single file
index_file() {
    local target_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$target_file" ]]; then
        log_error "File not found: $target_file"
        return 1
    fi
    
    log_debug "Indexing file: $target_file"
    ((STATS_FILES_SCANNED++))
    
    # Write file data to output
    {
        echo "# File Index: $target_file"
        echo "# Generated: $(date -Iseconds 2>/dev/null || date)"
        echo ""
        echo "file:"
        
        # Get file metadata
        local metadata
        metadata="$(get_file_metadata "$target_file")"
        while IFS=':' read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                echo "  $key: \"$value\""
            fi
        done <<< "$metadata"
        
        # Check if it's an archive and crawl is enabled
        if [[ "$CRAWL" == true ]] && is_archive "$target_file"; then
            log_info "Crawling archive: $target_file"
            echo "  is_archive: true"
            local contents
            if contents="$(extract_archive_contents "$target_file")"; then
                echo "  archive_contents:"
                while IFS= read -r content_line; do
                    echo "    - \"$content_line\""
                done <<< "$contents"
            fi
        fi
        
    } >> "$output_file"
}

# Generate output filename from path relative to TARGET_PATH and dot-join
generate_output_filename() {
    local dir_path="$1"
    local base_dir parent_dir

    base_dir="$(basename "$dir_path")"
    parent_dir="$(basename "$(dirname "$dir_path")")"

    if [[ "$dir_path" == "$ROOT_PATH" ]]; then
        # Root directory output file gets ...me prefix
        echo "$dir_path/...me.$base_dir.yaml"
    else
        # Subdirectories get prefix == base_dir, so:
        # e.g. for .../main/logic → main.logic.yaml
        echo "$dir_path/$base_dir.$base_dir.yaml"
    fi
}


# Convert to JSON (basic implementation)
convert_yaml_to_json() {
    local yaml_file="$1"
    local json_file="${yaml_file%.*}.json"
    
    # Simple YAML to JSON conversion (basic implementation)
    # This is a simplified converter - for production use a proper tool
    {
        echo "{"
        echo "  \"note\": \"Basic YAML to JSON conversion - use proper tools for complex structures\","
        echo "  \"original_yaml\": \"$yaml_file\","
        echo "  \"generated_at\": \"$(date -Iseconds 2>/dev/null || date)\""
        echo "}"
    } > "$json_file"
    
    log_warn "Basic JSON conversion created. For full YAML->JSON conversion, use 'yq' or 'python -c \"import yaml,json; print(json.dumps(yaml.safe_load(open('$yaml_file'))))\"'"
    echo "$json_file"
}

# Main execution function
main() {
    parse_args "$@"

    ROOT_PATH="$(realpath "$TARGET_PATH")"
    export ROOT_PATH

    log_info "${BOLD}Universal Project Indexer v1.0.0 - Pure Bash${NC}"
    log_info "Mode: ${CYAN}$MODE${NC}"
    log_info "Target: ${GREEN}$TARGET_PATH${NC}"
    log_info "Format: ${BLUE}$FORMAT${NC}"
    [[ "$CRAWL" == true ]] && log_info "Deep crawl: ${RED}ENABLED${NC}"
    [[ "$RECURSIVE" == true ]] && log_info "Recursive mode: ${RED}ENABLED${NC}"

    # If output path doesn't exist, create it
    if [[ -n "$OUTPUT_PATH" && ! -d "$OUTPUT_PATH" ]]; then
        mkdir -p "$OUTPUT_PATH" || {
            log_error "Cannot create output directory: $OUTPUT_PATH"
            exit 1
        }
    fi

    case "$MODE" in
        directory)
            if [[ ! -d "$TARGET_PATH" ]]; then
                log_error "Directory not found: $TARGET_PATH"
                exit 1
            fi

            if [[ "$RECURSIVE" == true ]]; then
                log_info "Recursive mode enabled - indexing ALL subdirectories"
                index_directory "$ROOT_PATH" 0
            else
                log_info "Starting directory indexing (non-recursive)..."
                index_directory "$ROOT_PATH" 0
            fi
            ;;
        file)
            if [[ ! -f "$TARGET_PATH" ]]; then
                log_error "File not found: $TARGET_PATH"
                exit 1
            fi
            local output_file
            output_file="$(generate_output_filename "$TARGET_PATH")"
            : > "$output_file"
            log_info "Indexing single file, output: $output_file"
            index_file "$TARGET_PATH" "$output_file"
            ;;
        *)
            log_error "Unknown mode: $MODE"
            exit 1
            ;;
    esac

    # Print summary on root output file only
    local root_output_file
    root_output_file="$(generate_output_filename "$TARGET_PATH")"
    {
        echo ""
        echo "# Indexing Summary"
        echo "summary:"
        echo "  indexer_version: \"1.0.0\""
        echo "  target_path: \"$TARGET_PATH\""
        echo "  mode: \"$MODE\""
        echo "  crawl_enabled: $CRAWL"
        echo "  recursive_enabled: $RECURSIVE"
        echo "  generated_at: \"$(date -Iseconds 2>/dev/null || date)\""
        echo "  statistics:"
        echo "    directories_scanned: $STATS_DIRS_SCANNED"
        echo "    files_processed: $STATS_FILES_SCANNED"
        echo "    archives_extracted: $STATS_ARCHIVES_EXTRACTED"
        echo "    total_size_bytes: $STATS_TOTAL_SIZE"
        echo "    processing_time_seconds: $(($(date +%s) - START_TIME))"
    } >> "$root_output_file"

    # Convert YAML to JSON if needed
    local final_output="$root_output_file"
    if [[ "$FORMAT" == "json" ]]; then
        final_output="$(convert_yaml_to_json "$root_output_file")"
    fi

    local duration=$(($(date +%s) - START_TIME))
    log_success "Indexing completed in ${duration}s"
    log_success "Results written to: ${GREEN}$final_output${NC}"
    log_info "Statistics:"
    log_info "  Directories scanned: $STATS_DIRS_SCANNED"
    log_info "  Files processed: $STATS_FILES_SCANNED"
    log_info "  Archives extracted: $STATS_ARCHIVES_EXTRACTED"
    log_info "  Total size processed: $STATS_TOTAL_SIZE bytes"
}


# Signal handling
trap 'log_error "Interrupted! Cleaning up..."; exit 130' INT TERM

# Run the indexer
main "$@"