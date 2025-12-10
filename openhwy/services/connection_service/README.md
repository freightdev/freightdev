# Nebula CA Service

Certificate Authority and IP allocation service for HWY-TMS Nebula mesh VPN.

## Features

- Certificate generation for dispatchers and drivers
- IP address allocation (10.42.x.x subnet)
- Certificate revocation
- Certificate verification
- Dispatcher = 10.42.X.1 (own /24 subnet)
- Drivers = 10.42.X.2-254 (in dispatcher's subnet)

## API Endpoints

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

**Response:**
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

### POST /cert/revoke
Revoke a certificate.

**Request:**
```json
{
  "user_id": "users:abc123"
}
```

**Response:**
```json
{
  "revoked": true,
  "revoked_at": "2025-12-09T12:00:00Z"
}
```

### POST /cert/verify
Verify a certificate.

**Request:**
```json
{
  "cert_pem": "-----BEGIN NEBULA CERTIFICATE-----..."
}
```

**Response:**
```json
{
  "valid": true,
  "nebula_ip": "10.42.1.1",
  "issued_at": "2025-12-09T00:00:00Z",
  "expires_at": "2026-12-09T00:00:00Z",
  "revoked": false
}
```

## IP Allocation

### Dispatcher IPs
- Format: `10.42.X.1` where X = dispatcher count + 1
- Each dispatcher gets their own /24 subnet
- Example: 1st dispatcher = 10.42.1.1, 2nd = 10.42.2.1

### Driver IPs
- Format: `10.42.X.Y` where X = dispatcher subnet, Y = 2-254
- Drivers are allocated within their dispatcher's subnet
- Max 253 drivers per dispatcher
- Example: Dispatcher at 10.42.1.1 → Drivers at 10.42.1.2, 10.42.1.3, etc.

## Development

```bash
# Copy environment file
cp .env.example .env

# Run locally
cargo run

# CA will be auto-generated if not found (ca.crt, ca.key)
```

## Testing

```bash
# Issue dispatcher certificate
curl -X POST http://localhost:8003/cert/issue \
  -H "Content-Type: application/json" \
  -d '{"user_id":"users:dispatcher1","role":"dispatcher"}'

# Issue driver certificate
curl -X POST http://localhost:8003/cert/issue \
  -H "Content-Type: application/json" \
  -d '{"user_id":"users:driver1","role":"driver","dispatcher_id":"users:dispatcher1"}'

# Revoke certificate
curl -X POST http://localhost:8003/cert/revoke \
  -H "Content-Type: application/json" \
  -d '{"user_id":"users:driver1"}'
```

## Environment Variables

- `DATABASE_URL`: SurrealDB connection
- `CA_CERT_PATH`: Path to CA certificate file
- `CA_KEY_PATH`: Path to CA private key file
- `LIGHTHOUSE_HOST`: Nebula lighthouse server address
- `SUBNET_BASE`: Base subnet (default: 10.42)
- `PORT`: Server port (default: 8003)

## Certificate Lifecycle

1. User signs up (via auth service)
2. Auth service calls `/cert/issue`
3. CA generates cert with allocated IP
4. Cert returned to user (stored in app)
5. User connects to Nebula mesh
6. If user removed: `/cert/revoke` called
7. Revoked certs cannot connect

## Security

- Ed25519 keys for CA and certificates
- 1-year certificate validity
- Certificates stored in SurrealDB
- Revocation list checked on connection
- Private keys never leave the user's device

## Production Notes

- **Important**: Back up `ca.crt` and `ca.key` securely
- Losing CA keys means regenerating all certificates
- Use hardware security module (HSM) for CA keys in production
- Rotate CA every 5 years

## Integration with Lighthouse

The lighthouse server coordinates NAT traversal. It needs:
- CA certificate to verify connecting nodes
- List of valid IPs

```yaml
# lighthouse.yml
pki:
  ca: /path/to/ca.crt
  cert: /path/to/lighthouse.crt
  key: /path/to/lighthouse.key

lighthouse:
  am_lighthouse: true
  serve_dns: false

listen:
  host: 0.0.0.0
  port: 4242
```
