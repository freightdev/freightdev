# Torii Auth Service

Authentication service for HWY-TMS.

## Features

- User signup (dispatcher/driver)
- User login with password hashing (Argon2)
- JWT token generation (7-day expiry)
- Refresh token support (90-day expiry)
- Subscription validation
- Tier-based feature flags

## API Endpoints

### POST /auth/signup
Create a new user account.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!",
  "role": "dispatcher"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "uuid...",
  "user": {
    "id": "users:abc123",
    "email": "dispatcher@example.com",
    "role": "dispatcher",
    "tier": "free"
  }
}
```

### POST /auth/login
Authenticate existing user.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** Same as signup.

### GET /auth/validate
Validate JWT token and check subscription.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
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

### POST /auth/refresh
Refresh access token.

**Request:**
```json
{
  "refresh_token": "uuid..."
}
```

**Response:** Same as login.

## Development

```bash
# Copy environment file
cp .env.example .env

# Run locally
cargo run

# Build release
cargo build --release
```

## Testing

```bash
# Signup
curl -X POST http://localhost:8001/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","role":"dispatcher"}'

# Login
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Validate (replace TOKEN)
curl http://localhost:8001/auth/validate \
  -H "Authorization: Bearer TOKEN"
```

## Environment Variables

- `DATABASE_URL`: SurrealDB connection string (default: 127.0.0.1:8000)
- `JWT_SECRET`: Secret for JWT signing (required in production)
- `PORT`: Server port (default: 8001)
- `RUST_LOG`: Log level

## Security

- Passwords hashed with Argon2
- JWT tokens with 7-day expiry
- Refresh tokens with 90-day expiry
- Tokens stored in database (revocable)
- CORS enabled for all origins (configure for production)

## Production Deployment

```bash
# Build Docker image
docker build -t hwy-tms/auth-service:latest .

# Run container
docker run -p 8001:8001 \
  -e DATABASE_URL=surrealdb:8000 \
  -e JWT_SECRET=your-secret-here \
  hwy-tms/auth-service:latest
```
