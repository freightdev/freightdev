# HWY-TMS

**Highway Transportation Management System**

Enterprise-grade TMS platform built by Fast & Easy Dispatching LLC.

---

## 🎯 Project Overview

HWY-TMS is a modern Transportation Management System featuring:

- **Cross-platform Apps**: Flutter-based dispatcher (desktop/mobile) and driver (mobile) applications
- **Peer-to-Peer VPN**: Nebula mesh network for direct encrypted dispatcher ↔ driver communication
- **AI-Powered Automation**: Client-side WASM agents for document processing
- **Freemium SaaS Model**: Tiered pricing (Free, Pro, Enterprise)
- **Privacy-First**: Client-side data storage, P2P communication

---

## 🏗️ Architecture

### Backend Services (Rust)
- **Auth Service** (Port 8001) - User authentication, JWT tokens
- **Payment Service** (Port 8002) - Stripe webhook integration
- **Nebula CA Service** (Port 8003) - VPN certificate authority
- **Invite Service** (Port 8004) - Driver onboarding with magic links
- **Download Service** (Port 8005) - App binary distribution

### Frontend Applications
- **Marketing Site** (Astro) - Public-facing website
- **Auth Portal** (Astro) - Signup, login, billing dashboard
- **Dispatcher App** (Flutter) - Desktop/mobile TMS interface
- **Driver App** (Flutter) - Mobile app for drivers

### Infrastructure
- **Database**: SurrealDB (embedded + distributed)
- **Storage**: Garage (S3-compatible)
- **VPN**: Nebula mesh network
- **Payments**: Stripe
- **Containerization**: Docker + Docker Compose

---

## 🚀 Quick Start

### Option 1: Automated Setup

```bash
cd ~/openhwy
./init.sh
docker-compose up --build
```

### Option 2: Manual Setup

See [docs/claude-code/SETUP-GUIDE.md](docs/claude-code/SETUP-GUIDE.md) for detailed instructions.

---

## 📊 Project Status

**Build Progress**: 13/14 major tasks complete (93%)

### ✅ Completed
- [x] SurrealDB schema
- [x] Auth service (Torii)
- [x] Payment webhook service
- [x] Nebula CA service
- [x] Invite service
- [x] Download service
- [x] Docker Compose setup
- [x] Dockerfiles for all services
- [x] Comprehensive documentation
- [x] Setup guide and init script
- [x] Complete FED-TMS → HWY-TMS rebranding
- [x] Flutter dispatcher app auth integration
- [x] Astro marketing site updates

### 🏗️ In Progress
- [ ] End-to-end authentication testing
- [ ] Flutter driver app development
- [ ] Nebula VPN client integration

---

## 📚 Documentation

All documentation is in `docs/claude-code/`:

- **[00-INDEX.md](docs/claude-code/00-INDEX.md)** - Documentation index
- **[01-PROJECT-OVERVIEW.md](docs/claude-code/01-PROJECT-OVERVIEW.md)** - System architecture
- **[02-SURREALDB-SCHEMA.md](docs/claude-code/02-SURREALDB-SCHEMA.md)** - Database schema
- **[03-AUTH-SERVICE.md](docs/claude-code/03-AUTH-SERVICE.md)** - Authentication service docs
- **[SETUP-GUIDE.md](docs/claude-code/SETUP-GUIDE.md)** - **START HERE** for local development
- **[PROGRESS.md](docs/claude-code/PROGRESS.md)** - Detailed build progress

---

## 🔧 Technology Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Rust (Tokio, Axum) |
| **Database** | SurrealDB |
| **Frontend** | Astro, Flutter/Dart |
| **VPN** | Nebula |
| **Payments** | Stripe |
| **Storage** | Garage (S3) |
| **Deployment** | Docker, Docker Compose |

---

## 🧪 Testing

```bash
# Test auth flow
curl http://localhost:8001/health
curl -X POST http://localhost:8001/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!","role":"dispatcher"}'

# Test Nebula certificates
curl -X POST http://localhost:8003/cert/issue \
  -H "Content-Type: application/json" \
  -d '{"user_id":"users:test1","role":"dispatcher"}'

# Test invites
curl -X POST http://localhost:8004/invite/create \
  -H "Content-Type: application/json" \
  -d '{"dispatcher_id":"users:test1","driver_name":"John Doe"}'
```

See [SETUP-GUIDE.md](docs/claude-code/SETUP-GUIDE.md) for comprehensive testing instructions.

---

## 📦 Directory Structure

```
openhwy/
├── agents/              # Rust agents (future: compile to WASM)
├── apps/
│   ├── dispatcher/      # Flutter desktop/mobile app
│   ├── driver/          # Flutter mobile app
│   ├── marketing/       # Astro marketing site
│   └── portal/          # Astro auth portal
├── services/
│   ├── auth_service/    # Torii (Rust)
│   ├── payment_service/ # Stripe webhooks (Rust)
│   ├── connection_service/ # Nebula CA (Rust)
│   ├── invite_service/  # Magic links (Rust)
│   └── download_service/ # Binary serving (Rust)
├── storage/
│   ├── surrealdb/       # Database files
│   └── garage/          # S3 storage
├── docs/
│   └── claude-code/     # **Comprehensive documentation**
├── docker-compose.yml   # Container orchestration
├── init.sh              # Initialization script
└── README.md            # This file
```

---

## 🌟 Key Features

### For Dispatchers
- Complete TMS interface (loads, drivers, invoicing)
- Real-time GPS tracking
- Document automation
- Payment tracking
- ELD integration
- Multi-board load search

### For Drivers
- On-the-go load management
- Direct communication with dispatcher
- GPS tracking
- Document uploads
- Load acceptance/rejection

### For Administrators
- User authentication
- Subscription management (Free/Pro/Enterprise)
- Payment processing via Stripe
- VPN certificate management
- Binary distribution

---

## 🔐 Security

- **Authentication**: JWT tokens with Argon2 password hashing
- **VPN**: Nebula mesh with Ed25519 certificates
- **Payments**: Stripe with HMAC webhook verification
- **Data**: Client-side storage in Hive
- **Communication**: Encrypted P2P via Nebula

---

## 🚧 Roadmap

### Phase 1: Foundation (COMPLETE)
- [x] Backend services
- [x] Database schema
- [x] Docker setup

### Phase 2: Frontend Integration (IN PROGRESS)
- [ ] Rebrand FED → HWY-TMS
- [ ] Marketing site updates
- [ ] Flutter app integration
- [ ] Auth flow testing

### Phase 3: Advanced Features (PLANNED)
- [ ] AI agents (WASM compilation)
- [ ] Mobile app launch
- [ ] Enterprise features
- [ ] Analytics dashboard

---

## 📧 Contact

**Company**: Fast & Easy Dispatching LLC
**Domain**: open-hwy.com
**Documentation**: ~/openhwy/docs/claude-code/

---

## 📄 License

Proprietary - Fast & Easy Dispatching LLC

---

**Built with ❤️ using Claude Code**

Last Updated: December 9, 2025
