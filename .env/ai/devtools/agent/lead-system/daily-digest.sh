#!/bin/bash
# Generate daily digest of top leads

set -e

echo "📧 Generating Daily Lead Digest"
echo "================================"
echo ""

# Check if lead-manager is running
if ! curl -s http://localhost:9015/health > /dev/null 2>&1; then
    echo "❌ Lead manager is not running. Start it with: systemctl --user start lead-manager"
    exit 1
fi

# Minimum fit score (default 0.6)
MIN_SCORE="${1:-0.6}"

echo "🎯 Fetching leads with fit score >= $MIN_SCORE..."
echo ""

RESPONSE=$(curl -s "http://localhost:9015/daily-digest?min_score=$MIN_SCORE")

# Pretty print and format
echo "$RESPONSE" | python3 -c "
import sys
import json

data = json.load(sys.stdin)

print(f\"📅 Date: {data['date']}\")
print(f\"📊 Total Leads: {data['total_leads']}\")
print()
print('🏆 Top Leads:')
print('=' * 80)

for i, lead in enumerate(data['top_leads'], 1):
    score = lead.get('fit_score', 0)
    bars = '█' * int(score * 10)

    print(f\"\n{i}. {lead['title']}\")
    print(f\"   Score: {bars} {score:.2f}\")
    print(f\"   Source: {lead['source']}\")
    print(f\"   Category: {lead['category']} | Pricing: {lead['pricing']}\")
    print(f\"   URL: {lead['url']}\")

print()
print('=' * 80)
" 2>/dev/null || echo "$RESPONSE" | python3 -m json.tool

echo ""
echo "✅ Digest generated successfully!"
