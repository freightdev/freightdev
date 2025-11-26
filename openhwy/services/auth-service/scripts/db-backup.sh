# scripts/db-backup.sh
#!/bin/bash

# Database backup script

set -e

# Configuration
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-auth_service}
DB_USER=${DB_USER:-postgres}
BACKUP_DIR=${BACKUP_DIR:-./backups}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql"

echo "📦 Starting database backup..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
PGPASSWORD=$DB_PASSWORD pg_dump \
  -h $DB_HOST \
  -p $DB_PORT \
  -U $DB_USER \
  -d $DB_NAME \
  --no-owner \
  --no-privileges \
  --clean \
  --if-exists \
  > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

echo "✅ Database backup completed: ${BACKUP_FILE}.gz"

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "${DB_NAME}_backup_*.sql.gz" -mtime +7 -delete

echo "🧹 Old backups cleaned up"
