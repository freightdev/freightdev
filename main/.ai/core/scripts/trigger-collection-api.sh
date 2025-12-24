#!/bin/bash
# API endpoint to trigger data collection
# This allows CoDriver or other services to trigger collection on-demand

case "$1" in
  trucking)
    systemctl --user start trucking-collector.service
    echo "✅ Trucking collection triggered"
    ;;
  housing)
    systemctl --user start housing-collector.service
    echo "✅ Housing collection triggered"
    ;;
  both)
    systemctl --user start trucking-collector.service
    systemctl --user start housing-collector.service
    echo "✅ Both collections triggered"
    ;;
  *)
    echo "Usage: $0 {trucking|housing|both}"
    exit 1
    ;;
esac

# Wait a moment, then show status
sleep 2
journalctl --user -u trucking-collector.service -n 10 --no-pager 2>/dev/null
journalctl --user -u housing-collector.service -n 10 --no-pager 2>/dev/null
