#!/usr/bin/env bash
# CoDriver - Start All Microservices
# Plug-and-play microservices startup script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     CoDriver Microservices - Startup Manager              ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo

# Services configuration
declare -A SERVICES=(
    ["auth"]="auth.todo:9020"
    ["payment"]="payment.todo:9021"
    ["email"]="email.todo:9011"
    ["user"]="user.todo:9022"
)

PID_DIR="$SCRIPT_DIR/../var/runtime/pids"
LOG_DIR="$SCRIPT_DIR/../var/logs"

mkdir -p "$PID_DIR"
mkdir -p "$LOG_DIR"

# Function to check if service is running
is_running() {
    local service=$1
    local pidfile="$PID_DIR/${service}.pid"

    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$pidfile"
        fi
    fi
    return 1
}

# Function to start a service
start_service() {
    local name=$1
    local dir=$2
    local port=$3

    if is_running "$name"; then
        echo -e "${YELLOW}⚠️  $name service already running${NC}"
        return 0
    fi

    if [ ! -d "$dir" ]; then
        echo -e "${RED}❌ Service directory not found: $dir${NC}"
        return 1
    fi

    if [ ! -f "$dir/start.sh" ]; then
        echo -e "${RED}❌ Start script not found: $dir/start.sh${NC}"
        return 1
    fi

    echo -e "${BLUE}🚀 Starting $name service (port $port)...${NC}"

    cd "$dir"

    # Start service in background
    nohup ./start.sh > "$LOG_DIR/${name}.log" 2>&1 &
    local pid=$!

    # Save PID
    echo $pid > "$PID_DIR/${name}.pid"

    # Wait a moment and check if still running
    sleep 2
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name service started (PID: $pid)${NC}"
        return 0
    else
        echo -e "${RED}❌ $name service failed to start${NC}"
        rm -f "$PID_DIR/${name}.pid"
        return 1
    fi
}

# Function to stop a service
stop_service() {
    local name=$1
    local pidfile="$PID_DIR/${name}.pid"

    if [ ! -f "$pidfile" ]; then
        echo -e "${YELLOW}⚠️  $name service not running${NC}"
        return 0
    fi

    local pid=$(cat "$pidfile")

    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${BLUE}🛑 Stopping $name service (PID: $pid)...${NC}"
        kill $pid

        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! ps -p $pid > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $name service stopped${NC}"
                rm -f "$pidfile"
                return 0
            fi
            sleep 1
        done

        # Force kill if still running
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Force killing $name service${NC}"
            kill -9 $pid
        fi

        rm -f "$pidfile"
    else
        echo -e "${YELLOW}⚠️  $name service not running (removing stale PID)${NC}"
        rm -f "$pidfile"
    fi
}

# Function to show service status
show_status() {
    echo
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}     Service Status                                         ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo

    for name in "${!SERVICES[@]}"; do
        IFS=':' read -r dir port <<< "${SERVICES[$name]}"

        if is_running "$name"; then
            local pid=$(cat "$PID_DIR/${name}.pid")
            echo -e "${GREEN}✅ $name${NC} - Running (PID: $pid, Port: $port)"
        else
            echo -e "${RED}❌ $name${NC} - Stopped (Port: $port)"
        fi
    done

    echo
}

# Main script
case "${1:-start}" in
    start)
        echo -e "${BLUE}Starting all microservices...${NC}"
        echo

        for name in "${!SERVICES[@]}"; do
            IFS=':' read -r dir port <<< "${SERVICES[$name]}"
            start_service "$name" "$SCRIPT_DIR/$dir" "$port"
        done

        show_status

        echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}Access Points:${NC}"
        echo -e "  Auth Service:    http://localhost:9020"
        echo -e "  Payment Service: http://localhost:9021"
        echo -e "  Email Service:   http://localhost:9011"
        echo -e "  User Service:    http://localhost:9022"
        echo
        echo -e "${YELLOW}Logs:${NC} $LOG_DIR"
        echo -e "${YELLOW}PIDs:${NC} $PID_DIR"
        echo
        echo -e "${GREEN}To stop all services, run: $0 stop${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
        ;;

    stop)
        echo -e "${BLUE}Stopping all microservices...${NC}"
        echo

        for name in "${!SERVICES[@]}"; do
            stop_service "$name"
        done

        echo
        echo -e "${GREEN}All services stopped${NC}"
        ;;

    restart)
        $0 stop
        sleep 2
        $0 start
        ;;

    status)
        show_status
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
