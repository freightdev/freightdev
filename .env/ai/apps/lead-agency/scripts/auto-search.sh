#!/bin/bash
#
# Lead Agency Auto Search Script
# Runs automated lead search and logs results
#
# Usage: ./auto-search.sh
# Cron: 0 9,18 * * * /home/admin/freightdev/openhwy/.ai/lead-agency-v2/scripts/auto-search.sh

set -e

# Configuration
API_URL="http://localhost:8000"
LOG_DIR="/home/admin/freightdev/openhwy/.ai/agencies/lead-agency/logs"
LOG_FILE="$LOG_DIR/auto-search-$(date +%Y-%m-%d).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "Starting automated lead search..."
log "========================================"

# Check if API is running
if ! curl -s "$API_URL" > /dev/null; then
    log "ERROR: API is not running at $API_URL"
    exit 1
fi

log "API is running ✓"

# Start lead search
log "Initiating search request..."
SEARCH_RESPONSE=$(curl -s -X POST "$API_URL/api/search" \
    -H "Content-Type: application/json" \
    -d '{
        "categories": ["web_development"],
        "min_budget": 1000,
        "sources": ["reddit", "hackernews"],
        "min_score": 70
    }')

SEARCH_ID=$(echo "$SEARCH_RESPONSE" | grep -o '"search_id":"[^"]*' | cut -d'"' -f4)

if [ -z "$SEARCH_ID" ]; then
    log "ERROR: Failed to start search"
    log "Response: $SEARCH_RESPONSE"
    exit 1
fi

log "Search started: $SEARCH_ID"
log "Estimated time: 5-10 minutes"

# Wait for search to complete (10 minutes max)
log "Waiting for search to complete..."
sleep 600

# Get final stats
log "Fetching results..."
STATS=$(curl -s "$API_URL/api/stats")

TOTAL_LEADS=$(echo "$STATS" | grep -o '"total_leads":[0-9]*' | cut -d':' -f2)
QUALIFIED_LEADS=$(echo "$STATS" | grep -o '"qualified_leads":[0-9]*' | cut -d':' -f2)
AVG_SCORE=$(echo "$STATS" | grep -o '"average_score":[0-9.]*' | cut -d':' -f2)

log "========================================"
log "Search Results:"
log "  Total Leads: $TOTAL_LEADS"
log "  Qualified Leads: $QUALIFIED_LEADS"
log "  Average Score: $AVG_SCORE"
log "========================================"

# Get top 5 qualified leads
log "Top 5 qualified leads:"
TOP_LEADS=$(curl -s "$API_URL/api/leads?min_score=70&limit=5")
echo "$TOP_LEADS" | python3 -m json.tool >> "$LOG_FILE" 2>&1 || log "  (Could not parse lead details)"

log "Search complete! ✓"
log "View leads at: http://localhost:3000"
log "========================================"

# Keep last 30 days of logs only
find "$LOG_DIR" -name "auto-search-*.log" -mtime +30 -delete

exit 0
