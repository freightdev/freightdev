# HWY-TMS Project Overview

## Project Identity

**Name**: HWY-TMS (Highway Transportation Management System)
**Company**: Fast & Easy Dispatching LLC
**Domain**: open-hwy.com
**Version**: 1.0.0
**Status**: Active Development

---

## What is HWY-TMS?

HWY-TMS is an **enterprise-grade Transportation Management System (TMS)** designed to modernize truck dispatching with:

- **Dispatcher Desktop/Mobile Apps** (Flutter) - Complete TMS interface
- **Driver Mobile App** (Flutter) - On-the-go load management
- **Peer-to-Peer VPN** (Nebula) - Direct encrypted dispatcher ↔ driver communication
- **AI-Powered Automation** - Client-side WASM agents for document processing
- **Freemium SaaS Model** - Tiered pricing with feature gates

---

## Core Philosophy

**What makes HWY-TMS different:**

1. **Client-Side Data Storage** - Dispatcher data lives in local Hive DB, not our servers
2. **Peer-to-Peer Communication** - Dispatcher ↔ Driver connects via Nebula VPN mesh
3. **Backend is Coordination Only** - We handle auth, payments, VPN certs, downloads
4. **AI Runs Client-Side** - WASM-compiled agents execute locally (zero compute costs)
5. **Privacy-First** - We never see your load data or communications

---

## Architecture Principles

### Three-Tier Pricing Model

```
FREE TIER
├── 3 drivers max
├── 10 loads max
├── Basic features
└── Email support

PRO TIER ($189/mo)
├── 20 drivers
├── Unlimited loads
├── AI agents enabled
├── All load boards
└── Priority support

ENTERPRISE TIER ($449/mo)
├── Unlimited drivers
├── White-label branding
├── Custom integrations
├── Dedicated support
└── Multi-location
```

### Data Flow

```
User Signs Up (Astro Portal)
  ↓
Torii Auth Service (Creates account in SurrealDB)
  ↓
User Chooses Plan (Stripe Payment)
  ↓
Payment Webhook Updates Subscription
  ↓
User Downloads App (From Garage S3)
  ↓
App Logs In (Gets JWT + Nebula cert)
  ↓
App Connects to Nebula Mesh
  ↓
Dispatcher Invites Driver (Magic link)
  ↓
Driver Accepts Invite (Gets Nebula cert)
  ↓
Direct P2P Tunnel Established
  ↓
ALL COMMUNICATION IS PEER-TO-PEER (We don't see it)
```

---

## Service Breakdown

### Backend Services (Rust)

1. **Torii (auth_service)**
   - User signup/login
   - JWT token generation
   - Subscription validation
   - Feature flag checking

2. **Payment Service (payment_service)**
   - Stripe webhook handler
   - Subscription lifecycle management
   - Payment tracking

3. **Nebula CA (connection_service)**
   - Certificate authority
   - IP allocation (10.42.x.x)
   - Lighthouse coordination server
   - Certificate revocation

4. **Invite Service (invite_service)**
   - Magic link generation
   - Driver onboarding
   - Pre-generated cert bundles

5. **Download Service (download_service)**
   - Serves app binaries from Garage
   - Version management
   - Platform detection

6. **Pingora (edge_service)**
   - Edge routing
   - Load balancing
   - Rate limiting
   - SSL termination

### Frontend Applications

1. **Marketing Site (Astro)**
   - Landing page
   - Pricing
   - Features
   - About/Contact

2. **Auth Portal (Astro)**
   - Signup/login
   - Stripe checkout
   - Dashboard
   - Billing management

3. **Dispatcher App (Flutter)**
   - Cross-platform (Windows, macOS, Linux, iOS, Android, Web)
   - Local Hive database
   - Nebula VPN client
   - Load management
   - Driver coordination

4. **Driver App (Flutter)**
   - Mobile only (iOS, Android)
   - Local Hive database
   - Nebula VPN client
   - Load acceptance
   - GPS tracking

### Storage Layer

1. **SurrealDB**
   - Users
   - Subscriptions
   - Invites
   - Nebula certificates
   - Connections

2. **Garage (S3)**
   - App binaries (.exe, .dmg, .apk, .ipa)
   - AI model files (WASM)
   - Backups

---

## User Journeys

### Dispatcher Journey

```
1. Visit open-hwy.com
2. Sign up (email + password)
3. Choose plan (Free/Pro/Enterprise)
4. Pay with Stripe (if Pro/Enterprise)
5. Download dispatcher app
6. Login to app
7. App receives Nebula certificate
8. Create loads in local Hive DB
9. Invite drivers (magic links)
10. Drivers accept → P2P connection established
11. Manage loads, communicate directly with drivers
```

### Driver Journey

```
1. Receive magic link from dispatcher
2. Click link → lands on open-hwy.com/driver/join
3. Download driver app
4. App auto-connects using invite token
5. Receives Nebula certificate
6. P2P tunnel to dispatcher established
7. See available loads
8. Accept loads
9. Update status in real-time
10. Communicate directly with dispatcher
```

