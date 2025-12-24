#!/bin/bash
# Stop all CoDriver Agent services

PID_DIR="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/pids"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}Stopping CoDriver Agent Services${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

if [ ! -d "$PID_DIR" ]; then
    echo -e "${RED}No services running (PID directory not found)${NC}"
    exit 0
fi

for pidfile in "$PID_DIR"/*.pid; do
    if [ -f "$pidfile" ]; then
        name=$(basename "$pidfile" .pid)
        pid=$(cat "$pidfile")

        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${BLUE}Stopping $name (PID: $pid)...${NC}"
            kill "$pid"
            sleep 1

            if ! ps -p "$pid" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $name stopped${NC}"
                rm "$pidfile"
            else
                echo -e "${RED}⚠️  Force killing $name${NC}"
                kill -9 "$pid"
                rm "$pidfile"
            fi
        else
            echo -e "${RED}❌ $name not running (removing stale PID file)${NC}"
            rm "$pidfile"
        fi
    fi
done

echo ""
echo -e "${GREEN}All services stopped${NC}"
echo ""
