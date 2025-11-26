# scripts/health-check.sh
#!/bin/bash

# Health check script for monitoring

set -e

BASE_URL=${BASE_URL:-http://localhost:8080}
TIMEOUT=${TIMEOUT:-10}

echo "🏥 Performing health check..."

# Check main health endpoint
response=$(curl -s -w "\n%{http_code}" --connect-timeout $TIMEOUT "$BASE_URL/health" || echo -e "\n000")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Health check passed"
    echo "Response: $body"
    exit 0
else
    echo "❌ Health check failed"
    echo "HTTP Code: $http_code"
    echo "Response: $body"
    exit 1
fi
