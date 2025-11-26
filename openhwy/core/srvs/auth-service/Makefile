# Makefile
.DEFAULT_GOAL := help
.PHONY: help build test clean docker run dev migrate lint security deps tools install

# Variables
APP_NAME := auth-service
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GO_VERSION := $(shell go version | cut -d " " -f 3)

# Build flags
LDFLAGS := -ldflags "-X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.gitCommit=${GIT_COMMIT} -w -s"

# Docker
DOCKER_REGISTRY := your-registry.com
DOCKER_IMAGE := ${DOCKER_REGISTRY}/${APP_NAME}
DOCKER_TAG := ${VERSION}

# Database
DB_URL := postgres://postgres:password@localhost:5432/auth_service?sslmode=disable
MIGRATE_DIR := ./migrations

help: ## Show this help message
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development
dev: ## Run in development mode with hot reload
	@echo "🚀 Starting development server with hot reload..."
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build

dev-clean: ## Clean development environment
	@echo "🧹 Cleaning development environment..."
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans

# Build
build: clean ## Build the application
	@echo "🔨 Building ${APP_NAME} ${VERSION}..."
	@mkdir -p bin/
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build ${LDFLAGS} -o bin/${APP_NAME} cmd/server/main.go
	@echo "✅ Build complete: bin/${APP_NAME}"

build-local: clean ## Build for local development
	@echo "🔨 Building ${APP_NAME} for local development..."
	@mkdir -p bin/
	go build ${LDFLAGS} -o bin/${APP_NAME}-local cmd/server/main.go
	@echo "✅ Local build complete: bin/${APP_NAME}-local"

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf bin/
	@rm -rf coverage.out coverage.html
	@go clean -cache
	@go clean -testcache

# Testing
test: ## Run all tests
	@echo "🧪 Running tests..."
	go test -v -race -timeout=30s ./...

test-coverage: ## Run tests with coverage
	@echo "🧪 Running tests with coverage..."
	go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "📊 Coverage report generated: coverage.html"

test-integration: ## Run integration tests
	@echo "🧪 Running integration tests..."
	docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
	docker-compose -f docker-compose.test.yml down -v

benchmark: ## Run benchmarks
	@echo "⚡ Running benchmarks..."
	go test -bench=. -benchmem ./...

# Docker
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t ${APP_NAME}:${DOCKER_TAG} .
	docker tag ${APP_NAME}:${DOCKER_TAG} ${APP_NAME}:latest
	@echo "✅ Docker image built: ${APP_NAME}:${DOCKER_TAG}"

docker-push: docker-build ## Push Docker image to registry
	@echo "🚀 Pushing Docker image to registry..."
	docker tag ${APP_NAME}:${DOCKER_TAG} ${DOCKER_IMAGE}:${DOCKER_TAG}
	docker tag ${APP_NAME}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
	docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
	docker push ${DOCKER_IMAGE}:latest
	@echo "✅ Docker image pushed: ${DOCKER_IMAGE}:${DOCKER_TAG}"

docker-run: ## Run Docker container locally
	@echo "🐳 Running Docker container..."
	docker run --rm -p 8080:8080 --env-file .env.docker ${APP_NAME}:latest

# Docker Compose
up: ## Start all services with docker-compose
	@echo "🚀 Starting services..."
	docker-compose up -d
	@echo "✅ Services started. Auth service available at http://localhost:8080"

down: ## Stop all services
	@echo "🛑 Stopping services..."
	docker-compose down
	@echo "✅ Services stopped"

logs: ## Show logs from all services
	docker-compose logs -f

restart: down up ## Restart all services

# Database
migrate-up: ## Run database migrations
	@echo "📊 Running database migrations..."
	migrate -path ${MIGRATE_DIR} -database "${DB_URL}" up
	@echo "✅ Migrations applied"

migrate-down: ## Rollback database migrations
	@echo "📊 Rolling back database migrations..."
	migrate -path ${MIGRATE_DIR} -database "${DB_URL}" down
	@echo "✅ Migrations rolled back"

migrate-reset: ## Reset database (down and up)
	@echo "🔄 Resetting database..."
	migrate -path ${MIGRATE_DIR} -database "${DB_URL}" drop -f
	migrate -path ${MIGRATE_DIR} -database "${DB_URL}" up
	@echo "✅ Database reset complete"

