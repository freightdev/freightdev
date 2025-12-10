# HWY-TMS Implementation Documentation

**Project**: HWY-TMS (Highway Transportation Management System)
**Company**: Fast & Easy Dispatching LLC
**Domain**: open-hwy.com
**Database**: SurrealDB
**Started**: December 9, 2025

---

## Documentation Index

### 01. Project Overview
- [01-PROJECT-OVERVIEW.md](01-PROJECT-OVERVIEW.md) - System architecture and vision

### 02. Database
- [02-SURREALDB-SCHEMA.md](02-SURREALDB-SCHEMA.md) - Complete database schema
- [02-SURREALDB-QUERIES.md](02-SURREALDB-QUERIES.md) - Common queries and operations

### 03. Services (Rust Backend)
- [03-AUTH-SERVICE.md](03-AUTH-SERVICE.md) - Torii authentication service
- [03-PAYMENT-SERVICE.md](03-PAYMENT-SERVICE.md) - Stripe webhook handler
- [03-NEBULA-CA-SERVICE.md](03-NEBULA-CA-SERVICE.md) - Certificate authority
- [03-DOWNLOAD-SERVICE.md](03-DOWNLOAD-SERVICE.md) - App binary downloads
- [03-INVITE-SERVICE.md](03-INVITE-SERVICE.md) - Driver invitations
- [03-EDGE-SERVICE.md](03-EDGE-SERVICE.md) - Pingora edge router

### 04. Frontend Applications
- [04-FLUTTER-DISPATCHER.md](04-FLUTTER-DISPATCHER.md) - Dispatcher desktop/mobile app
- [04-FLUTTER-DRIVER.md](04-FLUTTER-DRIVER.md) - Driver mobile app
- [04-ASTRO-MARKETING.md](04-ASTRO-MARKETING.md) - Marketing website
- [04-ASTRO-PORTAL.md](04-ASTRO-PORTAL.md) - Auth/billing portal

### 05. Integration & APIs
- [05-API-ENDPOINTS.md](05-API-ENDPOINTS.md) - Complete API reference
- [06-FRONTEND-INTEGRATION.md](06-FRONTEND-INTEGRATION.md) - **✅ Flutter/Astro integration & rebranding**
- [05-NEBULA-VPN.md](05-NEBULA-VPN.md) - Mesh VPN configuration

### 06. Deployment
- [06-LOCAL-DEVELOPMENT.md](06-LOCAL-DEVELOPMENT.md) - Local setup guide
- [06-PRODUCTION-DEPLOYMENT.md](06-PRODUCTION-DEPLOYMENT.md) - Production deployment
- [06-DOCKER-COMPOSE.md](06-DOCKER-COMPOSE.md) - Docker configuration

### 07. Testing
- [07-TESTING-GUIDE.md](07-TESTING-GUIDE.md) - Testing strategies
- [07-E2E-TESTS.md](07-E2E-TESTS.md) - End-to-end test suite

### 08. Operations
- [08-MONITORING.md](08-MONITORING.md) - Monitoring and observability
- [08-TROUBLESHOOTING.md](08-TROUBLESHOOTING.md) - Common issues and solutions

---

## Implementation Status

✅ = Complete
🏗️ = In Progress
⏳ = Pending

### Phase 1: Foundation ✅
- ✅ Rebrand FED → HWY-TMS
- ✅ SurrealDB schema
- ✅ Local development setup
- ✅ Documentation structure

### Phase 2: Core Services ✅
- ✅ Torii auth service
- ✅ Payment webhook service
- ✅ Docker Compose setup

### Phase 3: Networking ✅
- ✅ Nebula CA service
- ✅ Invite service
- ✅ Download service
- ⏳ Pingora edge router (optional)

### Phase 4: Frontend ✅
- ✅ Marketing site rebranding
- ✅ Flutter apps update
- ✅ Auth flow integration

### Phase 5: VPN Integration (Week 9-10)
- ⏳ Nebula VPN in Flutter
- ⏳ P2P messaging
- ⏳ Connection management

### Phase 6: Testing & Polish (Week 11-12)
- ⏳ End-to-end tests
- ⏳ Performance optimization
- ⏳ Security audit

---

## Quick Start Commands

```bash
# Start all services locally
cd ~/openhwy
docker-compose up -d

# Run auth service
cd services/auth_service
cargo run

# Run marketing site
cd apps/marketing
npm run dev

# Run dispatcher app
cd apps/dispatcher
flutter run -d chrome
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│        open-hwy.com (Frontend)          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │   Marketing  │  │  Portal (Auth)  │ │
│  │    (Astro)   │  │     (Astro)     │ │
│  └──────────────┘  └─────────────────┘ │
└─────────────────┬───────────────────────┘
                  │
         ┌────────▼─────────┐
         │   Pingora Edge   │
         │   Load Balancer  │
         └────────┬─────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼────┐  ┌─────▼──────┐  ┌──▼─────┐
│ Torii  │  │ Nebula CA  │  │ Garage │
│ (Auth) │  │ +Lighthouse│  │  (S3)  │
└───┬────┘  └─────┬──────┘  └────────┘
    │             │
    └──────┬──────┘
           │
    ┌──────▼───────┐
    │  SurrealDB   │
    │  - Users     │
    │  - Subs      │
    │  - Certs     │
    └──────────────┘

         Nebula Mesh VPN
              │
      ┌───────┼────────┐
      │                │
┌─────▼──────┐   ┌─────▼──────┐
│ Dispatcher │◄──►│   Driver   │
│    App     │P2P │    App     │
│  (Flutter) │   │  (Flutter) │
└────────────┘   └────────────┘
```

---

## Technology Stack

**Backend Services**: Rust (Tokio, Axum)
**Database**: SurrealDB
**Storage**: Garage (S3-compatible)
**Frontend**: Flutter (Dart), Astro (JS/TS)
**VPN**: Nebula mesh network
**Payments**: Stripe
**Auth**: JWT tokens
**Edge**: Pingora (Rust)

---

## Contact

**Organization**: Fast & Easy Dispatching LLC
**Website**: https://open-hwy.com
**Documentation**: ~/openhwy/docs/claude-code/

---

Last Updated: December 9, 2025
