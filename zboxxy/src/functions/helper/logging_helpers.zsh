# ============================================================================
# LOGGING HELPERS (helpers/logging_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Logging, debugging, and tracing helpers

function log_write() {
    local level="$1"
    local message="$2"
    local logger_name="${3:-ZBOX}"
    local log_file="${4:-$ZBOX_HOME/logs/zbox.log}"
    
    local timestamp=$(date -Iseconds)
    local log_entry="[$timestamp] $level [$logger_name] $message"
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$log_file")"
    
    # Write to log file
    echo "$log_entry" >> "$log_file"
    
    # Also output to stderr if debug enabled or error level
    if [[ "$ZBOX_DEBUG" == "true" || "$level" == "ERROR" || "$level" == "WARN" ]]; then
        echo "$log_entry" >&2
    fi
}

function log_info() {
    log_write "INFO" "$1" "$2" "$3"
}

function log_warn() {
    log_write "WARN" "$1" "$2" "$3"
}

function log_error() {
    log_write "ERROR" "$1" "$2" "$3"
}

function log_debug() {
    if [[ "$ZBOX_DEBUG" == "true" ]]; then
        log_write "DEBUG" "$1" "$2" "$3"
    fi
}

function log_trace() {
    if [[ "$ZBOX_TRACE" == "true" ]]; then
        local function_name="${FUNCNAME[1]}"
        local line_number="${BASH_LINENO[0]}"
        log_write "TRACE" "Function: $function_name, Line: $line_number, Message: $1" "$2" "$3"
    fi
}

function log_performance() {
    local operation="$1"
    local start_time="$2"
    local end_time="${3:-$(date +%s%3N)}"
    
    local duration=$((end_time - start_time))
    log_info "Performance: $operation took ${duration}ms" "PERF"
}

function log_structured() {
    local level="$1"
    local event="$2"
    shift 2
    
    local structured_data="{\"level\":\"$level\",\"event\":\"$event\",\"timestamp\":\"$(date -Iseconds)\""
    
    # Add key-value pairs
    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        structured_data="$structured_data,\"$key\":\"$value\""
        shift 2
    done
    
    structured_data="$structured_data}"
    
    echo "$structured_data" >> "$ZBOX_HOME/logs/structured.log"
}

function log_get_last() {
    local count="${1:-10}"
    local log_file="${2:-$ZBOX_HOME/logs/zbox.log}"
    
    if [[ -f "$log_file" ]]; then
        tail -n "$count" "$log_file"
    else
        echo "Log file not found: $log_file"
    fi
}

function log_search() {
    local pattern="$1"
    local log_file="${2:-$ZBOX_HOME/logs/zbox.log}"
    local context_lines="${3:-2}"
    
    if [[ -f "$log_file" ]]; then
        grep -n -C "$context_lines" "$pattern" "$log_file"
    else
        echo "Log file not found: $log_file"
    fi
}