# Makefile
.PHONY: build run test clean docker-build docker-run migrate-up migrate-down

# Go parameters
BINARY_NAME=user_service
MAIN_PATH=cmd/server/main.go

# Build the application
build:
	go build -o bin/$(BINARY_NAME) $(MAIN_PATH)

# Run the application
run:
	go run $(MAIN_PATH)

# Run tests
test:
	go test -v ./...

# Clean build artifacts
clean:
	go clean
	rm -rf bin/

# Install dependencies
deps:
	go mod download
	go mod tidy

# Format code
fmt:
	go fmt ./...

# Lint code
lint:
	golangci-lint run

# Run database migrations
migrate-up:
	migrate -path internal/infrastructure/database/migrations -database "postgres://user_service:password123@localhost:5432/user_service?sslmode=disable" up

# Rollback database migrations
migrate-down:
	migrate -path internal/infrastructure/database/migrations -database "postgres://user_service:password123@localhost:5432/user_service?sslmode=disable" down

# Docker build
docker-build:
	docker build -t $(BINARY_NAME):latest .

# Docker run with compose
docker-run:
	docker-compose up --build

# Docker stop
docker-stop:
	docker-compose down

# Generate mocks (if using mockery)
mocks:
	mockery --all --output=tests/mocks

# Database setup for local development
db-setup:
	docker run --name user_service_postgres -e POSTGRES_DB=user_service -e POSTGRES_USER=user_service -e POSTGRES_PASSWORD=password123 -p 5432:5432 -d postgres:15-alpine
	docker run --name user_service_redis -p 6379:6379 -d redis:7-alpine

# Database teardown
db-teardown:
	docker stop user_service_postgres user_service_redis || true
	docker rm user_service_postgres user_service_redis || true

# Hot reload for development (requires air: go install github.com/cosmtrek/air@latest)
dev:
	air

# Load test data
seed:
	go run scripts/seed.go
