#!/bin/bash
# CoDriver Agent Services - Stop Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/src/scripts"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}Stopping CoDriver Agent Services${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""

if [ -f "$SCRIPTS_DIR/stop-agency.sh" ]; then
    bash "$SCRIPTS_DIR/stop-agency.sh"
else
    echo "⚠️  Stop script not found at: $SCRIPTS_DIR/stop-agency.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}Agent services stopped${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo ""
