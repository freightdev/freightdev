#!/bin/bash
# One-command setup to start automatic data collection

echo "🚀 Starting Automatic Data Collection"
echo "======================================"
echo ""

# Enable and start timers
echo "⏰ Enabling timers..."
systemctl --user enable trucking-collector.timer 2>/dev/null
systemctl --user enable housing-collector.timer 2>/dev/null
systemctl --user start trucking-collector.timer
systemctl --user start housing-collector.timer

echo "✅ Timers enabled and started!"
echo ""

# Show status
echo "📊 Timer Status:"
systemctl --user list-timers | grep collector || echo "  (Timers will appear after first run)"
echo ""

echo "📅 Collection Schedule:"
echo "  • Trucking: Daily at 8:00 AM"
echo "  • Housing: Twice daily at 9:00 AM and 6:00 PM"
echo ""

echo "🔍 Management Commands:"
echo "  • Check status:    systemctl --user list-timers"
echo "  • View logs:       journalctl --user -u trucking-collector.service -f"
echo "  • Stop timers:     systemctl --user stop trucking-collector.timer"
echo "  • Trigger now:     /collect-data trucking"
echo ""

echo "📁 Collected data will appear in:"
echo "  • Trucking: ~/.ai/data/trucking/"
echo "  • Housing:  ~/.ai/data/housing/"
echo ""

echo "✅ Automatic collection is now running!"
echo ""

# Offer to trigger first collection
read -p "Trigger first collection now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔄 Triggering trucking collection..."
    systemctl --user start trucking-collector.service
    echo "✅ Collection started! Check logs: tail -f ~/.ai/data/logs/trucking-collector.log"
fi
