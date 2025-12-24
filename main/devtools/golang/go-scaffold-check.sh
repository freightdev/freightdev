#!/bin/bash

# scripts/go-scaffold-check.sh - Check and create enterprise-grade Go project structure
# Ensures project follows best practices for scalability

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="."
SCAFFOLD_LOG="scaffold-check-$(date +%Y%m%d-%H%M%S).log"

log_check() {
    echo -e "$1" | tee -a "$SCAFFOLD_LOG"
}

echo -e "${BLUE}=== Enterprise Go Project Scaffold Check ===${NC}"

# Expected enterprise project structure
declare -A EXPECTED_DIRS=(
    ["cmd"]="Main applications for this project"
    ["pkg"]="Library code that can be imported by external applications"
    ["internal"]="Private application and library code"
    ["api"]="OpenAPI/Swagger specs, JSON schema files, protocol definition files"
    ["web"]="Web application specific components"
    ["configs"]="Configuration file templates or default configs"
    ["init"]="System init (systemd, upstart, sysv) and process manager/supervisor configs"
    ["scripts"]="Scripts to perform various build, install, analysis, etc operations"
    ["build"]="Packaging and Continuous Integration"
    ["deployments"]="IaaS, PaaS, system and container orchestration deployment configurations"
    ["test"]="Additional external test apps and test data"
    ["docs"]="Design and user documents"
    ["tools"]="Supporting tools for this project"
    ["examples"]="Examples for your applications and/or public libraries"
    ["assets"]="Other assets to go along with your repository (images, logos, etc)"
)

declare -A EXPECTED_FILES=(
    ["go.mod"]="Go module definition"
    ["go.sum"]="Go module checksums"
    ["README.md"]="Project documentation"
    [".gitignore"]="Git ignore rules"
    ["Makefile"]="Build automation"
    ["Dockerfile"]="Container definition"
    [".golangci.yml"]="Linting configuration"
    ["LICENSE"]="Project license"
)

# Check current structure
check_current_structure() {
    log_check "${YELLOW}Analyzing current project structure...${NC}"
    
    local score=0
    local max_score=0
    
    # Check directories
    for dir in "${!EXPECTED_DIRS[@]}"; do
        ((max_score++))
        if [[ -d "$dir" ]]; then
            log_check "${GREEN}✓ $dir/ - ${EXPECTED_DIRS[$dir]}${NC}"
            ((score++))
        else
            log_check "${YELLOW}✗ $dir/ - Missing: ${EXPECTED_DIRS[$dir]}${NC}"
        fi
    done
    
    # Check files
    for file in "${!EXPECTED_FILES[@]}"; do
        ((max_score++))
        if [[ -f "$file" ]]; then
            log_check "${GREEN}✓ $file - ${EXPECTED_FILES[$file]}${NC}"
            ((score++))
        else
            log_check "${YELLOW}✗ $file - Missing: ${EXPECTED_FILES[$file]}${NC}"
        fi
    done
    
    log_check "${BLUE}Structure Score: $score/$max_score${NC}"
    
    if (( score < max_score / 2 )); then
        log_check "${RED}Project structure needs significant improvement${NC}"
    elif (( score < (max_score * 3 / 4) )); then
        log_check "${YELLOW}Project structure is partial - consider improvements${NC}"
    else
        log_check "${GREEN}Good project structure!${NC}"
    fi
}

# Create missing structure
create_missing_structure() {
    echo -e "${YELLOW}Creating missing directories and files...${NC}"
    
    # Create directories with appropriate files
    for dir in "${!EXPECTED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            read -p "Create $dir/ directory? [y/N]: " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$dir"
                
                # Add appropriate starter files
                case $dir in
                    "cmd")
                        mkdir -p "$dir/$(basename "$PWD")"
                        cat > "$dir/$(basename "$PWD")/main.go" << 'EOF'
package main

import (
	"fmt"
	"log"
)

func main() {
	fmt.Println("Hello from $(basename "$PWD")!")
	log.Println("Application started")
}
EOF
                        ;;
                    "pkg")
                        mkdir -p "$dir/$(basename "$PWD")"
                        cat > "$dir/$(basename "$PWD")/service.go" << 'EOF'
package $(basename "$PWD")

// Service represents the main service interface
type Service interface {
	Start() error
	Stop() error
}

// Implementation of the service
type serviceImpl struct {
	// Add your fields here
}

// NewService creates a new service instance
func NewService() Service {
	return &serviceImpl{}
}

func (s *serviceImpl) Start() error {
	// Implementation here
	return nil
}

func (s *serviceImpl) Stop() error {
	// Implementation here
	return nil
}
EOF
                        ;;
                    "internal")
                        mkdir -p "$dir/config"
                        mkdir -p "$dir/handler"
                        mkdir -p "$dir/repository"
                        mkdir -p "$dir/service"
                        cat > "$dir/config/config.go" << 'EOF'
package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port     int
	Database DatabaseConfig
}

type DatabaseConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	Database string
}

func Load() *Config {
	port, _ := strconv.Atoi(getEnv("PORT", "8080"))
	dbPort, _ := strconv.Atoi(getEnv("DB_PORT", "5432"))

	return &Config{
		Port: port,
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     dbPort,
			Username: getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASS", ""),
			Database: getEnv("DB_NAME", "myapp"),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
EOF
                        ;;
                    "scripts")
                        cat > "$dir/build.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Building application..."
go build -o bin/$(basename "$PWD") ./cmd/$(basename "$PWD")/

echo "Build complete: bin/$(basename "$PWD")"
EOF
                        chmod +x "$dir/build.sh"
                        ;;
                    "test")
                        cat > "$dir/integration_test.go" << 'EOF'
