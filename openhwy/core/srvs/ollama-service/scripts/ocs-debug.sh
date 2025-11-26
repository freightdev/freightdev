#!/bin/bash

# ocs-debug.sh - Specific debug script for ollama-control-service
# Analyzes your exact project structure and builds the binary

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Ollama Control Service - Debug & Build${NC}"
echo -e "${YELLOW}Project Structure Analysis...${NC}"

# Check if we're in the right directory
if [[ ! -f "go.mod" ]] || [[ ! -d "cmd" ]]; then
    echo -e "${RED}❌ Run this from your project root (where go.mod exists)${NC}"
    exit 1
fi

# Quick project analysis
echo -e "${BLUE}📊 Project Overview:${NC}"
echo "Main package: $(ls cmd/)"
echo "API handlers: $(ls api/handler/ | wc -l)"
echo "Managers: $(ls managers/ | wc -l)"
echo "Models: $(ls models/ | wc -l)"
echo "Tools: $(ls src/tools/ | wc -l)"

# Check go.mod
MODULE_NAME=$(head -n1 go.mod | cut -d' ' -f2)
echo "Module: $MODULE_NAME"

echo -e "\n${YELLOW}🔍 Quick Health Check...${NC}"

# 1. Check for obvious build issues
echo "1. Testing compilation..."
BUILD_OUTPUT=$(go build ./... 2>&1 || true)

if [[ -z "$BUILD_OUTPUT" ]]; then
    echo -e "${GREEN}✅ All packages compile successfully!${NC}"
    
    # Try building the main binary
    echo -e "\n${BLUE}🚀 Building ollama-control-service...${NC}"
    
    if go build -o ollama-control-service ./cmd; then
        echo -e "${GREEN}🎉 SUCCESS! Binary built: ollama-control-service${NC}"
        echo -e "${BLUE}File info:${NC}"
        ls -lah ollama-control-service
        echo -e "${YELLOW}Run with: ./ollama-control-service${NC}"
        exit 0
    else
        echo -e "${RED}❌ Failed to build main binary${NC}"
        go build -o ollama-control-service ./cmd 2>&1
    fi
else
    echo -e "${RED}❌ Compilation issues found:${NC}"
    echo "$BUILD_OUTPUT" | head -15
    
    echo -e "\n${YELLOW}🛠️  Auto-fixing common issues...${NC}"
    
    # Fix imports
    echo "Fixing imports..."
    if command -v goimports &> /dev/null; then
        find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
        echo -e "${GREEN}✓ Imports fixed${NC}"
    else
        echo "Installing goimports..."
        go install golang.org/x/tools/cmd/goimports@latest
        find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
        echo -e "${GREEN}✓ Imports fixed${NC}"
    fi
    
    # Clean dependencies
    echo "Cleaning dependencies..."
    go mod tidy
    echo -e "${GREEN}✓ Dependencies cleaned${NC}"
    
    # Re-test after fixes
    echo -e "\n${BLUE}Re-testing after fixes...${NC}"
    if go build ./...; then
        echo -e "${GREEN}✅ Fixed! Now building binary...${NC}"
        
        if go build -o ollama-control-service ./cmd; then
            echo -e "${GREEN}🎉 SUCCESS! Binary built: ollama-control-service${NC}"
            ls -lah ollama-control-service
        fi
    else
        echo -e "${RED}❌ Still has issues. Running detailed analysis...${NC}"
        
        # Detailed error analysis
        echo -e "\n${YELLOW}📋 Detailed Error Analysis:${NC}"
        
        # Check each package individually
        for pkg in api managers models src/tools src/utils databases; do
            if [[ -d "$pkg" ]]; then
                echo -n "Testing $pkg... "
                if go build ./$pkg > /dev/null 2>&1; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗${NC}"
                    echo "  Errors in $pkg:"
                    go build ./$pkg 2>&1 | head -3 | sed 's/^/    /'
                fi
            fi
        done
        
        # Check main package specifically
        echo -n "Testing cmd/main.go... "
        if go build ./cmd > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            echo "  Main package errors:"
            go build ./cmd 2>&1 | head -5 | sed 's/^/    /'
        fi
    fi
fi

# Advanced debugging options
echo -e "\n${BLUE}🔧 Advanced Debug Options:${NC}"
echo "1. Run comprehensive analysis"
echo "2. Check specific package"
echo "3. Fix content interactively" 
echo "4. Check project structure"
echo "5. Show detailed errors"
echo "0. Exit"

read -p "Choose option (0-5): " choice

case $choice in
    1)
        echo -e "${YELLOW}Running comprehensive analysis...${NC}"
        ./scripts/helpers/go-project/go-comprehensive-check.sh
        ;;
    2)
        echo "Available packages:"
        echo "  api, managers, models, src/tools, src/utils, databases, cmd"
        read -p "Enter package name: " pkg_name
        
        if [[ -d "$pkg_name" ]]; then
            echo "Analyzing $pkg_name..."
            go build -v ./$pkg_name 2>&1
        else
            echo -e "${RED}Package not found: $pkg_name${NC}"
        fi
        ;;
    3)
        ./scripts/helpers/go-project/go-fix-content.sh
        ;;
    4)
        ./scripts/helpers/go-project/go-scaffold-check.sh
        ;;
    5)
        echo -e "${YELLOW}Detailed error output:${NC}"
        go build ./... 2>&1
        
        echo -e "\n${YELLOW}Go vet output:${NC}"
        go vet ./... 2>&1 || true
        
        echo -e "\n${YELLOW}Module verification:${NC}"
        go mod verify || true
        ;;
    0)
        echo "Done!"
        ;;
esac

# Quick fix suggestions based on your structure
echo -e "\n${BLUE}💡 Quick Fix Suggestions for OCS:${NC}"
echo "• If you get import cycle errors: Check managers/ cross-references"
echo "• If websocket issues: Verify websocket-manager.go imports"
echo "• If config issues: Check configs/ YAML loading in config-manager.go"
echo "• If gRPC issues: Ensure grpc-api.go has proper protobuf imports"
echo "• If database issues: Check storage-database.go connections"

echo -e "\n${YELLOW}🚀 To build successfully:${NC}"
echo "1. Fix any import issues shown above"
echo "2. Ensure all manager dependencies are correct" 
echo "3. Verify config loading works (configs/*.yaml)"
echo "4. Check that main.go properly initializes all managers"
echo "5. Run: go build -o ollama-control-service ./cmd"