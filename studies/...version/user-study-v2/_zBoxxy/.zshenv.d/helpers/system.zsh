#!  ╔═══════════════════════════════════════════╗
#?    System Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

sys_info() {
    print -P "System Information:"
    print -P "==================="
    print -P "Hostname: $(hostname)"
    print -P "Uptime: $(uptime -p 2>/dev/null || uptime)"
    print -P "Kernel: $(uname -sr)"
    print -P "Shell: $SHELL"
    print -P "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    print -P "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    print -P "Disk Usage: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    print -P "Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
}

memory_usage() {
    local opt="$1"
    case "$opt" in
    -s | --summary)
        free -h
        ;;
    -t | --top)
        ps aux --sort=-%mem | head -n 15
        ;;
    *)
        echo "Usage: memory_usage [-s|--summary] [-t|--top]"
        return 1
        ;;
    esac
}

cpu_usage() {
    local opt="$1"
    case "$opt" in
    -s | --summary)
        top -bn1 | grep "Cpu(s)" | awk '{print "User: "$2"%  System: "$4"%  Idle: "$8"%"}'
        ;;
    -l | --load)
        uptime
        ;;
    *)
        echo "Usage: cpu_usage [-s|--summary] [-l|--load]"
        return 1
        ;;
    esac
}

loadmon() {
    local delay="${1:-2}"
    echo "Monitoring load average (press Ctrl+C to stop)..."

    while true; do
        clear
        echo "=== System Load Monitor ==="
        local loads
        loads=($(cut -d' ' -f1-3 /proc/loadavg))
        echo "Load Average (1m, 5m, 15m): ${loads[0]}, ${loads[1]}, ${loads[2]}"
        echo "CPU Count: $(nproc)"
        echo "Timestamp: $(date "+%d-%m-%Y %H:%M:%S")"
        echo "----------------------------"
        sleep "$delay"
    done
}


killps() {
    local pname="$1"
    if [[ -z $pname ]]; then
        echo "Usage: killps <process_name>"
        return 1
    fi

    local pids
    # Get all PIDs matching the process name, excluding grep and this function
    pids=$(ps -ax -o pid,comm | grep -i "$pname" | grep -v grep | grep -v "$0" | awk '{print $1}')

    if [[ -n $pids ]]; then
        echo "Killing process(es) '$pname': $pids"
        kill -9 $pids
    else
        echo "Process '$pname' not found"
    fi
}