---

## Technical Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Edge** | Pingora (Rust) | Load balancing, routing, SSL |
| **Services** | Rust (Tokio/Axum) | High-performance async services |
| **Database** | SurrealDB | Multi-model embedded+distributed DB |
| **Storage** | Garage | Self-hosted S3-compatible storage |
| **VPN** | Nebula | Mesh network for P2P connections |
| **Payments** | Stripe | Subscription management |
| **Frontend** | Astro | Marketing site, auth portal |
| **Apps** | Flutter/Dart | Cross-platform mobile/desktop |
| **Auth** | JWT | Token-based authentication |
| **AI** | Rig + WASM | Client-side agent execution |

---

## Security Model

### Authentication Flow
```
1. User logs in with email/password
2. Torii verifies credentials (bcrypt hash)
3. Torii generates JWT token (7-day expiry)
4. Token includes: user_id, email, role, tier
5. App stores token in secure storage
6. Every API call includes Authorization: Bearer <token>
7. Services validate JWT signature
8. Services check subscription status in SurrealDB
```

### Nebula VPN Security
```
- Each dispatcher gets a /24 subnet (10.42.X.0/24)
- Dispatcher = 10.42.X.1
- Drivers = 10.42.X.2-254
- Certificates signed by our CA
- Lighthouse facilitates NAT traversal
- All traffic encrypted (Curve25519)
- Firewall rules prevent cross-dispatcher access
```

### Payment Security
```
- Never store credit card data
- Stripe Payment Element (PCI compliant)
- Webhook signature verification
- HTTPS everywhere
- Idempotency keys for webhooks
```

---

## Subscription Enforcement

### Free Tier Limits
- Max 3 drivers → Enforced in app (invite button disabled)
- Max 10 loads → Enforced in app (create load button disabled)
- No AI agents → Features hidden in UI
- Check on every app launch via `/auth/validate` endpoint

### Payment Failure Handling
```
Day 0: Payment fails
  ↓
Update status to 'past_due' in SurrealDB
  ↓
Set grace_period_ends = NOW() + 7 days
  ↓
App shows warning banner
  ↓
Limited functionality (view only, can't create new)
  ↓
Day 7: If still unpaid
  ↓
Stripe cancels subscription
  ↓
Update tier to 'free' in SurrealDB
  ↓
App enforces free tier limits
```

---

## Development Workflow

### Local Development
```bash
# Start SurrealDB
surreal start --log debug --bind 0.0.0.0:8000 file://storage/surrealdb

# Start Garage
garage server

# Start auth service
cd services/auth_service
cargo run

# Start marketing site
cd apps/marketing
npm run dev

# Start dispatcher app
cd apps/dispatcher
flutter run -d chrome
```

### Production Deployment
```
All services containerized (Docker)
Orchestrated with docker-compose
Reverse proxy: Pingora
SSL: Let's Encrypt
Monitoring: TBD (Prometheus + Grafana)
```

---

## File Structure

```
openhwy/
├── agents/              # Rust agents (compile to WASM)
│   ├── big_bear/
│   ├── cargo_connect/
│   ├── packet_pilot/
│   └── ...
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
│   ├── download_service/ # Binary serving (Rust)
│   └── edge_service/    # Pingora router (Rust)
├── storage/
│   ├── surrealdb/       # Database files
│   └── garage/          # S3 storage
└── docs/
    └── claude-code/     # This documentation
```

---

## Success Metrics

### Business Metrics
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Churn rate
- Conversion rate (Free → Pro)
- Average revenue per user (ARPU)

### Technical Metrics
- API response time (p95 < 200ms)
- Uptime (99.9% target)
- Nebula tunnel success rate
- App crash rate
- Database query performance

### User Metrics
- Daily active users (DAU)
- Feature adoption rate
- Support ticket volume
- Net Promoter Score (NPS)

---

## Roadmap

### Q1 2026 (Jan-Mar)
- ✅ Complete Phase 1: Foundation
- ✅ Complete Phase 2: Core Services
- ✅ Complete Phase 3: Networking
- 🏗️ MVP launch (beta)

### Q2 2026 (Apr-Jun)
- AI agents (WASM)
- Mobile app launch
- Enterprise tier launch
- API for third-party integrations

### Q3 2026 (Jul-Sep)
- Multi-language support
- Advanced analytics
- Accounting integrations (QuickBooks)
- Load board marketplace

### Q4 2026 (Oct-Dec)
- White-label options
- Advanced compliance tools
- Fleet management features
- International expansion

---

## Contact & Support

**Company**: Fast & Easy Dispatching LLC
**Website**: https://open-hwy.com
**Email**: support@open-hwy.com
**Documentation**: ~/openhwy/docs/claude-code/

---

Last Updated: December 9, 2025
