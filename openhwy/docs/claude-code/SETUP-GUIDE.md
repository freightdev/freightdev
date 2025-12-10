# HWY-TMS Local Development Setup Guide

**Complete guide to running HWY-TMS locally**

---

## Prerequisites

Install these tools before starting:

```bash
# 1. Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Rust (for local development without Docker)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 3. Node.js & npm (for Astro frontend)
# Visit nodejs.org or use nvm

# 4. Flutter (for mobile/desktop apps)
# Visit flutter.dev

# 5. SurrealDB CLI (optional)
curl --proto '=https' --tlsv1.2 -sSf https://install.surrealdb.com | sh
```

---

## Quick Start (Docker)

### 1. Initialize Database Schema

```bash
cd ~/openhwy

# Start only SurrealDB first
docker-compose up -d surrealdb

# Wait for it to be healthy
docker-compose ps

# Import schema
surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql
```

### 2. Create Environment Files

```bash
# Copy all .env.example files
cp services/auth_service/.env.example services/auth_service/.env
cp services/payment_service/.env.example services/payment_service/.env
cp services/connection_service/.env.example services/connection_service/.env
cp services/invite_service/.env.example services/invite_service/.env
cp services/download_service/.env.example services/download_service/.env

# Edit services/payment_service/.env with your Stripe keys (optional for auth testing)
```

### 3. Start All Services

```bash
# Build and start all containers
docker-compose up --build

# Or run in background
docker-compose up --build -d

# View logs
docker-compose logs -f
```

### 4. Verify Services

```bash
# Check all services are healthy
curl http://localhost:8000/health  # SurrealDB
curl http://localhost:8001/health  # Auth Service
curl http://localhost:8002/health  # Payment Service
curl http://localhost:8003/health  # Nebula CA Service
curl http://localhost:8004/health  # Invite Service
curl http://localhost:8005/health  # Download Service
```

---

## Local Development (Without Docker)

### 1. Start SurrealDB

```bash
# Terminal 1: Run SurrealDB
surreal start --log debug --user root --pass root file://storage/surrealdb

# Terminal 2: Import schema
surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql
```

### 2. Run Services Individually

```bash
# Terminal 3: Auth Service
cd services/auth_service
cp .env.example .env
cargo run

# Terminal 4: Payment Service
cd services/payment_service
cp .env.example .env
cargo run

# Terminal 5: Nebula CA Service
cd services/connection_service
cp .env.example .env
cargo run

# Terminal 6: Invite Service
cd services/invite_service
cp .env.example .env
cargo run

# Terminal 7: Download Service
cd services/download_service
cp .env.example .env
cargo run
```

---

## Testing the System

### 1. Test Auth Flow

```bash
# Signup
curl -X POST http://localhost:8001/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "dispatcher@test.com",
    "password": "SecurePass123!",
    "role": "dispatcher"
  }'

# Save the access_token from response

# Login
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "dispatcher@test.com",
    "password": "SecurePass123!"
  }'

# Validate (replace TOKEN)
curl http://localhost:8001/auth/validate \
  -H "Authorization: Bearer TOKEN"
```

### 2. Test Nebula Certificate Generation

```bash
# Issue dispatcher certificate
curl -X POST http://localhost:8003/cert/issue \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "users:dispatcher1",
    "role": "dispatcher"
  }'

# Save the dispatcher cert response

# Issue driver certificate
curl -X POST http://localhost:8003/cert/issue \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "users:driver1",
    "role": "driver",
    "dispatcher_id": "users:dispatcher1"
  }'
```

### 3. Test Invite Flow

```bash
# Create invite
curl -X POST http://localhost:8004/invite/create \
  -H "Content-Type: application/json" \
  -d '{
    "dispatcher_id": "users:dispatcher1",
    "driver_name": "John Doe",
    "contact": "john@test.com"
  }'

# Save the invite_token from response

# Verify invite
curl http://localhost:8004/invite/verify/INVITE_TOKEN_HERE

# Accept invite
curl -X POST http://localhost:8004/invite/accept \
  -H "Content-Type: application/json" \
  -d '{
    "invite_token": "INVITE_TOKEN_HERE",
    "device_id": "test-device-123"
  }'
```

### 4. Test Stripe Webhooks (Optional)

