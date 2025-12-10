# HWY-TMS API Endpoints Reference

Complete reference for all backend service endpoints.

---

## Base URLs

**Local Development:**
- Auth Service: `http://localhost:8001`
- Payment Service: `http://localhost:8002`
- Nebula CA Service: `http://localhost:8003`
- Invite Service: `http://localhost:8004`
- Download Service: `http://localhost:8005`

**Production:**
- All services: `https://api.open-hwy.com` (routed by Pingora)

---

## Auth Service (Port 8001)

### POST /auth/signup
Create a new user account.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!",
  "role": "dispatcher"  // "dispatcher" or "driver"
}
```

**Response (201):**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": "users:abc123",
    "email": "dispatcher@example.com",
    "role": "dispatcher",
    "tier": "free"
  }
}
```

---

### POST /auth/login
Authenticate existing user.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200):** Same as signup

---

### GET /auth/validate
Validate JWT token and check subscription.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "valid": true,
  "user_id": "users:abc123",
  "tier": "pro",
  "status": "active",
  "expires_at": "2026-01-09T00:00:00Z",
  "features": {
    "tier": "pro",
    "max_drivers": 20,
    "max_loads": -1,
    "ai_agents_enabled": true,
    "custom_branding": false,
    "priority_support": true,
    "dedicated_support": false
  }
}
```

---

### POST /auth/refresh
Refresh access token.

**Request:**
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "new-uuid-here",
  "user": {
    "id": "users:abc123",
    "email": "dispatcher@example.com",
    "role": "dispatcher",
    "tier": "pro"
  }
}
```

---

### GET /health
Health check.

**Response:** `"Torii Auth Service - Healthy ✅"`

---

## Payment Service (Port 8002)

### POST /webhook/stripe
Handle Stripe webhook events.

**Headers:**
```
stripe-signature: t=timestamp,v1=signature
Content-Type: application/json
```

**Request:** Stripe event object

**Response (200):**
```json
{
  "received": true
}
```

**Handled Events:**
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`

---

### GET /health
Health check.

**Response:** `"Payment Webhook Service - Healthy ✅"`

---

## Nebula CA Service (Port 8003)

### POST /cert/issue
Issue a new Nebula certificate.

**Request:**
```json
{
  "user_id": "users:abc123",
  "role": "dispatcher",  // or "driver"
  "dispatcher_id": "users:def456"  // required if role=driver
}
```

**Response (200):**
```json
{
  "cert_pem": "-----BEGIN NEBULA CERTIFICATE-----...",
  "key_pem": "-----BEGIN NEBULA PRIVATE KEY-----...",
  "nebula_ip": "10.42.1.1",
  "ca_cert": "-----BEGIN NEBULA CERTIFICATE-----...",
  "lighthouse_host": "lighthouse.open-hwy.com:4242",
  "expires_at": "2026-12-09T00:00:00Z"
}
```

---

### POST /cert/revoke
Revoke a certificate.

**Request:**
```json
{
  "user_id": "users:abc123"
}
```

**Response (200):**
```json
{
  "revoked": true,
  "revoked_at": "2025-12-09T12:00:00Z"
}
```

---

### POST /cert/verify
Verify a certificate.

**Request:**
```json
{
  "cert_pem": "-----BEGIN NEBULA CERTIFICATE-----..."
}
```

**Response (200):**
```json
{
  "valid": true,
  "nebula_ip": "10.42.1.1",
  "issued_at": "2025-12-09T00:00:00Z",
  "expires_at": "2026-12-09T00:00:00Z",
  "revoked": false
}
```

---

### GET /health
Health check.

**Response:** `"Nebula CA Service - Healthy ✅"`

---

## Invite Service (Port 8004)

### POST /invite/create
Create a driver invite.

**Request:**
```json
{
  "dispatcher_id": "users:abc123",
  "driver_name": "John Doe",
  "contact": "john@example.com"
}
```

**Response (200):**
```json
{
  "invite_token": "uuid-here",
  "magic_link": "https://open-hwy.com/driver/join?token=uuid-here",
  "expires_at": "2025-12-16T00:00:00Z"
}
```

---

### POST /invite/accept
Accept an invite (called by driver app).

**Request:**
```json
{
  "invite_token": "uuid-here",
  "device_id": "driver-device-fingerprint"
}
```

**Response (200):**
```json
{
  "access_token": "jwt-token",
  "refresh_token": "uuid",
  "driver_id": "users:driver123",
  "dispatcher": {
    "id": "users:abc123",
    "nebula_ip": "10.42.1.1"
  },
  "nebula_config": {
    "ca_cert": "...",
    "cert": "...",
    "key": "...",
    "nebula_ip": "10.42.1.2",
    "lighthouse": "lighthouse.open-hwy.com:4242"
  }
}
```

---

### GET /invite/verify/:token
Verify invite validity without accepting.

**Response (200):**
```json
{
  "valid": true,
  "dispatcher_name": "ABC Logistics",
  "expires_at": "2025-12-16T00:00:00Z"
}
```

---

### GET /health
Health check.

**Response:** `"Invite Service - Healthy ✅"`

---

## Download Service (Port 8005)

### GET /download/:app
Download app binary.

**Parameters:**
- `app`: "dispatcher" or "driver"
- `platform` (query param, optional): "windows", "macos", "linux", "android", "ios"

**Example:**
```bash
# Auto-detect platform from User-Agent
curl http://localhost:8005/download/dispatcher -o dispatcher.exe

