#!/bin/bash

# analyze-ocs-structure.sh - Analyze and fix issues specific to your OCS project structure

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔬 OCS Project Structure Analysis${NC}"

# Analyze each component of your project
analyze_component() {
    local component="$1"
    local description="$2"
    
    echo -e "\n${YELLOW}📂 Analyzing $component - $description${NC}"
    
    if [[ -d "$component" ]]; then
        local go_files=$(find "$component" -name "*.go" | wc -l)
        echo "  Go files: $go_files"
        
        # Check if it compiles
        if go build "./$component" > /dev/null 2>&1; then
            echo -e "  Status: ${GREEN}✓ Compiles${NC}"
        else
            echo -e "  Status: ${RED}✗ Build errors${NC}"
            echo "  Errors:"
            go build "./$component" 2>&1 | head -3 | sed 's/^/    /'
        fi
        
        # Check for common issues in this component
        case "$component" in
            "api")
                check_api_component
                ;;
            "managers")
                check_managers_component
                ;;
            "models")
                check_models_component
                ;;
            "src/tools")
                check_tools_component
                ;;
            "cmd")
                check_main_component
                ;;
        esac
    else
        echo -e "  Status: ${RED}✗ Directory missing${NC}"
    fi
}

check_api_component() {
    echo "  🔍 API Component Analysis:"
    
    # Check for handler issues
    if [[ -f "api/handler/authentication-handler.go" ]]; then
        if grep -q "package handler" "api/handler/authentication-handler.go"; then
            echo "    ✓ Authentication handler package correct"
        else
            echo "    ⚠ Check authentication handler package declaration"
        fi
    fi
    
    # Check REST API
    if [[ -f "api/rest-api.go" ]]; then
        if grep -q "package api" "api/rest-api.go"; then
            echo "    ✓ REST API package correct"
        fi
    fi
    
    # Check gRPC API
    if [[ -f "api/grpc-api.go" ]]; then
        if grep -q "package api" "api/grpc-api.go"; then
            echo "    ✓ gRPC API package correct"
        fi
        
        # Check for protobuf imports
        if grep -q "google.golang.org/grpc" "api/grpc-api.go"; then
            echo "    ✓ gRPC imports found"
        else
            echo "    ⚠ Missing gRPC imports - may need: go get google.golang.org/grpc"
        fi
    fi
}

check_managers_component() {
    echo "  🔍 Managers Component Analysis:"
    
    local managers=(
        "config-manager.go"
        "conversation-manager.go"
        "disk-manager.go"
        "inference-manager.go"
        "memory-manager.go"
        "model-manager.go"
        "session-manager.go"
        "token-manager.go"
        "websocket-manager.go"
    )
    
    for manager in "${managers[@]}"; do
        if [[ -f "managers/$manager" ]]; then
            if grep -q "package managers" "managers/$manager"; then
                echo "    ✓ $manager package correct"
            else
                echo "    ⚠ $manager package declaration issue"
            fi
        else
            echo "    ⚠ Missing: $manager"
        fi
    done
    
    # Check for circular dependencies
    echo "  🔄 Checking for circular dependencies in managers..."
    local cycle_check=$(go list ./managers 2>&1 | grep -i "import cycle" || true)
    if [[ -n "$cycle_check" ]]; then
        echo "    ❌ Import cycle detected in managers!"
        echo "$cycle_check" | sed 's/^/      /'
    else
        echo "    ✓ No import cycles detected"
    fi
}

check_models_component() {
    echo "  🔍 Models Component Analysis:"
    
    local models=("chat-model.go" "code-model.go" "reasoning-model.go")
    
    for model in "${models[@]}"; do
        if [[ -f "models/$model" ]]; then
            if grep -q "package models" "models/$model"; then
                echo "    ✓ $model package correct"
            else
                echo "    ⚠ $model package declaration issue"
            fi
        fi
    done
}

check_tools_component() {
    echo "  🔍 Tools Component Analysis:"
    
    local tools=("code-tools.go" "file-tools.go" "search-tools.go")
    
    for tool in "${tools[@]}"; do
        if [[ -f "src/tools/$tool" ]]; then
            if grep -q "package tools" "src/tools/$tool"; then
                echo "    ✓ $tool package correct"
            else
                echo "    ⚠ $tool package declaration issue"
            fi
        fi
    done
}

