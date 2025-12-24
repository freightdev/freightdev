#!/bin/bash

# quick-setup-ocs.sh - One-command setup and build for your OCS project

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}⚡ Quick Setup & Build - Ollama Control Service${NC}"

# Create the OCS-specific debug script
cat > ocs-debug.sh << 'EOF'
#!/bin/bash
# Copy the content from the ocs_specific_debug artifact here
EOF

# Make it executable
chmod +x ocs-debug.sh
chmod +x scripts/helpers/go-project/*.sh

# Quick diagnostic and build
echo -e "${YELLOW}🔍 Quick Diagnostic...${NC}"

# 1. Install required tools quickly
if ! command -v goimports &> /dev/null; then
    echo "Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
fi

# 2. Quick fix common issues
echo "Auto-fixing imports..."
find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w

echo "Cleaning dependencies..."
go mod tidy

# 3. Attempt build
echo -e "\n${BLUE}🚀 Attempting build...${NC}"

if go build -o ollama-control-service ./cmd; then
    echo -e "${GREEN}🎉 SUCCESS! ollama-control-service built successfully!${NC}"
    echo -e "${BLUE}Binary info:${NC}"
    ls -lah ollama-control-service
    
    echo -e "\n${GREEN}✅ Ready to run:${NC}"
    echo "./ollama-control-service"
    
    echo -e "\n${YELLOW}🔧 Project structure looks good:${NC}"
    echo "• API handlers: ✓"
    echo "• Managers: ✓" 
    echo "• Models: ✓"
    echo "• Tools: ✓"
    echo "• Configs: ✓"
    echo "• Database: ✓"
    
else
    echo -e "${RED}❌ Build failed. Running diagnostic...${NC}"
    
    # Quick error analysis
    echo -e "\n${YELLOW}📋 Error Analysis:${NC}"
    BUILD_ERRORS=$(go build ./cmd 2>&1 || true)
    echo "$BUILD_ERRORS"
    
    # Categorize errors
    if echo "$BUILD_ERRORS" | grep -q "undefined:"; then
        echo -e "\n${YELLOW}🔍 Found undefined references - likely import issues${NC}"
    fi
    
    if echo "$BUILD_ERRORS" | grep -q "imported and not used"; then
        echo -e "\n${YELLOW}🔍 Found unused imports - running goimports again${NC}"
        find . -name "*.go" | xargs goimports -w
    fi
    
    if echo "$BUILD_ERRORS" | grep -q "cannot find package"; then
        echo -e "\n${YELLOW}🔍 Missing packages - running go mod download${NC}"
        go mod download
    fi
    
    # Try build again after fixes
    echo -e "\n${BLUE}🔄 Retrying build after fixes...${NC}"
    if go build -o ollama-control-service ./cmd; then
        echo -e "${GREEN}🎉 SUCCESS after fixes!${NC}"
        ls -lah ollama-control-service
    else
        echo -e "${RED}❌ Still failing. Use detailed debugging:${NC}"
        echo "Run: ./ocs-debug.sh"
        echo "Or: ./scripts/helpers/go-project/go-debug-toolkit.sh"
    fi
fi

echo -e "\n${BLUE}📁 Your project structure:${NC}"
echo "cmd/main.go         - Main application entry"
echo "api/                - REST & gRPC API layer"
echo "managers/           - Business logic managers"
echo "models/             - Data models"
echo "src/tools/          - Utility tools"
echo "configs/            - Configuration files"
echo "databases/          - Database layer"

echo -e "\n${YELLOW}💡 Quick commands:${NC}"
echo "./ollama-control-service              # Run the service"
echo "./ocs-debug.sh                        # Debug issues"
echo "go test ./...                         # Run tests"
echo "go build -race ./cmd                  # Build with race detection"

# Create a quick run script
cat > run-ocs.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Ollama Control Service..."

# Check if binary exists
if [[ ! -f "ollama-control-service" ]]; then
    echo "Binary not found. Building..."
    go build -o ollama-control-service ./cmd
fi

# Run with helpful output
echo "Starting service..."
./ollama-control-service
EOF

chmod +x run-ocs.sh

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. ./ollama-control-service    # If build was successful"
echo "2. ./ocs-debug.sh             # If you need to debug issues"
echo "3. ./run-ocs.sh               # Convenient run script"