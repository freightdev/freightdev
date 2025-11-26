#!/bin/zsh
#############################
# zBox Resource Monitor
# Track CPU, RAM, function calls, etc.
#############################

export ZBOX_MONITOR_LOG="$ZBOX_AI/logs/monitoring/resource.log"
export ZBOX_MONITOR_PID_FILE="$ZBOX_AI/logs/monitoring/monitor.pid"

# Function call counter
typeset -gA ZBOX_FUNCTION_CALLS
export ZBOX_FUNCTION_CALLS

# Hook into function calls
_zbox_track_function_call() {
    local func_name="$1"
    ((ZBOX_FUNCTION_CALLS[$func_name]++))
}

# Start monitoring
zbox_monitor_start() {
    mkdir -p "$(dirname "$ZBOX_MONITOR_LOG")"

    if [[ -f "$ZBOX_MONITOR_PID_FILE" ]]; then
        local old_pid=$(cat "$ZBOX_MONITOR_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo "Monitor already running (PID: $old_pid)"
            return 0
        fi
    fi

    echo "Starting resource monitor..."

    # Start background monitoring
    (
        while true; do
            zbox_monitor_collect_metrics
            sleep 5
        done
    ) &

    local monitor_pid=$!
    echo "$monitor_pid" > "$ZBOX_MONITOR_PID_FILE"

    echo "✓ Monitor started (PID: $monitor_pid)"
    echo "  Log: $ZBOX_MONITOR_LOG"
    echo "  Stop with: zbox monitor stop"
}

# Collect metrics
zbox_monitor_collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

    # Memory usage
    local mem_used=$(free -m | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')

    # Shell processes
    local zsh_procs=$(pgrep -c zsh)

    # Function call count
    local func_calls=0
    for func in "${(@k)ZBOX_FUNCTION_CALLS}"; do
        func_calls=$((func_calls + ZBOX_FUNCTION_CALLS[$func]))
    done

    # Log metrics
    echo "$timestamp | CPU: ${cpu_usage}% | MEM: ${mem_used}% | ZSH: $zsh_procs | CALLS: $func_calls" >> "$ZBOX_MONITOR_LOG"
}

# Show current status
zbox_monitor_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "zBox Resource Monitor Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if monitoring is running
    if [[ -f "$ZBOX_MONITOR_PID_FILE" ]]; then
        local pid=$(cat "$ZBOX_MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Status: ✅ Running (PID: $pid)"
        else
            echo "Status: ❌ Not running (stale PID file)"
            rm -f "$ZBOX_MONITOR_PID_FILE"
        fi
    else
        echo "Status: ❌ Not running"
    fi

    echo ""

    # Current metrics
    echo "Current Metrics:"

    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "  CPU Usage:    ${cpu_usage}%"

    # Memory
    local mem_total=$(free -h | grep Mem | awk '{print $2}')
    local mem_used=$(free -h | grep Mem | awk '{print $3}')
    local mem_percent=$(free -m | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
    echo "  Memory:       $mem_used / $mem_total (${mem_percent}%)"

    # Disk
    local disk_used=$(df -h / | tail -1 | awk '{print $3}')
    local disk_total=$(df -h / | tail -1 | awk '{print $2}')
    local disk_percent=$(df -h / | tail -1 | awk '{print $5}')
    echo "  Disk:         $disk_used / $disk_total ($disk_percent)"

    # Processes
    local zsh_procs=$(pgrep -c zsh)
    echo "  Zsh Processes: $zsh_procs"

    # Function calls
    local func_calls=0
    for func in "${(@k)ZBOX_FUNCTION_CALLS}"; do
        func_calls=$((func_calls + ZBOX_FUNCTION_CALLS[$func]))
    done
    echo "  Function Calls: $func_calls (since shell start)"

    echo ""

    # Top functions
    if [[ ${#ZBOX_FUNCTION_CALLS} -gt 0 ]]; then
        echo "Top Functions:"
        for func in "${(@k)ZBOX_FUNCTION_CALLS}"; do
            echo "  $func: ${ZBOX_FUNCTION_CALLS[$func]}"
        done | sort -t: -k2 -rn | head -5
    fi

    # Recent log entries
    if [[ -f "$ZBOX_MONITOR_LOG" ]]; then
        echo ""
        echo "Recent Activity:"
        tail -5 "$ZBOX_MONITOR_LOG" | sed 's/^/  /'
    fi
}

# Stop monitoring
zbox_monitor_stop() {
    if [[ ! -f "$ZBOX_MONITOR_PID_FILE" ]]; then
        echo "Monitor not running"
        return 0
    fi

    local pid=$(cat "$ZBOX_MONITOR_PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        echo "Stopping monitor (PID: $pid)..."
        kill "$pid"
        rm -f "$ZBOX_MONITOR_PID_FILE"
        echo "✓ Monitor stopped"
    else
        echo "Monitor not running (cleaning up stale PID file)"
        rm -f "$ZBOX_MONITOR_PID_FILE"
    fi
}

# Watch resources in real-time
zbox_monitor_watch() {
    while true; do
        clear
        zbox_monitor_status
        echo ""
        echo "Press Ctrl+C to exit"
        sleep 2
    done
}