migrate-create: ## Create new migration (usage: make migrate-create name=add_users_table)
	@if [ -z "$(name)" ]; then echo "❌ Please provide migration name: make migrate-create name=migration_name"; exit 1; fi
	@echo "📝 Creating migration: $(name)"
	migrate create -ext sql -dir ${MIGRATE_DIR} -seq $(name)
	@echo "✅ Migration created in ${MIGRATE_DIR}"

# Code Quality
lint: ## Run linter
	@echo "🔍 Running linter..."
	golangci-lint run ./...
	@echo "✅ Linting complete"

fmt: ## Format code
	@echo "💅 Formatting code..."
	go fmt ./...
	goimports -w .
	@echo "✅ Code formatted"

vet: ## Run go vet
	@echo "🔍 Running go vet..."
	go vet ./...
	@echo "✅ Vet complete"

# Security
security: ## Run security scan
	@echo "🔒 Running security scan..."
	gosec ./...
	@echo "✅ Security scan complete"

security-deps: ## Check for vulnerable dependencies
	@echo "🔒 Checking for vulnerable dependencies..."
	go list -json -deps ./... | nancy sleuth
	@echo "✅ Dependency security check complete"

# Dependencies
deps: ## Download dependencies
	@echo "📦 Downloading dependencies..."
	go mod download
	go mod verify
	@echo "✅ Dependencies downloaded"

deps-update: ## Update dependencies
	@echo "🔄 Updating dependencies..."
	go get -u ./...
	go mod tidy
	@echo "✅ Dependencies updated"

deps-audit: ## Audit dependencies
	@echo "🔍 Auditing dependencies..."
	go mod verify
	go list -m -u all
	@echo "✅ Dependency audit complete"

# Tools
tools: ## Install development tools
	@echo "🔧 Installing development tools..."
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/securecodewarrior/github-action-add-sarif@latest
	go install github.com/sonatypeoss/nancy@latest
	curl -sSfL https://raw.githubusercontent.com/securecodewarrior/github-action-add-sarif/main/install.sh | sh -s -- -b $(go env GOPATH)/bin
	@echo "✅ Development tools installed"

# Kubernetes
k8s-deploy: ## Deploy to Kubernetes
	@echo "🚀 Deploying to Kubernetes..."
	kubectl apply -f kubernetes/
	@echo "✅ Deployed to Kubernetes"

k8s-delete: ## Delete from Kubernetes
	@echo "🗑️ Deleting from Kubernetes..."
	kubectl delete -f kubernetes/
	@echo "✅ Deleted from Kubernetes"

k8s-logs: ## Show Kubernetes logs
	kubectl logs -f deployment/auth-service -n auth-service

# Monitoring
monitor: ## Start monitoring stack (Prometheus, Grafana)
	@echo "📊 Starting monitoring stack..."
	docker-compose -f docker-compose.monitoring.yml up -d
	@echo "✅ Monitoring available at:"
	@echo "  - Prometheus: http://localhost:9090"
	@echo "  - Grafana: http://localhost:3000 (admin/admin)"

# Load Testing
load-test: ## Run load tests
	@echo "⚡ Running load tests..."
	@if ! command -v k6 >/dev/null; then echo "❌ k6 not installed. Install from https://k6.io/docs/get-started/installation/"; exit 1; fi
	k6 run scripts/load-test.js

# Release
release: lint test security docker-build ## Build release version
	@echo "🎉 Release ${VERSION} ready!"
	@echo "Docker image: ${APP_NAME}:${DOCKER_TAG}"

# Installation
install: build ## Install binary to $GOPATH/bin
	@echo "📦 Installing ${APP_NAME}..."
	go install ${LDFLAGS} ./cmd/server
	@echo "✅ Installed to $(shell go env GOPATH)/bin/${APP_NAME}"

# Environment setup
setup: ## Initial project setup
	@echo "🔧 Setting up project..."
	@cp .env.example .env
	@echo "📝 Please edit .env file with your configuration"
	@make tools
	@make deps
	@echo "✅ Project setup complete!"
