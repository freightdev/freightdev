#!/bin/bash
# Scrape leads from all sources and analyze them

set -e

echo "🔍 Starting lead scraping and analysis pipeline..."
echo ""

# Check if lead-manager is running
if ! curl -s http://localhost:9015/health > /dev/null 2>&1; then
    echo "❌ Lead manager is not running. Start it with: systemctl --user start lead-manager"
    exit 1
fi

# Default values
SOURCE="${1:-all}"
LIMIT="${2:-50}"

echo "📊 Configuration:"
echo "  Source: $SOURCE"
echo "  Limit: $LIMIT leads per source"
echo ""

# Run scrape and analyze
echo "🚀 Executing pipeline..."
RESPONSE=$(curl -s -X POST http://localhost:9015/scrape-and-analyze \
    -H "Content-Type: application/json" \
    -d "{\"source\": \"$SOURCE\", \"limit\": $LIMIT}")

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

echo ""
echo "✅ Pipeline complete!"
echo ""
echo "View results with: ./daily-digest.sh"
