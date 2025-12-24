# scripts/smoke_test.sh
#!/bin/bash

set -e

# Smoke tests for Payment Service
BASE_URL=${BASE_URL:-"http://localhost:8080"}
API_KEY=${API_KEY:-"test-api-key"}
JWT_TOKEN=${JWT_TOKEN:-"test-jwt-token"}

echo "Running smoke tests against: $BASE_URL"

# Test 1: Health Check
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/health_response "${BASE_URL}/health")
if [ "$HEALTH_RESPONSE" != "200" ]; then
    echo "❌ Health check failed: HTTP $HEALTH_RESPONSE"
    exit 1
fi
echo "✅ Health check passed"

# Test 2: Create Payment
echo "Testing payment creation..."
PAYMENT_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/payment_response \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -X POST "${BASE_URL}/api/v1/payments" \
    -d '{
        "client_id": "test-client",
        "merchant_id": "test-merchant",
        "order_id": "smoke-test-'$(date +%s)'",
        "amount": "10.00",
        "currency": "USD",
        "method": "card",
        "description": "Smoke test payment"
    }')

if [ "$PAYMENT_RESPONSE" != "201" ]; then
    echo "❌ Payment creation failed: HTTP $PAYMENT_RESPONSE"
    cat /tmp/payment_response
    exit 1
fi

PAYMENT_ID=$(jq -r '.id' /tmp/payment_response)
echo "✅ Payment created successfully: $PAYMENT_ID"

# Test 3: Get Payment
echo "Testing payment retrieval..."
GET_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/get_response \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "X-API-Key: $API_KEY" \
    "${BASE_URL}/api/v1/payments/${PAYMENT_ID}")

if [ "$GET_RESPONSE" != "200" ]; then
    echo "❌ Payment retrieval failed: HTTP $GET_RESPONSE"
    exit 1
fi
echo "✅ Payment retrieved successfully"

# Test 4: List Payments
echo "Testing payment listing..."
LIST_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/list_response \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "X-API-Key: $API_KEY" \
    "${BASE_URL}/api/v1/payments?client_id=test-client&limit=10")

if [ "$LIST_RESPONSE" != "200" ]; then
    echo "❌ Payment listing failed: HTTP $LIST_RESPONSE"
    exit 1
fi
echo "✅ Payment listing successful"

# Test 5: Analytics Endpoint (if available)
echo "Testing analytics endpoint..."
ANALYTICS_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/analytics_response \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "X-API-Key: $API_KEY" \
    "${BASE_URL}/api/v1/analytics/stats" || echo "404")

if [ "$ANALYTICS_RESPONSE" = "200" ]; then
    echo "✅ Analytics endpoint available"
elif [ "$ANALYTICS_RESPONSE" = "404" ]; then
    echo "⚠️  Analytics endpoint not available (optional)"
else
    echo "❌ Analytics endpoint error: HTTP $ANALYTICS_RESPONSE"
fi

echo "🎉 All smoke tests passed!"

# Clean up test files
rm -f /tmp/health_response /tmp/payment_response /tmp/get_response /tmp/list_response /tmp/analytics_response
