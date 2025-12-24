#!/usr/bin/env bash
# Test SurrealDB connection and basic operations

set -e

ENDPOINT="http://127.0.0.1:8000"
USER="codriver_coordinator"
PASS="changeme"
NS="openhwy"
DB="codriver_agency"

echo "Testing SurrealDB connection..."
echo ""

# Test 1: Query prompts table
echo "=== Test 1: Query prompts table ==="
echo "SELECT * FROM prompts;" | /home/admin/.surrealdb/surreal sql \
  --endpoint "$ENDPOINT" \
  --username "$USER" \
  --password "$PASS" \
  --namespace "$NS" \
  --database "$DB"

echo ""
echo "=== Test 2: Insert test log ==="
echo "INSERT INTO operation_logs {
  level: 'info',
  agent: 'test',
  operation: 'connection_test',
  details: { message: 'Testing database connection' },
  duration_ms: 0,
  success: true
};" | /home/admin/.surrealdb/surreal sql \
  --endpoint "$ENDPOINT" \
  --username "$USER" \
  --password "$PASS" \
  --namespace "$NS" \
  --database "$DB"

echo ""
echo "=== Test 3: Query recent logs ==="
echo "SELECT * FROM operation_logs ORDER BY timestamp DESC LIMIT 5;" | /home/admin/.surrealdb/surreal sql \
  --endpoint "$ENDPOINT" \
  --username "$USER" \
  --password "$PASS" \
  --namespace "$NS" \
  --database "$DB"

echo ""
echo "Database connection test complete!"
