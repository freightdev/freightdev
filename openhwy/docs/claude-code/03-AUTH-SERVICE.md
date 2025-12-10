# Auth Service (Torii) Documentation

## Overview

**Service Name**: Torii (auth_service)
**Port**: 8001
**Language**: Rust
**Framework**: Axum
**Database**: SurrealDB

The authentication service handles user signup, login, JWT token generation, and subscription validation for HWY-TMS.

---

## Architecture

```
Client App
    ↓
POST /auth/signup or /auth/login
    ↓
Torii Service (Port 8001)
    ↓
SurrealDB
    ↓
Return JWT + Refresh Token
```

---

## Features

1. **User Signup**
   - Email/password registration
   - Role assignment (dispatcher/driver)
   - Automatic free tier subscription
   - Password hashing with Argon2

2. **User Login**
   - Email/password authentication
   - JWT token generation (7 days)
   - Refresh token generation (90 days)

3. **Token Validation**
   - JWT signature verification
   - Subscription status check
   - Feature flag retrieval

4. **Token Refresh**
   - Refresh token validation
   - Old token revocation
   - New token pair generation

---

## API Endpoints

### 1. POST /auth/signup

Create a new user account with default free subscription.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!",
  "role": "dispatcher"  // or "driver"
}
```

**Success Response (201):**
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

**Error Responses:**
- 409 Conflict: User already exists
- 400 Bad Request: Invalid input

---

### 2. POST /auth/login

Authenticate existing user.

**Request:**
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePassword123!"
}
```

**Success Response (200):**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": "users:abc123",
    "email": "dispatcher@example.com",
    "role": "dispatcher",
    "tier": "pro"
  }
}
```

**Error Responses:**
- 401 Unauthorized: Invalid credentials

---

### 3. GET /auth/validate

Validate JWT token and return subscription status.

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Success Response (200):**
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

**Error Responses:**
- 401 Unauthorized: Missing or invalid token

---

### 4. POST /auth/refresh

Refresh access token using refresh token.

**Request:**
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Success Response (200):**
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

**Error Responses:**
- 401 Unauthorized: Invalid or revoked refresh token

---

## Security

### Password Hashing

Using **Argon2** (winner of Password Hashing Competition 2015):
- Salt generated per password
- Stored as PHC string format
- Resistant to GPU/ASIC attacks

```rust
let salt = SaltString::generate(&mut OsRng);
let argon2 = Argon2::default();
let password_hash = argon2
    .hash_password(password.as_bytes(), &salt)?
    .to_string();
```

### JWT Tokens

**Access Token:**
- Algorithm: HS256 (HMAC with SHA-256)
- Expiry: 7 days
- Claims: user_id, email, role, tier

**Structure:**
```json
{
  "sub": "users:abc123",
  "email": "dispatcher@example.com",
  "role": "dispatcher",
  "tier": "pro",
  "iat": 1733788800,
  "exp": 1734393600
}
```

**Refresh Token:**
- Format: UUID v4
- Expiry: 90 days
- Stored in database (can be revoked)

### Token Validation Flow

```
1. Client sends request with Authorization: Bearer <token>
2. Extract token from header
3. Verify JWT signature with secret key
4. Check expiration (exp claim)
5. Query SurrealDB for user and subscription
6. Check subscription status (active/past_due/cancelled)
7. Return validation result with features
```

---

## Database Operations

### Create User
```surql
CREATE users CONTENT {
    email: "user@example.com",
    password_hash: "$argon2id$v=19$m=...",
    role: "dispatcher",
    created_at: time::now(),
    updated_at: time::now()
};
```

### Create Subscription
```surql
CREATE subscriptions CONTENT {
    user_id: users:abc123,
    tier: "free",
    status: "active",
    cancel_at_period_end: false,
    created_at: time::now(),
    updated_at: time::now()
};
```

### Find User by Email
```surql
SELECT * FROM users WHERE email = $email LIMIT 1;
```

### Get User with Subscription
```surql
SELECT * FROM users WHERE id = $user_id LIMIT 1;
SELECT * FROM subscriptions WHERE user_id = $user_id LIMIT 1;
```

---

## Error Handling

Custom error types with proper HTTP status codes:

```rust
pub enum AuthError {
    InvalidCredentials,      // 401
    UserAlreadyExists,       // 409
    InvalidToken,            // 401
    TokenExpired,            // 401
    Unauthorized,            // 401
    DatabaseError(String),   // 500
    InternalServerError,     // 500
}
```

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | SurrealDB connection | `127.0.0.1:8000` |
| `JWT_SECRET` | JWT signing secret | `dev-secret` (change!) |
| `PORT` | Server port | `8001` |
| `HOST` | Server host | `0.0.0.0` |
| `RUST_LOG` | Log level | `auth_service=debug` |

### .env Example

```bash
DATABASE_URL=127.0.0.1:8000
JWT_SECRET=your-super-secret-key-change-this-in-production
PORT=8001
HOST=0.0.0.0
RUST_LOG=auth_service=debug,tower_http=debug
```

---

## Development

### Local Setup

```bash
# Navigate to service
cd services/auth_service

