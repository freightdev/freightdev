# ============================================================================
# SYSTEM HELPERS (helpers/system_helpers.zsh)
# ============================================================================

#!/bin/zsh
# System information and process management helpers

function sys_get_cpu_usage() {
    if command -v top >/dev/null 2>&1; then
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}'
    else
        echo "unknown"
    fi
}

function sys_get_memory_usage() {
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local used_kb=$((total_kb - available_kb))
    local usage_percent=$((used_kb * 100 / total_kb))
    echo "$usage_percent"
}

function sys_get_disk_usage() {
    local path="${1:-/}"
    df -h "$path" | awk 'NR==2 {print $5}' | tr -d '%'
}

function sys_get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
}

function sys_process_exists() {
    local process_name="$1"
    pgrep "$process_name" >/dev/null 2>&1
}

function sys_kill_process_tree() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    # Get all child processes
    local children=$(pgrep -P "$pid")
    
    # Recursively kill children first
    for child_pid in $children; do
        sys_kill_process_tree "$child_pid" "$signal"
    done
    
    # Kill the parent process
    if kill -0 "$pid" 2>/dev/null; then
        kill -"$signal" "$pid" 2>/dev/null
        output_debug "Killed process $pid with signal $signal"
    fi
}

function sys_wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    
    local waited=0
    while [[ $waited -lt $timeout ]]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 0  # Process has ended
        fi
        sleep 1
        ((waited++))
    done
    
    return 1  # Timeout reached
}

function sys_get_process_memory() {
    local pid="$1"
    
    if [[ -f "/proc/$pid/status" ]]; then
        grep VmRSS "/proc/$pid/status" | awk '{print $2 " " $3}'
    else
        echo "unknown"
    fi
}

function sys_get_open_ports() {
    local process_name="$1"
    
    if command -v ss >/dev/null 2>&1; then
        ss -tulpn | grep "$process_name"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulpn | grep "$process_name"
    else
        echo "No network tools available"
    fi
}

function sys_check_dependencies() {
    local deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps} -gt 0 ]]; then
        output_error "Missing dependencies: ${(j:, :)missing_deps}"
        return 1
    fi
    
    return 0
}