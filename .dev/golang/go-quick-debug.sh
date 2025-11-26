#!/bin/bash

# scripts/go-quick-debug.sh - Fast debugging techniques for Go projects
# One-liner commands to quickly identify and fix common issues

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Quick Go Debug Commands ===${NC}"

# Fast debugging techniques
echo -e "${YELLOW}🚀 FAST DEBUGGING TECHNIQUES:${NC}\n"

echo -e "${BLUE}1. INSTANT BUILD CHECK:${NC}"
echo "go build -v ./... 2>&1 | head -20"
echo

echo -e "${BLUE}2. FIND ALL COMPILATION ERRORS:${NC}"
echo "go list ./... 2>&1 | grep -v '^[a-zA-Z]' | head -30"
echo

echo -e "${BLUE}3. CHECK SPECIFIC PACKAGE:${NC}"
echo "go build -v ./cmd/your-app-name 2>&1"
echo

echo -e "${BLUE}4. RACE CONDITION CHECK:${NC}"
echo "go build -race ./... 2>&1 | grep -E 'race|DATA RACE'"
echo

echo -e "${BLUE}5. MISSING IMPORTS FIX:${NC}"
echo "find . -name '*.go' | xargs goimports -w"
echo

echo -e "${BLUE}6. UNUSED VARIABLES FINDER:${NC}"
echo "go vet ./... 2>&1 | grep 'declared and not used'"
echo

echo -e "${BLUE}7. IMPORT CYCLE DETECTION:${NC}"
echo "go list ./... 2>&1 | grep -A5 -B5 'import cycle'"
echo

echo -e "${BLUE}8. DEPENDENCY ISSUES:${NC}"
echo "go mod why -m all | grep -E 'ERROR|MISSING'"
echo

echo -e "${BLUE}9. QUICK SYNTAX CHECK:${NC}"
echo "go fmt ./... && echo 'Syntax OK' || echo 'Syntax Errors'"
echo

echo -e "${BLUE}10. FIND PANIC STATEMENTS:${NC}"
echo "grep -r 'panic(' --include='*.go' . | head -20"
echo

# Interactive mode
echo -e "\n${YELLOW}🔍 INTERACTIVE DEBUG MODE${NC}"
echo "Choose a quick debug option:"
echo "1. Run instant build check"
echo "2. Find all undefined references"
echo "3. Fix imports automatically"
echo "4. Check for unused variables"
echo "5. Detect import cycles"
echo "6. Check specific file"
echo "7. Build specific binary (ollama-control-service)"
echo "8. Full diagnostic (all checks)"
echo "0. Exit"

read -p "Choice (0-8): " choice