# Copy environment file
cp .env.example .env

# Install dependencies
cargo build

# Run service
cargo run

# Watch mode (requires cargo-watch)
cargo watch -x run
```

### Testing Endpoints

**Signup:**
```bash
curl -X POST http://localhost:8001/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "role": "dispatcher"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Validate:**
```bash
TOKEN="your-jwt-token-here"
curl http://localhost:8001/auth/validate \
  -H "Authorization: Bearer $TOKEN"
```

**Refresh:**
```bash
curl -X POST http://localhost:8001/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "your-refresh-token-here"
  }'
```

---

## Production Deployment

### Docker

Create `Dockerfile`:
```dockerfile
FROM rust:1.75 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/auth_service /usr/local/bin/
EXPOSE 8001
CMD ["auth_service"]
```

**Build and run:**
```bash
docker build -t hwy-tms/auth-service:latest .
docker run -p 8001:8001 \
  -e DATABASE_URL=surrealdb:8000 \
  -e JWT_SECRET=production-secret \
  hwy-tms/auth-service:latest
```

### Health Checks

```bash
# Simple health check
curl http://localhost:8001/health

# Response: "Torii Auth Service - Healthy ✅"
```

---

## Monitoring

### Logs

Uses `tracing` crate for structured logging:

```
2025-12-09T10:00:00Z DEBUG auth_service: Connected to SurrealDB
2025-12-09T10:00:01Z INFO  auth_service: Torii Auth Service listening on 0.0.0.0:8001
2025-12-09T10:01:00Z DEBUG auth_service::handlers: User signup: test@example.com
2025-12-09T10:02:00Z DEBUG auth_service::handlers: User login: test@example.com
```

### Metrics (Future)

- Request count per endpoint
- Response time (p50, p95, p99)
- Error rate
- Active users
- Token generation rate

---

## Integration with Other Services

### Flutter Apps

```dart
// Signup
final response = await dio.post('http://api.open-hwy.com/auth/signup',
  data: {
    'email': email,
    'password': password,
    'role': 'dispatcher',
  },
);

// Store tokens
await secureStorage.write(key: 'access_token', value: response.data['access_token']);
await secureStorage.write(key: 'refresh_token', value: response.data['refresh_token']);

// Validate on app launch
final token = await secureStorage.read(key: 'access_token');
final validateResponse = await dio.get('http://api.open-hwy.com/auth/validate',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

### Astro Portal

```typescript
// Login form submission
const response = await fetch('http://api.open-hwy.com/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});

const data = await response.json();
localStorage.setItem('access_token', data.access_token);
localStorage.setItem('refresh_token', data.refresh_token);
```

---

## Troubleshooting

### "Connection refused" error

```bash
# Check if SurrealDB is running
surreal start --log debug

# Check DATABASE_URL environment variable
echo $DATABASE_URL
```

### "Invalid credentials" on signup

```bash
# Ensure password meets requirements
# Ensure role is either "dispatcher" or "driver"
```

### JWT validation fails

```bash
# Check JWT_SECRET matches between signup and validation
# Check token hasn't expired (7 days)
# Check token format: "Bearer <token>"
```

---

## Future Enhancements

- [ ] OAuth2 support (Google, Apple, Microsoft)
- [ ] Two-factor authentication (2FA)
- [ ] Rate limiting per IP
- [ ] Password reset flow
- [ ] Email verification
- [ ] Session management (revoke all sessions)
- [ ] Audit logging (login attempts, password changes)

---

Last Updated: December 9, 2025