# Specify platform
curl "http://localhost:8005/download/driver?platform=android" -o driver.apk
```

**Response:** Binary file with appropriate Content-Type

**Supported Files:**
- Dispatcher: `.exe` (Windows), `.dmg` (macOS), `.AppImage` (Linux)
- Driver: `.apk` (Android), `.ipa` (iOS)

---

### GET /health
Health check.

**Response:** `"Download Service - Healthy ✅"`

---

## Error Responses

All services use consistent error format:

**4xx/5xx Response:**
```json
{
  "error": "Error message here"
}
```

**Common Status Codes:**
- `200` OK - Request successful
- `201` Created - Resource created
- `400` Bad Request - Invalid input
- `401` Unauthorized - Authentication failed
- `403` Forbidden - Insufficient permissions
- `404` Not Found - Resource not found
- `409` Conflict - Resource already exists
- `500` Internal Server Error - Server error

---

## Authentication Flow

```
1. User signs up
   POST /auth/signup
   ← {access_token, refresh_token}

2. Store tokens securely
   - Mobile: Flutter secure_storage
   - Web: localStorage (with httpOnly cookies in production)

3. Make authenticated requests
   Authorization: Bearer <access_token>

4. Token expires (7 days)
   POST /auth/refresh {refresh_token}
   ← {new access_token, new refresh_token}

5. Validate on app launch
   GET /auth/validate
   Authorization: Bearer <access_token>
   ← {subscription status, features}
```

---

## Driver Onboarding Flow

```
1. Dispatcher creates invite
   POST /invite/create {dispatcher_id, driver_name}
   ← {magic_link}

2. Driver clicks magic link
   Browser: https://open-hwy.com/driver/join?token=xxx

3. Driver downloads app
   GET /download/driver?platform=android
   ← driver.apk

4. App accepts invite
   POST /invite/accept {invite_token, device_id}
   ← {access_token, nebula_config}

5. App connects to Nebula VPN
   Using nebula_config from step 4

6. Direct P2P connection established
   Dispatcher ↔ Driver encrypted tunnel
```

---

## Subscription Management Flow

```
1. User upgrades via Stripe Checkout
   (Handled on frontend with Stripe.js)

2. Stripe sends webhook
   POST /webhook/stripe
   Event: customer.subscription.created

3. Payment service updates database
   UPDATE subscriptions SET tier='pro', status='active'

4. User's app checks subscription
   GET /auth/validate
   ← {tier: 'pro', features: {...}}

5. App enables pro features
   Based on features object
```

---

## IP Allocation Logic

**Dispatcher IPs:**
- Format: `10.42.X.1`
- X = dispatcher count + 1
- Each dispatcher gets own /24 subnet

**Driver IPs:**
- Format: `10.42.X.Y`
- X = dispatcher's subnet
- Y = driver count + 2 (starts at .2)
- Max 253 drivers per dispatcher

**Example:**
```
Dispatcher 1: 10.42.1.1
  Driver 1:   10.42.1.2
  Driver 2:   10.42.1.3
  Driver 3:   10.42.1.4

Dispatcher 2: 10.42.2.1
  Driver 1:   10.42.2.2
  Driver 2:   10.42.2.3
```

---

## Rate Limiting (Future)

Planned rate limits:

| Endpoint | Limit |
|----------|-------|
| `/auth/signup` | 10/hour per IP |
| `/auth/login` | 20/hour per IP |
| `/auth/validate` | 100/minute per user |
| `/cert/issue` | 10/hour per user |
| `/invite/create` | 20/hour per user |

---

Last Updated: December 9, 2025