case $choice in
    1)
        echo -e "${YELLOW}Running instant build check...${NC}"
        go build -v ./... 2>&1 | head -20
        ;;
    2)
        echo -e "${YELLOW}Finding undefined references...${NC}"
        go build ./... 2>&1 | grep -E "undefined:|not defined" | head -10
        ;;
    3)
        echo -e "${YELLOW}Auto-fixing imports...${NC}"
        if command -v goimports &> /dev/null; then
            find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
            echo -e "${GREEN}Imports fixed${NC}"
        else
            echo "Installing goimports..."
            go install golang.org/x/tools/cmd/goimports@latest
            find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
            echo -e "${GREEN}Imports fixed${NC}"
        fi
        
        echo "Testing build after import fix..."
        if go build ./...; then
            echo -e "${GREEN}✅ Build successful!${NC}"
        else
            echo -e "${RED}❌ Still has issues${NC}"
        fi
        ;;
    4)
        echo -e "${YELLOW}Checking for unused variables...${NC}"
        go vet ./... 2>&1 | grep -E "declared and not used|assigned and not used" | head -40
        ;;
    5)
        echo -e "${YELLOW}Detecting import cycles...${NC}"
        go list ./... 2>&1 | grep -A3 -B3 "import cycle"
        ;;
    6)
        read -p "Enter file path: " file_path
        if [[ -f "$file_path" ]]; then
            echo -e "${YELLOW}Checking $file_path...${NC}"
            go build "$file_path" 2>&1
        else
            echo -e "${RED}File not found: $file_path${NC}"
        fi
        ;;
    7)
        echo -e "${YELLOW}Building ollama-control-service...${NC}"
        
        # Try to find the main package
        if [[ -d "cmd/ollama-control-service" ]]; then
            main_path="./cmd/ollama-control-service"
        elif [[ -f "main.go" ]]; then
            main_path="."
        else
            read -p "Enter path to main package: " main_path
        fi
        
        echo "Building from: $main_path"
        if go build -o ollama-control-service "$main_path"; then
            echo -e "${GREEN}✅ Successfully built ollama-control-service${NC}"
            ls -la ollama-control-service
            echo -e "${BLUE}Run with: ./ollama-control-service${NC}"
        else
            echo -e "${RED}❌ Build failed. Errors above.${NC}"
            
            echo -e "\n${YELLOW}Quick fixes to try:${NC}"
            echo "1. go mod tidy"
            echo "2. goimports -w ."
            echo "3. Check main.go exists in correct location"
            echo "4. Verify all imports are correct"
        fi
        ;;
    8)
        echo -e "${YELLOW}Running full diagnostic...${NC}"
        
        echo -e "\n${BLUE}📋 BUILD STATUS:${NC}"
        if go build ./...; then
            echo -e "${GREEN}✅ Build: SUCCESS${NC}"
        else
            echo -e "${RED}❌ Build: FAILED${NC}"
        fi
        
        echo -e "\n${BLUE}📋 MODULE STATUS:${NC}"
        go mod verify
        
        echo -e "\n${BLUE}📋 DEPENDENCIES:${NC}"
        go list -m all | head -20
        
        echo -e "\n${BLUE}📋 VET ANALYSIS:${NC}"
        go vet ./... 2>&1 | head -20
        
        echo -e "\n${BLUE}📋 TEST COMPILATION:${NC}"
        if go test -c ./... > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Tests: OK${NC}"
        else
            echo -e "${RED}❌ Tests: COMPILATION ERRORS${NC}"
        fi
        
        echo -e "\n${BLUE}📋 QUICK STATS:${NC}"
        echo "Go files: $(find . -name "*.go" | wc -l)"
        echo "Packages: $(go list ./... | wc -l)"
        echo "Main packages: $(find . -name "*.go" -exec grep -l "package main" {} \; | wc -l)"
        ;;
    0)
        echo "Goodbye!"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac

echo -e "\n${BLUE}💡 DEBUGGING TIPS:${NC}"
echo "• Use 'go build -v' for verbose output"
echo "• Use 'go list -f '{{.ImportPath}} {{.Deps}}' ./...' to see dependencies"
echo "• Use 'go mod graph' to visualize dependency graph"
echo "• Use 'dlv debug' for step-by-step debugging"
echo "• Check GOPATH and GOROOT with 'go env'"

echo -e "\n${YELLOW}🔧 COMMON FIXES:${NC}"
echo "1. go mod tidy          # Clean dependencies"
echo "2. goimports -w .       # Fix imports"
echo "3. go fmt ./...         # Fix formatting"
echo "4. go clean -cache      # Clear build cache"
echo "5. rm go.sum && go mod download  # Refresh checksums"

echo -e "\n${BLUE}📊 PROJECT HEALTH CHECK:${NC}"
if go build ./... > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Project Status: HEALTHY${NC}"
    
    # Try to build your specific binary
    echo -e "\n${YELLOW}Attempting to build ollama-control-service...${NC}"
    
    # Smart detection of main package location
    main_locations=("./cmd/ollama-control-service" "./cmd/ocs" "." "./main.go")
    
    for location in "${main_locations[@]}"; do
        if [[ -f "$location/main.go" ]] || [[ "$location" == "./main.go" && -f "main.go" ]]; then
            echo "Found main package at: $location"
            if go build -o ollama-control-service "$location" 2>/dev/null; then
                echo -e "${GREEN}🎉 SUCCESS: ollama-control-service built!${NC}"
                echo "Binary location: ./ollama-control-service"
                echo "Run with: ./ollama-control-service"
                break
            else
                echo -e "${RED}Build failed from $location${NC}"
                go build -o ollama-control-service "$location" 2>&1 | head -3
            fi
        fi
    done
else
    echo -e "${RED}❌ Project Status: NEEDS ATTENTION${NC}"
    echo -e "${YELLOW}Run the debug toolkit: ./scripts/go-debug-toolkit.sh${NC}"
fi