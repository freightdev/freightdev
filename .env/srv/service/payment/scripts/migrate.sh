# scripts/migrate.sh
#!/bin/bash

set -e

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-password}
DB_NAME=${DB_NAME:-payment_service}
DB_SSLMODE=${DB_SSL_MODE:-disable}

# Migration parameters
MIGRATIONS_PATH=${MIGRATIONS_PATH:-migrations}
DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

# Check if migrate tool is installed
if ! command -v migrate &> /dev/null; then
    echo "migrate tool is not installed. Installing..."
    go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
fi

# Parse command line arguments
COMMAND=${1:-"up"}

case $COMMAND in
    "up")
        echo "Running database migrations up..."
        migrate -path $MIGRATIONS_PATH -database "$DATABASE_URL" up
        ;;
    "down")
        echo "Running database migrations down..."
        migrate -path $MIGRATIONS_PATH -database "$DATABASE_URL" down
        ;;
    "drop")
        echo "Dropping database..."
        migrate -path $MIGRATIONS_PATH -database "$DATABASE_URL" drop -f
        ;;
    "version")
        echo "Checking migration version..."
        migrate -path $MIGRATIONS_PATH -database "$DATABASE_URL" version
        ;;
    "force")
        if [ -z "$2" ]; then
            echo "Please provide version number: ./migrate.sh force <version>"
            exit 1
        fi
        echo "Forcing migration to version $2..."
        migrate -path $MIGRATIONS_PATH -database "$DATABASE_URL" force $2
        ;;
    *)
        echo "Usage: $0 {up|down|drop|version|force <version>}"
        exit 1
        ;;
esac

echo "Migration operation completed!"
