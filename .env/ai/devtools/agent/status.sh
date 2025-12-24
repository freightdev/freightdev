#!/bin/bash
# CoDriver Agent Services - Status Check Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/src/scripts"

if [ -f "$SCRIPTS_DIR/status-check.sh" ]; then
    bash "$SCRIPTS_DIR/status-check.sh"
else
    echo "⚠️  Status script not found at: $SCRIPTS_DIR/status-check.sh"
    exit 1
fi
