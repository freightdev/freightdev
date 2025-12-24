# Makefile
.PHONY: build run test clean docker-build docker-run migrate-up migrate-down

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=payment-service
BINARY_UNIX=$(BINARY_NAME)_unix

# Build the application
build:
$(GOBUILD) -o $(BINARY_NAME) -v ./cmd/server

# Build for Linux
build-linux:
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_UNIX) -v ./cmd/server

# Run the application
run:
$(GOBUILD) -o $(BINARY_NAME) -v ./cmd/server
./$(BINARY_NAME)

# Run with live reload (requires air: go install github.com/cosmtrek/air@latest)
dev:
air

# Test the application
test:
$(GOTEST) -v ./...

# Test with coverage
test-coverage:
$(GOTEST) -v -coverprofile=coverage.out ./...
$(GOCMD) tool cover -html=coverage.out

# Clean build files
clean:
$(GOCLEAN)
rm -f $(BINARY_NAME)
rm -f $(BINARY_UNIX)

# Download dependencies
deps:
$(GOMOD) download
$(GOMOD) tidy

# Security scan (requires gosec: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest)
security:
gosec ./...

# Lint code (requires golangci-lint)
lint:
golangci-lint run

# Format code
fmt:
$(GOCMD) fmt ./...

# Database migrations
migrate-up:
migrate -path migrations -database "postgres://postgres:password@localhost:5432/payment_service?sslmode=disable" up

migrate-down:
migrate -path migrations -database "postgres://postgres:password@localhost:5432/payment_service?sslmode=disable" down

# Docker commands
docker-build:
docker build -t payment-service .

docker-run:
docker run -p 8080:8080 --env-file .env payment-service

# Docker compose
compose-up:
docker-compose up -d

compose-down:
docker-compose down

# Generate API documentation (requires swag: go install github.com/swaggo/swag/cmd/swag@latest)
docs:
swag init -g cmd/server/main.go

# docker/Dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

# Install git and ca-certificates
RUN apk --no-cache add git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o payment-service ./cmd/server

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S appuser -G appgroup

WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/payment-service .

# Copy migrations
COPY --from=builder /app/migrations ./migrations

# Change ownership to non-root user
RUN chown -R appuser:appgroup /root
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["./payment-service"]
