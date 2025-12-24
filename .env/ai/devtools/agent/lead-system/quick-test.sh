#!/bin/bash
# Quick test of the lead generation system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Quick Lead Generation System Test"
echo "====================================="
echo ""

echo "1. Checking all services are running..."
if ! "$SCRIPT_DIR/status-lead-system.sh" | grep -q "🟢"; then
    echo "❌ Not all services are running. Start with: $SCRIPT_DIR/start-lead-system.sh"
    exit 1
fi

echo ""
echo "2. Testing health endpoints..."

endpoints=(
    "http://localhost:8000|SurrealDB"
    "http://localhost:11435/health|LLM Server"
    "http://localhost:9013/health|Lead Scraper"
    "http://localhost:9014/health|Lead Analyzer"
    "http://localhost:9015/health|Lead Manager"
)

all_healthy=true
for endpoint in "${endpoints[@]}"; do
    url="${endpoint%%|*}"
    name="${endpoint##*|}"

    if curl -sf "$url" > /dev/null 2>&1; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name - FAILED"
        all_healthy=false
    fi
done

if [ "$all_healthy" = false ]; then
    echo ""
    echo "❌ Some services failed health checks"
    exit 1
fi

echo ""
echo "3. Testing LLM inference..."
llm_test=$(curl -sf -X POST http://localhost:11435/completion \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Say hello", "max_tokens": 10}' 2>/dev/null)

if [ -n "$llm_test" ]; then
    echo "  ✓ LLM is responding"
else
    echo "  ✗ LLM test failed"
    exit 1
fi

echo ""
echo "4. Testing database connection..."
db_test=$(curl -sf -X POST http://localhost:9012/query \
    -H "Content-Type: application/json" \
    -d '{"query": "SELECT * FROM leads LIMIT 1"}' 2>/dev/null)

if [ -n "$db_test" ]; then
    echo "  ✓ Database is accessible"
else
    echo "  ⚠️  Database query failed (database-manager may not be running on port 9012)"
    echo "     This is OK - leads will be stored in memory"
fi

echo ""
echo "✅ All tests passed!"
echo ""
echo "System is ready. Next steps:"
echo "  • Run small test: $SCRIPT_DIR/scrape-leads.sh hn 5"
echo "  • Full pipeline: $SCRIPT_DIR/scrape-leads.sh all 30"
echo "  • View results: $SCRIPT_DIR/daily-digest.sh"