check_main_component() {
    echo "  🔍 Main Component Analysis:"
    
    if [[ -f "cmd/main.go" ]]; then
        if grep -q "package main" "cmd/main.go"; then
            echo "    ✓ main.go package correct"
        else
            echo "    ❌ main.go must have 'package main'"
        fi
        
        if grep -q "func main" "cmd/main.go"; then
            echo "    ✓ main function exists"
        else
            echo "    ❌ main function missing"
        fi
        
        # Check imports in main
        echo "    📦 Checking main.go imports..."
        local main_imports=$(grep -E "^\s*\"" "cmd/main.go" | wc -l || echo "0")
        echo "    Import count: $main_imports"
        
    else
        echo "    ❌ cmd/main.go missing!"
    fi
}

# Run analysis
echo -e "${BLUE}Starting comprehensive OCS analysis...${NC}"

# Analyze each component
analyze_component "cmd" "Main application entry point"
analyze_component "api" "REST and gRPC API layer"
analyze_component "managers" "Business logic managers"
analyze_component "models" "Data models and structures"
analyze_component "src/tools" "Utility tools and helpers"
analyze_component "src/utils" "Utility functions"
analyze_component "databases" "Database layer"

# Check configurations
echo -e "\n${YELLOW}📂 Analyzing configs${NC}"
if [[ -d "configs" ]]; then
    echo "  YAML files found:"
    find configs -name "*.yaml" | sed 's/^/    /'
    
    # Check if config loading works
    if grep -r "yaml" . --include="*.go" | grep -q "config"; then
        echo "  ✓ YAML config loading code found"
    else
        echo "  ⚠ No YAML config loading detected"
    fi
else
    echo "  ❌ configs directory missing"
fi

# Overall build test
echo -e "\n${BLUE}🏗️ Overall Build Test${NC}"
if go build ./...; then
    echo -e "${GREEN}✅ All packages build successfully!${NC}"
    
    # Try main binary build
    if go build -o ollama-control-service ./cmd; then
        echo -e "${GREEN}🎉 Main binary builds successfully!${NC}"
        echo "Binary: ./ollama-control-service"
        ls -lah ollama-control-service
    else
        echo -e "${RED}❌ Main binary build failed${NC}"
    fi
else
    echo -e "${RED}❌ Build issues detected${NC}"
    
    # Provide specific fixes
    echo -e "\n${YELLOW}🛠️ Suggested Fixes:${NC}"
    
    # Try to build each package and suggest fixes
    local packages=("cmd" "api" "managers" "models" "src/tools" "src/utils" "databases")
    
    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            if ! go build "./$pkg" > /dev/null 2>&1; then
                echo -e "  ${RED}❌ $pkg has issues:${NC}"
                go build "./$pkg" 2>&1 | head -2 | sed 's/^/      /'
                
                # Suggest specific fixes based on errors
                local errors=$(go build "./$pkg" 2>&1)
                
                if echo "$errors" | grep -q "undefined:"; then
                    echo "      💡 Fix: Check imports and function names"
                fi
                
                if echo "$errors" | grep -q "imported and not used"; then
                    echo "      💡 Fix: Run 'goimports -w ./$pkg'"
                fi
                
                if echo "$errors" | grep -q "package"; then
                    echo "      💡 Fix: Check package declaration matches directory name"
                fi
            fi
        fi
    done
fi

# Provide actionable next steps
echo -e "\n${BLUE}🎯 Next Steps:${NC}"

if go build -o ollama-control-service ./cmd > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Your project is ready!${NC}"
    echo "  Run: ./ollama-control-service"
else
    echo -e "${YELLOW}📋 To fix your project:${NC}"
    echo "  1. Run: goimports -w ."
    echo "  2. Run: go mod tidy"
    echo "  3. Fix any package declaration issues shown above"
    echo "  4. Run: go build -o ollama-control-service ./cmd"
    echo "  5. If still failing, run: ./scripts/helpers/go-project/go-debug-toolkit.sh"
fi

echo -e "\n${BLUE}🚀 Quick Build Command:${NC}"
echo "go build -o ollama-control-service ./cmd"