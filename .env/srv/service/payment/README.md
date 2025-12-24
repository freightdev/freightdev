# README.md

# Payment Service

Enterprise-grade payment processing microservice built with Go, implementing hexagonal architecture for maximum flexibility and maintainability.

## Features

- **Multi-processor Support**: Easily integrate with Stripe, PayPal, and other payment processors
- **Hexagonal Architecture**: Clean separation between business logic and external dependencies
- **Production Ready**: Comprehensive logging, monitoring, error handling, and observability
- **Kubernetes Native**: Ready for cloud deployment with auto-scaling and health checks
- **Security First**: JWT authentication, rate limiting, input validation, and audit logging
- **Database Agnostic**: Repository pattern with PostgreSQL implementation
- **Real-time Notifications**: Webhook-based event system for payment status updates

## Architecture

```
├── Domain Layer (Business Rules)
├── Application Layer (Use Cases)
├── Infrastructure Layer (External Dependencies)
└── Presentation Layer (HTTP API)
```

## Quick Start

1. **Clone and Setup**

```bash
git clone <repo-url>
cd payment-service
cp .env.example .env
# Edit .env with your configuration
```

2. **Start Dependencies**

```bash
docker-compose up -d postgres redis
```

3. **Run Migrations**

```bash
make migrate-up
```

4. **Start Service**

```bash
make run
```

5. **Test API**

```bash
curl -X POST http://localhost:8080/api/v1/payments \
  -H "Authorization: Bearer <your-jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "client-123",
    "merchant_id": "merchant-456",
    "order_id": "order-789",
    "amount": "100.00",
    "currency": "USD",
    "method": "card",
    "description": "Test payment"
  }'
```

## API Endpoints

| Method | Endpoint                        | Description     |
| ------ | ------------------------------- | --------------- |
| POST   | `/api/v1/payments`              | Create payment  |
| GET    | `/api/v1/payments`              | List payments   |
| GET    | `/api/v1/payments/{id}`         | Get payment     |
| POST   | `/api/v1/payments/{id}/process` | Process payment |
| POST   | `/api/v1/payments/{id}/refund`  | Refund payment  |
| DELETE | `/api/v1/payments/{id}/cancel`  | Cancel payment  |
| GET    | `/health`                       | Health check    |

## Configuration

Key environment variables:

- `JWT_SECRET`: JWT signing secret
- `DB_*`: Database connection settings
- `STRIPE_API_KEY`: Stripe integration
- `WEBHOOK_URL`: Notification endpoint
- `RATE_LIMIT_RPS`: Rate limiting configuration

## Deployment

**Docker:**

```bash
make docker-build
make docker-run
```

**Kubernetes:**

```bash
kubectl apply -f deployments/k8s/
```

## Development

```bash
make test          # Run tests
make lint          # Lint code
make security      # Security scan
make dev           # Live reload development
```

This microservice is designed for enterprise use with proper separation of concerns, comprehensive testing, and production-ready deployment configurations.
