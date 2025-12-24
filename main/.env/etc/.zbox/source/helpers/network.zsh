#!  ╔════════════════════════════════════════════╗
#?    Network Helpers - Environment Source (Zsh)  
#!  ╚════════════════════════════════════════════╝

# Show local and public IP
findmyip() {
    echo "=== IP Information ==="

    if command -v ip >/dev/null 2>&1; then
        local local_ip
        local_ip=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}')
        echo "Local IP:  ${local_ip:-N/A}"
    else
        echo "Local IP: ip command not found"
    fi

    if command -v curl >/dev/null 2>&1; then
        local public_ip
        public_ip=$(curl -s https://ipinfo.io/ip)
        echo "Public IP: ${public_ip:-N/A}"
    else
        echo "Public IP: curl command not found"
    fi

    echo "Timestamp: $TS"
}

# Check a single network port status
portcheck() {
    local port=$1

    if [[ -z $port ]]; then
        echo "Usage: portcheck <port>"
        return 1
    fi

    echo "=== Port Check: $port ==="

    local output
    if command -v ss &>/dev/null; then
        output=$(ss -tuln 2>/dev/null | grep ":$port ")
    elif command -v netstat &>/dev/null; then
        output=$(netstat -tuln 2>/dev/null | grep ":$port ")
    else
        echo "Error: Neither ss nor netstat is available"
        return 1
    fi

    if [[ -n $output ]]; then
        echo "$output"
    else
        echo "Port $port is not listening"
    fi

    echo "Timestamp: $(date '+%d-%m-%Y %H:%M:%S')"
}

# Display Network Info (function)
netinfo() {
    print -P "Network Information:"
    print -P "==================="
    print -P "Local IP: $(ip route get 1 | awk '{print $NF;exit}')"
    print -P "Public IP: $(curl -s https://ipinfo.io/ip)"
    print -P "DNS Servers:"
    grep nameserver /etc/resolv.conf
    print -P "Active Connections:"
    ss -tuln
}

# Network Usage
network_usage() {
    local opt="$1"
    case "$opt" in
        -i|--interfaces)
            if ! command -v ip &>/dev/null; then
                echo "ip command is required for this option"
                return 1
            fi
            echo "=== Network Interfaces ==="
            ip -br addr 2>/dev/null
            ;;
        -s|--stats)
            if ! command -v netstat &>/dev/null; then
                echo "netstat command is required for this option"
                return 1
            fi
            echo "=== Network Statistics ==="
            netstat -i 2>/dev/null
            ;;
        *)
            echo "Usage: network_usage [-i|--interfaces] [-s|--stats]"
            return 1
            ;;
    esac

    echo
    echo "Scan completed at: $(date '+%d-%m-%Y %H:%M:%S')"
}


# Check which processes are listening on network ports
netlistening() {
    if ! command -v lsof &>/dev/null; then
        echo "lsof command is required for this function"
        return 1
    fi

    echo "=== Network Listeners ==="
    printf "%-6s %-8s %-8s %-7s %s\n" "PID" "USER" "PROTO" "PORT" "COMMAND"
    
    local output
    output=$(lsof -i -P -n 2>/dev/null | awk '/LISTEN/ {
        split($9, a, ":");
        port=a[length(a)];
        printf "%-6s %-8s %-8s %-7s %s\n", $2, $3, $1, port, $1
    }')

    if [[ -n $output ]]; then
        echo "$output"
    else
        echo "No listening network processes detected"
    fi
}



