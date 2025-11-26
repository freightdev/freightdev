# User Service

Enterprise-grade microservice for user management built with Go, following clean architecture principles.

## Architecture

- **Clean Architecture** with clear separation of concerns
- **Hexagonal Architecture** (Ports & Adapters pattern)
- **Domain-Driven Design** principles
- **SOLID** principles throughout

## Project Structure

```
user_service/
├── cmd/server/           # Application entry point
├── internal/
│   ├── config/          # Configuration management
│   ├── domain/          # Business logic and entities
│   ├── application/     # Use cases and DTOs
│   ├── infrastructure/  # External concerns (DB, Redis)
│   └── shared/          # Shared utilities and middleware
├── deployments/         # Docker and K8s configurations
├── scripts/            # Build and utility scripts
└── docs/               # Documentation
```

## Features

- User CRUD operations
- Profile management
- Password hashing and validation
- Status management (active, suspended, etc.)
- Comprehensive validation
- Database migrations
- Redis caching
- Health checks
- Structured logging
- Graceful shutdown
- Docker support

## Quick Start

1. **Clone the repository**

```bash
git clone <repo-url>
cd user_service
```

2. **Start dependencies**

```bash
make db-setup
```

3. **Run the service**

```bash
make run
```

## API Endpoints

### Users

- `POST /api/v1/users` - Create user
- `GET /api/v1/users/:id` - Get user by ID
- `GET /api/v1/users/email/:email` - Get user by email
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user
- `POST /api/v1/users/:id/activate` - Activate user
- `POST /api/v1/users/:id/suspend` - Suspend user
- `GET /api/v1/users` - List users with filtering

### Health

- `GET /health` - Health check
- `GET /health/ready` - Readiness check
- `GET /health/live` - Liveness check

## Environment Variables

See `.env.example` for all configuration options.

## Development

```bash
# Install dependencies
make deps

# Run tests
make test

# Format code
make fmt

# Run with hot reload
make dev

# Run database migrations
make migrate-up
```

## Deployment

```bash
# Build Docker image
make docker-build

# Run with Docker Compose
make docker-run
```
