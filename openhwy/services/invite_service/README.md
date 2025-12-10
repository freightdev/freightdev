# Invite Service

Driver onboarding service with magic link invitations for HWY-TMS.

## Features

- Create invites for drivers
- Pre-generate Nebula certificates
- Magic link generation (7-day expiry)
- Driver account auto-creation
- Invite verification

## API Endpoints

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

**Response:**
```json
{
  "invite_token": "uuid-here",
  "magic_link": "https://open-hwy.com/driver/join?token=uuid-here",
  "expires_at": "2025-12-16T00:00:00Z"
}
```

### POST /invite/accept
Accept an invite (called by driver app).

**Request:**
```json
{
  "invite_token": "uuid-here",
  "device_id": "driver-device-fingerprint"
}
```

**Response:**
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

### GET /invite/verify/:token
Verify invite validity without accepting.

**Response:**
```json
{
  "valid": true,
  "dispatcher_name": "ABC Logistics",
  "expires_at": "2025-12-16T00:00:00Z"
}
```

## Development

```bash
cp .env.example .env
cargo run
```

## Flow

1. Dispatcher creates invite via /invite/create
2. Service calls Nebula CA to pre-generate driver certificate
3. Invite stored in database with cert
4. Magic link sent to driver
5. Driver clicks link, downloads app
6. App calls /invite/accept with token
7. Service creates driver account
8. Returns auth tokens + Nebula config
9. Driver connects to Nebula mesh

## Environment Variables

- `DATABASE_URL`: SurrealDB connection
- `NEBULA_CA_URL`: Nebula CA service URL
- `AUTH_URL`: Auth service URL
- `BASE_URL`: Frontend base URL for magic links
- `PORT`: Server port (default: 8004)
