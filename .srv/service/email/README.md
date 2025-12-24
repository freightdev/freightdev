# Email Service

**Go-based email service for CoDriver autonomous agent**

Handles all email communication between CoDriver and the user (jesse.freightdev@gmail.com).

## Features

- ✅ Send approval requests
- ✅ Send daily trucking intelligence digests
- ✅ Send notifications and alerts
- ✅ Send status reports
- ✅ Gmail SMTP integration
- ✅ Simple HTTP API

## Quick Start

### 1. Setup
```bash
make setup
```

Edit `.env` with your Gmail App Password.

### 2. Get Gmail App Password

1. Go to https://myaccount.google.com/apppasswords
2. Sign in to your Google account
3. Select "Mail" → "Other (Custom name)"
4. Enter: "CoDriver Email Service"
5. Click "Generate"
6. Copy the 16-character password
7. Paste into `.env` as `SMTP_PASSWORD`

### 3. Run
```bash
make run
```

Service runs on **port 9011**.

## Configuration

Edit `.env`:

```env
# Server
PORT=9011

# User email (where to send notifications)
USER_EMAIL=jesse.freightdev@gmail.com

# SMTP (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-gmail@gmail.com
SMTP_PASSWORD=your-gmail-app-password

# From email
FROM_EMAIL=codriver@freightdev.local
FROM_NAME=CoDriver AI Agent
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Send Approval Request
```bash
POST /email/approval
Content-Type: application/json

{
  "approval_id": "abc-123",
  "action": "Create new agent",
  "risk_level": "Medium",
  "details": "This will create a route optimizer agent...",
  "recommendation": "APPROVE - High value, low risk"
}
```

### Send Daily Digest
```bash
POST /email/digest
Content-Type: application/json

{
  "date": "2025-01-15",
  "summary": "Freight rates trending upward...",
  "freight_rates": {
    "van_rate": 2.45,
    "van_trend": "rising",
    "reefer_rate": 2.89,
    "reefer_trend": "rising",
    "flatbed_rate": 2.67,
    "flatbed_trend": "stable",
    "overall_trend": "rising"
  },
  "news_count": 47,
  "regulation_count": 3
}
```

### Send Notification
```bash
POST /email/notification
Content-Type: application/json

{
  "title": "Agent deployed successfully",
  "message": "Route optimizer is now online",
  "priority": "normal"
}
```

Priority: `low`, `normal`, `high`, `critical`

### Send Status Report
```bash
POST /email/status
Content-Type: application/json

{
  "agents_online": ["data-collector", "web-scraper"],
  "agents_offline": [],
  "recent_decisions": ["Updated trucking intel", "Collected rates"],
  "pending_approvals": 1
}
```

### Send Alert
```bash
POST /email/alert
Content-Type: application/json

{
  "error": "Data collector not responding",
  "details": "Unable to connect to port 9006"
}
```

## Development

```bash
# Run with hot reload
make dev

# Run tests
make test

# Format code
make fmt

# Lint
make lint

# Send test email
make test-send
```

## Integration with CoDriver

CoDriver (Rust) calls this service via HTTP:

```rust
// In CoDriver autonomous agent
let client = reqwest::Client::new();

// Send approval request
let response = client
    .post("http://localhost:9011/email/approval")
    .json(&serde_json::json!({
        "approval_id": approval_id,
        "action": "Deploy new agent",
        "risk_level": "Medium",
        "details": "...",
        "recommendation": "APPROVE"
    }))
    .send()
    .await?;
```

## Architecture

```
CoDriver (Rust Agent)
  ↓ HTTP POST
Email Service (Go) - Port 9011
  ↓ SMTP
Gmail
  ↓
jesse.freightdev@gmail.com
```

**Clean separation:**
- **Agents (Rust)**: Performance-critical tasks
- **Services (Go)**: Business logic, APIs, external communication

## Testing

```bash
# Start service
make run

# In another terminal, test each endpoint:

# Health check
curl http://localhost:9011/health

# Approval email
curl -X POST http://localhost:9011/email/approval \
  -H "Content-Type: application/json" \
  -d '{
    "approval_id": "test-123",
    "action": "Test approval",
    "risk_level": "Low",
    "details": "Testing email system",
    "recommendation": "APPROVE"
  }'

# Notification
curl -X POST http://localhost:9011/email/notification \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "message": "Email service is working!",
    "priority": "normal"
  }'
```

## Deployment

### Systemd Service

Create `/home/admin/.config/systemd/user/email-service.service`:

```ini
[Unit]
Description=Email Service for CoDriver
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/admin/WORKSPACE/services/email-service
ExecStart=/home/admin/WORKSPACE/services/email-service/bin/email-service
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user daemon-reload
systemctl --user enable email-service
systemctl --user start email-service
```

## Troubleshooting

### Email Not Sending

**Check SMTP config:**
```bash
cat .env | grep SMTP
```

**Test Gmail login:**
```bash
# Use telnet or openssl to test SMTP
openssl s_client -starttls smtp -connect smtp.gmail.com:587
```

**Common issues:**
- Wrong App Password (not regular password!)
- 2FA not enabled on Gmail
- "Less secure apps" blocking (use App Password instead)

### Service Not Starting

```bash
# Check logs
journalctl --user -u email-service -n 50

# Check port in use
lsof -i :9011
```

## Files

```
email-service/
├── cmd/
│   └── server/
│       └── main.go           # Entry point
├── internal/
│   ├── config/
│   │   └── config.go         # Configuration
│   ├── handlers/
│   │   └── handlers.go       # HTTP handlers
│   └── services/
│       └── email_service.go  # Email logic
├── .env.example              # Example config
├── .env                      # Your config (gitignored)
├── go.mod                    # Dependencies
├── Makefile                  # Build commands
└── README.md                 # This file
```

---

**Simple, clean, focused on one job: sending emails for CoDriver** 📧
