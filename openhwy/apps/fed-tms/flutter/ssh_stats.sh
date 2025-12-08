#!/bin/bash
# SSH Stats Collector
# Gathers real stats from remote systems

SYSTEM=$1

if [ -z "$SYSTEM" ]; then
    echo "Usage: $0 <system>"
    exit 1
fi

# SSH and collect stats
ssh -o ConnectTimeout=5 admin@$SYSTEM 'bash -s' << 'EOF'
#!/bin/bash

# CPU usage
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Memory usage
MEM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')

# Disk usage
DISK=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

# Load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

# Uptime
UPTIME=$(uptime -p | sed 's/up //')

# Running agents (moon-env processes)
AGENTS=$(ps aux | grep -c moon-env | awk '{print $1-1}')

# Network connections
CONNECTIONS=$(ss -s | grep estab | awk '{print $2}')

# Output as JSON
cat << JSON
{
  "cpu": $CPU,
  "memory": $MEM,
  "memory_total": "$MEM_TOTAL",
  "disk": $DISK,
  "load": $LOAD,
  "uptime": "$UPTIME",
  "agents": $AGENTS,
  "connections": "$CONNECTIONS"
}
JSON
EOF
