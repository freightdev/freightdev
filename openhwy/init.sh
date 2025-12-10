#!/bin/bash

# HWY-TMS Initialization Script
# Fast & Easy Dispatching LLC

set -e

echo "🚀 HWY-TMS Initialization Starting..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker installed${NC}"

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose installed${NC}"

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p storage/surrealdb
mkdir -p storage/garage/app_binaries
mkdir -p certs
mkdir -p services/download_service/binaries
echo -e "${GREEN}✅ Directories created${NC}"

# Create .env files
echo ""
echo "📝 Creating environment files..."

# Auth service
if [ ! -f services/auth_service/.env ]; then
    cp services/auth_service/.env.example services/auth_service/.env
    echo -e "${GREEN}✅ Created services/auth_service/.env${NC}"
else
    echo -e "${YELLOW}⚠️  services/auth_service/.env already exists${NC}"
fi

# Payment service
if [ ! -f services/payment_service/.env ]; then
    cp services/payment_service/.env.example services/payment_service/.env
    echo -e "${YELLOW}⚠️  Created services/payment_service/.env - UPDATE STRIPE KEYS!${NC}"
else
    echo -e "${YELLOW}⚠️  services/payment_service/.env already exists${NC}"
fi

# Nebula CA service
if [ ! -f services/connection_service/.env ]; then
    cp services/connection_service/.env.example services/connection_service/.env
    echo -e "${GREEN}✅ Created services/connection_service/.env${NC}"
else
    echo -e "${YELLOW}⚠️  services/connection_service/.env already exists${NC}"
fi

# Invite service
if [ ! -f services/invite_service/.env ]; then
    cp services/invite_service/.env.example services/invite_service/.env
    echo -e "${GREEN}✅ Created services/invite_service/.env${NC}"
else
    echo -e "${YELLOW}⚠️  services/invite_service/.env already exists${NC}"
fi

# Download service
if [ ! -f services/download_service/.env ]; then
    cp services/download_service/.env.example services/download_service/.env
    echo -e "${GREEN}✅ Created services/download_service/.env${NC}"
else
    echo -e "${YELLOW}⚠️  services/download_service/.env already exists${NC}"
fi

# Start SurrealDB only
echo ""
echo "🗄️  Starting SurrealDB..."
docker-compose up -d surrealdb

echo "⏳ Waiting for SurrealDB to be ready..."
sleep 5

# Check if surreal CLI is available
if command -v surreal &> /dev/null; then
    echo "📥 Importing database schema..."
    surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql || {
        echo -e "${YELLOW}⚠️  Schema import failed. You may need to run it manually.${NC}"
        echo "Run: surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql"
    }
else
    echo -e "${YELLOW}⚠️  SurrealDB CLI not found. Skipping schema import.${NC}"
    echo "Install SurrealDB CLI: curl --proto '=https' --tlsv1.2 -sSf https://install.surrealdb.com | sh"
    echo "Then run: surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql"
fi

echo ""
echo "✨ Initialization complete!"
echo ""
echo "Next steps:"
echo "1. Review and update .env files (especially Stripe keys)"
echo "2. Build and start all services: docker-compose up --build"
echo "3. Test endpoints:"
echo "   - SurrealDB: http://localhost:8000/health"
echo "   - Auth:      http://localhost:8001/health"
echo "   - Payment:   http://localhost:8002/health"
echo "   - Nebula CA: http://localhost:8003/health"
echo "   - Invite:    http://localhost:8004/health"
echo "   - Download:  http://localhost:8005/health"
echo ""
echo "📚 See docs/claude-code/SETUP-GUIDE.md for detailed instructions"
echo ""
