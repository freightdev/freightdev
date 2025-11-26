# README.md

# Auth Service

A production-ready, enterprise-grade authentication microservice built with Go. Features JWT tokens, role-based access control, rate limiting, and comprehensive security measures.

## 🚀 Features

- **Authentication & Authorization**
    - JWT access & refresh tokens
    - Role-based permissions (RBAC)
    - Session management with device tracking
    - Password reset & email verification flows

- **Security**
    - Bcrypt password hashing
    - Rate limiting & account lockout protection
    - Token blacklisting
    - Input validation & sanitization
    - CORS protection

- **Enterprise Ready**
    - Structured logging with slog
    - Comprehensive error handling
    - Health checks & metrics
    - Database migrations
    - Docker & Kubernetes deployment
    - Horizontal auto-scaling

- **Development Experience**
    - Hot reload with Air
    - Comprehensive test suite
    - Load testing with k6
    - Development tooling & scripts

## 🏗️ Architecture

The service follows Clean Architecture principles:

```
cmd/server/          # Application entry point
internal/
  ├── config/        # Configuration management
  ├── domain/        # Business entities & rules
  ├── handlers/      # HTTP handlers (controllers)
  ├── services/      # Business logic
  ├── repositories/  # Data access layer
  └── middleware/    # Cross-cutting concerns
pkg/
  ├── types/         # Shared types & DTOs
  └── errors/        # Error definitions
migrations/          # Database schema
kubernetes/          # K8s deployment manifests
scripts/            # Utility scripts
```

## 🚦 Quick Start

### Prerequisites

- Go 1.21+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

### Development Setup

1. **Clone & Setup**

    ```bash
    git clone <repo-url>
    cd auth-service
    make setup
    ```

2. **Configure Environment**

    ```bash
    cp .env.example .env
    # Edit .env with your configuration
    ```

3. **Start Development Environment**
    ```bash
    make dev
    ```

The service will be available at `http://localhost:8080`

### API Endpoints

#### Authentication

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout (single session)
- `POST /api/v1/auth/logout-all` - Logout all sessions

#### Password Management

- `POST /api/v1/auth/forgot-password` - Request password reset
- `POST /api/v1/auth/reset-password` - Confirm password reset
- `POST /api/v1/auth/change-password` - Change password (authenticated)

#### User Profile

- `GET /api/v1/profile` - Get user profile
- `PUT /api/v1/profile` - Update user profile

#### Verification

- `GET /api/v1/auth/verify-email?token=xxx` - Verify email address

## 🔧 Development Commands

```bash
# Development
make dev              # Start with hot reload
make dev-clean        # Clean dev environment

# Building
make build            # Build production binary
make build-local      # Build for local development

# Testing
make test             # Run all tests
make test-coverage    # Run tests with coverage
make benchmark        # Run benchmarks
make load-test        # Run load tests

# Code Quality
make lint             # Run linter
make fmt              # Format code
make security         # Security scan

# Database
make migrate-up       # Apply migrations
make migrate-down     # Rollback migrations
make migrate-create name=migration_name  # Create new migration

# Docker
make docker-build     # Build Docker image
make up               # Start all services
make down             # Stop all services

# Kubernetes
make k8s-deploy       # Deploy to Kubernetes
make k8s-delete       # Remove from Kubernetes
```

## 🐳 Deployment

### Docker Compose (Recommended for Development)

```bash
# Production
docker-compose up -d

# Development with hot reload
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Kubernetes (Production)

```bash
# Deploy
kubectl apply -f kubernetes/

# Check status
kubectl get pods -n auth-service

# View logs
kubectl logs -f deployment/auth-service -n auth-service
```

## 🔒 Security Features

- **Password Security**: Bcrypt hashing with proper salt
- **JWT Security**: Separate secrets for access/refresh tokens, JTI tracking
- **Rate Limiting**: Configurable request limits and account lockout
- **Session Management**: Device tracking with IP and User-Agent
- **Input Validation**: Comprehensive validation with go-playground/validator
- **SQL Injection Protection**: Parameterized queries throughout

## 📊 Monitoring & Observability

- **Health Checks**: `/health` endpoint with dependency checking
- **Structured Logging**: JSON logging with request tracing
- **Metrics**: Prometheus metrics (when enabled)
- **Tracing**: Distributed tracing support (OpenTelemetry ready)

## 🧪 Testing

The service includes comprehensive testing:

```bash
# Unit tests
make test

# Integration tests
make test-integration

# Load tests
make load-test

# Coverage report
make test-coverage
```

## 📝 Configuration

All configuration via environment variables. See `.env.example` for available options.

Key configurations:

- **JWT Secrets**: Must be changed in production
- **Database**: PostgreSQL connection settings
- **Redis**: For session storage and rate limiting
- **SMTP**: For email verification and password reset
- **Security**: Rate limits, lockout settings, password policies

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run `make lint` and `make test`
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

- Create an issue on GitHub
- Check the documentation in `/docs`
- Review the API documentation (OpenAPI spec coming soon)

---

**Built with ❤️ using Go, following enterprise best practices for production-ready microservices.**
