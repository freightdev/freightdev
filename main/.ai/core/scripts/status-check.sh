#!/bin/bash
# Check status of all AI Agency services

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}CoDriver Agent Services - Status${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

check_port() {
    local port=$1
    local name=$2

    if nc -z 127.0.0.1 "$port" 2>/dev/null; then
        echo -e "${GREEN}✅ $name${NC} (port $port)"
        return 0
    else
        echo -e "${RED}❌ $name${NC} (port $port)"
        return 1
    fi
}

check_http() {
    local url=$1
    local name=$2

    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC} ($url)"
        return 0
    else
        echo -e "${RED}❌ $name${NC} ($url)"
        return 1
    fi
}

echo -e "${BLUE}━━━ Managers ━━━${NC}"
check_http "http://127.0.0.1:9020/health" "Conversation Manager"
check_http "http://127.0.0.1:9012/health" "Database Manager"
check_http "http://127.0.0.1:9019/health" "Lead Manager"
check_http "http://127.0.0.1:9000/health" "Service Manager"

echo ""
echo -e "${BLUE}━━━ AI Tools ━━━${NC}"
check_http "http://127.0.0.1:9014/health" "File Operations"
check_http "http://127.0.0.1:9008/health" "Code Assistant"
check_http "http://127.0.0.1:9006/health" "Data Collector"
check_http "http://127.0.0.1:9017/health" "Web Scraper"
check_http "http://127.0.0.1:9018/health" "Web Searcher"
check_http "http://127.0.0.1:9013/health" "Lead Scraper"
check_http "http://127.0.0.1:9014/health" "Lead Analyzer"

echo ""
echo -e "${BLUE}━━━ Services ━━━${NC}"
check_http "http://127.0.0.1:9011/health" "Message Service"
check_http "http://127.0.0.1:9021/health" "PDF Service"
check_http "http://127.0.0.1:9022/health" "Vision Service"
check_http "http://127.0.0.1:9023/health" "Screen Service"
check_http "http://127.0.0.1:9024/health" "Audit Service"

echo ""
echo -e "${BLUE}━━━ Engines ━━━${NC}"
check_http "http://127.0.0.1:9016/health" "Workflow Engine"

echo ""
echo -e "${BLUE}━━━ System Status ━━━${NC}"

# Get service manager status if available
if curl -s "http://127.0.0.1:9000/status" > /dev/null 2>&1; then
    echo -e "\n${BLUE}Detailed Status:${NC}"
    curl -s "http://127.0.0.1:9000/status" | python3 -m json.tool 2>/dev/null || echo "Unable to parse status"
fi

echo ""
