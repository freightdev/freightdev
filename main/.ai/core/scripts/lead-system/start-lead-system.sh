#!/bin/bash
# Start all lead generation services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🚀 Starting Lead Generation System"
echo "===================================="
echo ""

# Start services in order
echo "1️⃣  Starting SurrealDB..."
systemctl --user start surrealdb.service
sleep 2

echo "2️⃣  Starting LLM Server (llama.cpp)..."
systemctl --user start llamacpp.service
sleep 3

echo "3️⃣  Starting Lead Scraper..."
systemctl --user start lead-scraper.service
sleep 1

echo "4️⃣  Starting Lead Analyzer..."
systemctl --user start lead-analyzer.service
sleep 1

echo "5️⃣  Starting Lead Manager..."
systemctl --user start lead-manager.service
sleep 2

echo ""
echo "✅ All services started!"
echo ""
echo "Checking health..."
echo ""

# Health checks
services=(
    "SurrealDB:http://localhost:8000"
    "LLM Server:http://localhost:11435/health"
    "Lead Scraper:http://localhost:9013/health"
    "Lead Analyzer:http://localhost:9014/health"
    "Lead Manager:http://localhost:9015/health"
)

for service in "${services[@]}"; do
    name="${service%%:*}"
    url="${service##*:}"

    if curl -s "$url" > /dev/null 2>&1; then
        echo "✓ $name - OK"
    else
        echo "✗ $name - FAILED"
    fi
done

echo ""
echo "🎯 System ready!"
echo ""
echo "Next steps:"
echo "  - Run pipeline: $SCRIPT_DIR/scrape-leads.sh"
echo "  - View digest: $SCRIPT_DIR/daily-digest.sh"
echo "  - Check logs: journalctl --user -u lead-manager -f"
echo "  - Full docs: $PROJECT_ROOT/docs/guides/LEAD_GENERATION.md"