```bash
# Install Stripe CLI
# https://stripe.com/docs/stripe-cli

# Forward webhooks to local
stripe listen --forward-to localhost:8002/webhook/stripe

# Trigger test event
stripe trigger customer.subscription.created
```

---

## Troubleshooting

### SurrealDB Connection Issues

```bash
# Check if SurrealDB is running
docker ps | grep surrealdb
# or
ps aux | grep surreal

# Test connection
surreal sql --conn http://localhost:8000 --user root --pass root --ns hwytms --db production

# Run a test query
USE NS hwytms DB production;
SELECT * FROM tier_features;
```

### Service Won't Start

```bash
# Check if port is already in use
lsof -i :8001  # Auth service
lsof -i :8002  # Payment service
lsof -i :8003  # Nebula CA
lsof -i :8004  # Invite service
lsof -i :8005  # Download service

# Kill process using port
kill -9 PID
```

### Docker Build Fails

```bash
# Clean rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### Database Schema Not Loaded

```bash
# Re-import schema
surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production storage/surrealdb/schema.surql

# Verify tier features exist
surreal sql --conn http://localhost:8000 --user root --pass root --ns hwytms --db production
USE NS hwytms DB production;
SELECT * FROM tier_features;
```

---

## Service Architecture

```
┌─────────────────────────────────────────┐
│          Your Machine                   │
│                                         │
│  SurrealDB    :8000  ✅                │
│  Auth         :8001  ✅                │
│  Payment      :8002  ✅                │
│  Nebula CA    :8003  ✅                │
│  Invite       :8004  ✅                │
│  Download     :8005  ✅                │
│  Marketing    :3000  (optional)        │
│                                         │
└─────────────────────────────────────────┘
```

---

## Next Steps

### 1. Frontend Development

```bash
# Marketing site
cd apps/marketing
npm install
npm run dev
# Visit http://localhost:3000

# Flutter dispatcher app
cd apps/dispatcher
flutter pub get
flutter run -d chrome
```

### 2. Integration Testing

- Test full signup → login → certificate flow
- Test invite creation → acceptance
- Test payment webhooks with Stripe CLI
- Test frontend connecting to backend services

### 3. Production Preparation

- [ ] Change JWT_SECRET to secure random value
- [ ] Set up real Stripe account
- [ ] Configure proper CORS origins
- [ ] Set up SSL certificates
- [ ] Configure firewall rules
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Back up CA certificates securely

---

## Environment Variables Reference

### Auth Service
```
DATABASE_URL=127.0.0.1:8000
JWT_SECRET=your-super-secret-key
PORT=8001
```

### Payment Service
```
DATABASE_URL=127.0.0.1:8000
STRIPE_SECRET_KEY=sk_test_xxx or sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
PORT=8002
```

### Nebula CA Service
```
DATABASE_URL=127.0.0.1:8000
CA_CERT_PATH=./ca.crt
CA_KEY_PATH=./ca.key
LIGHTHOUSE_HOST=lighthouse.open-hwy.com:4242
PORT=8003
```

### Invite Service
```
DATABASE_URL=127.0.0.1:8000
NEBULA_CA_URL=http://localhost:8003
AUTH_URL=http://localhost:8001
BASE_URL=https://open-hwy.com
PORT=8004
```

### Download Service
```
BINARIES_PATH=./binaries
PORT=8005
```

---

## Useful Commands

```bash
# View all running containers
docker-compose ps

# View logs for specific service
docker-compose logs -f auth-service

# Restart a service
docker-compose restart auth-service

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild specific service
docker-compose build auth-service
docker-compose up -d auth-service

# Run SurrealDB query
surreal sql --conn http://localhost:8000 --user root --pass root --ns hwytms --db production

# Export database backup
surreal export --conn http://localhost:8000 --user root --pass root --ns hwytms --db production backup.surql

# Import database backup
surreal import --conn http://localhost:8000 --user root --pass root --ns hwytms --db production backup.surql
```

---

## Support & Documentation

- **Documentation**: `~/openhwy/docs/claude-code/`
- **Service READMEs**: `~/openhwy/services/*/README.md`
- **API Endpoints**: See `docs/claude-code/05-API-ENDPOINTS.md`
- **Troubleshooting**: See `docs/claude-code/08-TROUBLESHOOTING.md`

---

Last Updated: December 9, 2025