// +build integration

package test

import (
	"testing"
)

func TestIntegration(t *testing.T) {
	// Integration tests go here
	t.Log("Integration test placeholder")
}
EOF
                        ;;
                esac
                
                log_check "${GREEN}Created $dir/${NC}"
            fi
        fi
    done
    
    # Create missing files
    for file in "${!EXPECTED_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            read -p "Create $file? [y/N]: " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                case $file in
                    "README.md")
                        cat > "$file" << EOF
# $(basename "$PWD")

## Description
A brief description of your project.

## Installation
\`\`\`bash
go mod download
go build -o bin/$(basename "$PWD") ./cmd/$(basename "$PWD")/
\`\`\`

## Usage
\`\`\`bash
./bin/$(basename "$PWD")
\`\`\`

## Development
\`\`\`bash
# Run tests
go test ./...

# Run with race detection
go run -race ./cmd/$(basename "$PWD")/

# Build for production
make build
\`\`\`

## License
See LICENSE file.
EOF
                        ;;
                    "Makefile")
                        cat > "$file" << 'EOF'
.PHONY: build test clean lint run

BINARY_NAME=$(shell basename $(PWD))
BUILD_DIR=bin

build:
	go build -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/$(BINARY_NAME)/

test:
	go test ./...

test-integration:
	go test -tags=integration ./test/...

clean:
	rm -rf $(BUILD_DIR)

lint:
	golangci-lint run

run:
	go run ./cmd/$(BINARY_NAME)/

deps:
	go mod download
	go mod tidy

.DEFAULT_GOAL := build
EOF
                        ;;
                    ".gitignore")
                        cat > "$file" << 'EOF'
# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with `go test -c`
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
vendor/

# Go workspace file
go.work

# Build output
bin/
build/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Environment files
.env
.env.local

# Log files
*.log
EOF
                        ;;
                    ".golangci.yml")
                        cat > "$file" << 'EOF'
run:
  timeout: 5m
  modules-download-mode: readonly

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - goimports
    - misspell
    - gocritic
    - gofmt
    - revive

linters-settings:
  revive:
    rules:
      - name: var-naming
      - name: package-comments
      - name: exported
EOF
                        ;;
                    "Dockerfile")
                        cat > "$file" << EOF
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/$(basename "$PWD")/

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .

CMD ["./main"]
EOF
                        ;;
                    "LICENSE")
                        echo "# Add your license here" > "$file"
                        ;;
                esac
                
                log_check "${GREEN}Created $file${NC}"
            fi
        fi
    done
}

# Check Go module structure
check_go_module() {
    log_check "${YELLOW}Checking Go module structure...${NC}"
    
    if [[ ! -f "go.mod" ]]; then
        read -p "Initialize Go module? Enter module name: " module_name
        if [[ -n "$module_name" ]]; then
            go mod init "$module_name"
            log_check "${GREEN}Initialized Go module: $module_name${NC}"
        fi
    else
        module_name=$(head -n 1 go.mod | cut -d' ' -f2)
        log_check "${GREEN}Go module: $module_name${NC}"
    fi
    
    # Check if module name follows conventions
    if [[ "$module_name" =~ ^github\.com/|^gitlab\.com/|^bitbucket\.org/ ]]; then
        log_check "${GREEN}✓ Module name follows VCS convention${NC}"
    else
        log_check "${YELLOW}⚠ Consider using VCS-based module name (github.com/user/repo)${NC}"
    fi
}

# Generate project health report
generate_health_report() {
    echo -e "${BLUE}=== Project Health Report ===${NC}" | tee -a "$SCAFFOLD_LOG"
    
    # Check build status
    if go build ./... > /dev/null 2>&1; then
        log_check "${GREEN}✓ Project builds successfully${NC}"
    else
        log_check "${RED}✗ Project has build errors${NC}"
    fi
    
    # Check test compilation
    if go test -c ./... > /dev/null 2>&1; then
        log_check "${GREEN}✓ Tests compile successfully${NC}"
    else
        log_check "${RED}✗ Tests have compilation errors${NC}"
    fi
    
    # Check for main packages
    main_packages=$(find . -name "*.go" -exec grep -l "package main" {} \; | wc -l)
    log_check "${BLUE}Main packages found: $main_packages${NC}"
    
    # Check dependencies
    if [[ -f "go.mod" ]]; then
        dep_count=$(go list -m all | wc -l)
        log_check "${BLUE}Total dependencies: $((dep_count - 1))${NC}"
    fi
    
    # Check code coverage potential
    if go test -cover ./... > /dev/null 2>&1; then
        coverage=$(go test -cover ./... 2>/dev/null | grep -E "coverage:" | tail -1 | awk '{print $5}' || echo "0%")
        log_check "${BLUE}Test coverage: $coverage${NC}"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Analyzing: $(pwd)${NC}"
    
    check_current_structure
    echo
    
    check_go_module
    echo
    
    generate_health_report
    echo
    
    read -p "Create missing structure? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_missing_structure
        
        echo -e "\n${BLUE}Re-checking structure after creation...${NC}"
        check_current_structure
    fi
    
    echo -e "\n${YELLOW}Report saved to: $SCAFFOLD_LOG${NC}"
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Review and customize created files"
    echo "  2. Run 'go mod tidy' to clean dependencies"
    echo "  3. Initialize git repository if needed"
    echo "  4. Set up CI/CD pipeline"
    echo "  5. Add comprehensive tests"
}

main "$@"