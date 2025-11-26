# ============================================================================
# FILE HELPERS (helpers/file_helpers.zsh)
# ============================================================================

#!/bin/zsh
# File operations and path handling helpers

function file_safe_write() {
    local filepath="$1"
    local content="$2"
    local backup="${3:-true}"
    
    # Create backup if file exists
    if [[ "$backup" == "true" && -f "$filepath" ]]; then
        cp "$filepath" "${filepath}.backup.$(date +%s)"
    fi
    
    # Write to temporary file first
    local temp_file="${filepath}.tmp.$$"
    echo "$content" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$filepath"
        output_success "File written: $filepath"
        return 0
    else
        rm -f "$temp_file"
        output_error "Failed to write file: $filepath"
        return 1
    fi
}

function file_append_line() {
    local filepath="$1"
    local line="$2"
    local create_if_missing="${3:-true}"
    
    if [[ "$create_if_missing" == "true" || -f "$filepath" ]]; then
        echo "$line" >> "$filepath"
        return $?
    else
        output_error "File does not exist: $filepath"
        return 1
    fi
}

function file_find_and_replace() {
    local filepath="$1"
    local search_pattern="$2"
    local replacement="$3"
    local backup="${4:-true}"
    
    if [[ ! -f "$filepath" ]]; then
        output_error "File not found: $filepath"
        return 1
    fi
    
    if [[ "$backup" == "true" ]]; then
        cp "$filepath" "${filepath}.backup.$(date +%s)"
    fi
    
    sed -i "s|$search_pattern|$replacement|g" "$filepath"
    output_success "Replaced '$search_pattern' with '$replacement' in $filepath"
}

function file_get_extension() {
    local filepath="$1"
    echo "${filepath##*.}"
}

function file_get_basename() {
    local filepath="$1"
    local filename="${filepath##*/}"
    echo "${filename%.*}"
}

function file_get_size_human() {
    local filepath="$1"
    
    if [[ -f "$filepath" ]]; then
        if command -v numfmt >/dev/null 2>&1; then
            numfmt --to=iec-i --suffix=B $(stat -c%s "$filepath")
        else
            local size=$(stat -c%s "$filepath")
            if [[ $size -gt 1073741824 ]]; then
                echo "$(($size / 1073741824))GB"
            elif [[ $size -gt 1048576 ]]; then
                echo "$(($size / 1048576))MB"
            elif [[ $size -gt 1024 ]]; then
                echo "$(($size / 1024))KB"
            else
                echo "${size}B"
            fi
        fi
    else
        echo "File not found"
        return 1
    fi
}

function file_count_lines() {
    local filepath="$1"
    
    if [[ -f "$filepath" ]]; then
        wc -l < "$filepath"
    else
        echo 0
    fi
}

function file_tail_follow() {
    local filepath="$1"
    local lines="${2:-10}"
    local filter="$3"
    
    if [[ -n "$filter" ]]; then
        tail -f -n "$lines" "$filepath" | grep --line-buffered "$filter"
    else
        tail -f -n "$lines" "$filepath"
    fi
}

function file_rotate_log() {
    local logfile="$1"
    local max_size="${2:-10M}"
    local keep_files="${3:-5}"
    
    if [[ ! -f "$logfile" ]]; then
        return 0
    fi
    
    local current_size=$(stat -c%s "$logfile")
    local max_bytes
    
    case "$max_size" in
        *M) max_bytes=$((${max_size%M} * 1048576)) ;;
        *K) max_bytes=$((${max_size%K} * 1024)) ;;
        *) max_bytes="$max_size" ;;
    esac
    
    if [[ $current_size -gt $max_bytes ]]; then
        # Rotate existing files
        for i in $(seq $((keep_files-1)) -1 1); do
            [[ -f "${logfile}.$i" ]] && mv "${logfile}.$i" "${logfile}.$((i+1))"
        done
        
        # Move current log to .1
        mv "$logfile" "${logfile}.1"
        touch "$logfile"
        
        output_info "Rotated log file: $logfile"
    fi
}