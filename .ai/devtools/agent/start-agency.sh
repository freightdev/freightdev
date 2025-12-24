#!/bin/bash
# Start all CoDriver Agent services

AGENT_ROOT="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo"
LOG_DIR="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/logs/agents"
PID_DIR="/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/var/pids"

mkdir -p "$LOG_DIR" "$PID_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}Starting CoDriver Agent Services${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

start_service() {
    local name=$1
    local binary=$2
    local port=$3

    if [ -f "$PID_DIR/$name.pid" ]; then
        local pid=$(cat "$PID_DIR/$name.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  $name already running (PID: $pid)${NC}"
            return 0
        fi
    fi

    echo -e "${BLUE}Starting $name on port $port...${NC}"

    nohup "$binary" > "$LOG_DIR/$name.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_DIR/$name.pid"

    sleep 1

    if ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name started (PID: $pid)${NC}"
        return 0
    else
        echo -e "${RED}❌ $name failed to start${NC}"
        return 1
    fi
}

# Start Core Services
echo -e "\n${BLUE}━━━ Core Services ━━━${NC}"

if [ -f "$AGENT_ROOT/core/managers/service-manager/target/release/service-manager" ]; then
    start_service "service-manager" "$AGENT_ROOT/core/managers/service-manager/target/release/service-manager" "9000"
fi

if [ -f "$AGENT_ROOT/core/managers/conversation-manager/target/release/conversation-manager" ]; then
    start_service "conversation-manager" "$AGENT_ROOT/core/managers/conversation-manager/target/release/conversation-manager" "9020"
fi

if [ -f "$AGENT_ROOT/core/managers/database-manager/target/release/database-manager" ]; then
    start_service "database-manager" "$AGENT_ROOT/core/managers/database-manager/target/release/database-manager" "9012"
fi

if [ -f "$AGENT_ROOT/core/managers/lead-manager/target/release/lead-manager" ]; then
    start_service "lead-manager" "$AGENT_ROOT/core/managers/lead-manager/target/release/lead-manager" "9019"
fi

# Start AI Tools
echo -e "\n${BLUE}━━━ AI Tools ━━━${NC}"

if [ -f "$AGENT_ROOT/core/ai-tools/file-operations/target/release/file-operations" ]; then
    start_service "file-operations" "$AGENT_ROOT/core/ai-tools/file-operations/target/release/file-operations" "9014"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/code-assistant/target/release/code-assistant" ]; then
    start_service "code-assistant" "$AGENT_ROOT/core/ai-tools/code-assistant/target/release/code-assistant" "9008"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/data-collector/target/release/data-collector" ]; then
    start_service "data-collector" "$AGENT_ROOT/core/ai-tools/data-collector/target/release/data-collector" "9006"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/web-scraper/target/release/web-scraper" ]; then
    start_service "web-scraper" "$AGENT_ROOT/core/ai-tools/web-scraper/target/release/web-scraper" "9017"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/web-searcher/target/release/web-searcher" ]; then
    start_service "web-searcher" "$AGENT_ROOT/core/ai-tools/web-searcher/target/release/web-searcher" "9018"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/lead-scraper/target/release/lead-scraper" ]; then
    start_service "lead-scraper" "$AGENT_ROOT/core/ai-tools/lead-scraper/target/release/lead-scraper" "9013"
fi

if [ -f "$AGENT_ROOT/core/ai-tools/lead-analyzer/target/release/lead-analyzer" ]; then
    start_service "lead-analyzer" "$AGENT_ROOT/core/ai-tools/lead-analyzer/target/release/lead-analyzer" "9014"
fi

# Start Services
echo -e "\n${BLUE}━━━ Agent Services ━━━${NC}"

if [ -f "$AGENT_ROOT/core/services/message-service/target/release/message-service" ]; then
    start_service "message-service" "$AGENT_ROOT/core/services/message-service/target/release/message-service" "9011"
fi

if [ -f "$AGENT_ROOT/core/services/pdf-service/target/release/pdf-service" ]; then
    start_service "pdf-service" "$AGENT_ROOT/core/services/pdf-service/target/release/pdf-service" "9021"
fi

if [ -f "$AGENT_ROOT/core/services/vision-service/target/release/vision-service" ]; then
    start_service "vision-service" "$AGENT_ROOT/core/services/vision-service/target/release/vision-service" "9022"
fi

if [ -f "$AGENT_ROOT/core/services/screen-service/target/release/screen-service" ]; then
    start_service "screen-service" "$AGENT_ROOT/core/services/screen-service/target/release/screen-service" "9023"
fi

if [ -f "$AGENT_ROOT/core/services/audit-service/target/release/audit-service" ]; then
    start_service "audit-service" "$AGENT_ROOT/core/services/audit-service/target/release/audit-service" "9024"
fi

# Start Workflow Engine
if [ -f "$AGENT_ROOT/core/engines/workflow-engine/target/release/workflow-engine" ]; then
    start_service "workflow-engine" "$AGENT_ROOT/core/engines/workflow-engine/target/release/workflow-engine" "9016"
fi

# Show status
echo ""
echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}Service Status${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

for pidfile in "$PID_DIR"/*.pid; do
    if [ -f "$pidfile" ]; then
        name=$(basename "$pidfile" .pid)
        pid=$(cat "$pidfile")

        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $name (PID: $pid)${NC}"
        else
            echo -e "${RED}❌ $name (not running)${NC}"
        fi
    fi
done

echo ""
echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}Access Points${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""
echo -e "  ${GREEN}Conversation Manager:${NC}  http://127.0.0.1:9020"
echo -e "  ${GREEN}Database Manager:${NC}     http://127.0.0.1:9012"
echo -e "  ${GREEN}File Operations:${NC}      http://127.0.0.1:9014"
echo -e "  ${GREEN}Code Assistant:${NC}       http://127.0.0.1:9008"
echo ""
echo -e "${YELLOW}Logs:${NC} $LOG_DIR"
echo -e "${YELLOW}PIDs:${NC} $PID_DIR"
echo ""
echo -e "${GREEN}To stop all services, run: ./stop-agent-services.sh${NC}"
echo ""
