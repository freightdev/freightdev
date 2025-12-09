.DEFAULT_GOAL := help
.PHONY: help build run dev test clean

APP_NAME := email-service
PORT := 9011

help: ## Show this help message
	@echo "Email Service - Make targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the service
	@echo "🔨 Building email-service..."
	go build -o bin/$(APP_NAME) cmd/server/main.go
	@echo "✅ Build complete: bin/$(APP_NAME)"

run: build ## Run the service
	@echo "🚀 Starting email-service..."
	./bin/$(APP_NAME)

dev: ## Run with auto-reload (requires air)
	@echo "🔄 Starting with hot reload..."
	@if ! command -v air >/dev/null; then \
		echo "Installing air..."; \
		go install github.com/cosmtrek/air@latest; \
	fi
	air

test: ## Run tests
	@echo "🧪 Running tests..."
	go test -v ./...

test-send: ## Send test email
	@echo "📧 Sending test email..."
	@curl -X POST http://localhost:$(PORT)/email/notification \
		-H "Content-Type: application/json" \
		-d '{"title":"Test Email","message":"This is a test from email-service","priority":"normal"}'

clean: ## Clean build artifacts
	@echo "🧹 Cleaning..."
	rm -rf bin/
	go clean

setup: ## Initial setup
	@echo "⚙️  Setting up email-service..."
	@cp .env.example .env
	@echo "📝 Edit .env with your Gmail App Password"
	@echo "   Get app password: https://myaccount.google.com/apppasswords"
	@go mod download
	@echo "✅ Setup complete!"

deps: ## Download dependencies
	@echo "📦 Downloading dependencies..."
	go mod download
	go mod tidy

fmt: ## Format code
	@echo "💅 Formatting code..."
	go fmt ./...

vet: ## Run go vet
	@echo "🔍 Running go vet..."
	go vet ./...

lint: ## Run linter
	@echo "🔍 Running linter..."
	@if command -v golangci-lint >/dev/null; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint not installed. Run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi

# Docker targets (if needed later)
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t $(APP_NAME):latest .

docker-run: ## Run in Docker
	@echo "🐳 Running in Docker..."
	docker run --rm -p $(PORT):$(PORT) --env-file .env $(APP_NAME):latest
