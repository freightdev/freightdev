#!/bin/bash
# Check status of all lead generation services

echo "📊 Lead Generation System Status"
echo "=================================="
echo ""

services=(
    "surrealdb"
    "llamacpp"
    "lead-scraper"
    "lead-analyzer"
    "lead-manager"
)

for service in "${services[@]}"; do
    status=$(systemctl --user is-active "$service.service" 2>/dev/null || echo "inactive")

    if [ "$status" = "active" ]; then
        echo "✓ $service: 🟢 RUNNING"
    else
        echo "✗ $service: 🔴 STOPPED"
    fi
done

echo ""
echo "Timer Status:"
timer_status=$(systemctl --user is-active lead-scraper-daily.timer 2>/dev/null || echo "inactive")
if [ "$timer_status" = "active" ]; then
    echo "✓ Daily scraper timer: 🟢 ENABLED"
    systemctl --user status lead-scraper-daily.timer --no-pager 2>/dev/null | grep "Trigger:" || true
else
    echo "✗ Daily scraper timer: 🔴 DISABLED"
fi

echo ""
echo "Port Status:"
ports=("8000:SurrealDB" "11435:LLM" "9013:Scraper" "9014:Analyzer" "9015:Manager")

for port_info in "${ports[@]}"; do
    port="${port_info%%:*}"
    name="${port_info##*:}"

    if ss -tlnp 2>/dev/null | grep -q ":$port "; then
        echo "✓ Port $port ($name): 🟢 LISTENING"
    else
        echo "✗ Port $port ($name): 🔴 NOT LISTENING"
    fi
done
