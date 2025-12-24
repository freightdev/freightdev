#!/bin/bash
# CoDriver Agent Services - Master Startup Script
# Starts all AI agent services including managers, tools, and engines

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/src/scripts"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}CoDriver Agent Services${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

# Check if SurrealDB is running
echo -e "${BLUE}Checking dependencies...${NC}"
if ! curl -s http://192.168.12.66:8000/health > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  SurrealDB not reachable at http://192.168.12.66:8000${NC}"
    echo -e "${YELLOW}   Make sure SurrealDB is running before starting agents${NC}"
    echo ""
fi

# Start all agent services
echo -e "${BLUE}Starting agent services...${NC}"
echo ""

if [ -f "$SCRIPTS_DIR/start-agency.sh" ]; then
    bash "$SCRIPTS_DIR/start-agency.sh"
else
    echo -e "${YELLOW}⚠️  Start script not found at: $SCRIPTS_DIR/start-agency.sh${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Agent services startup complete!${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""
