#!/bin/bash

# scripts/go-build-errors.sh - Detailed build error analysis and fixes
# Focuses specifically on compilation and build issues

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERROR_LOG="build-errors-$(date +%Y%m%d-%H%M%S).log"

echo -e "${BLUE}=== Go Build Error Analysis ===${NC}"

# Function to categorize and explain errors
analyze_error() {
    local error_line="$1"
    
    case "$error_line" in
        *"undefined:"*)
            echo -e "${RED}UNDEFINED REFERENCE:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Check imports, function names, or add missing dependencies${NC}"
            ;;
        *"imported and not used"*)
            echo -e "${YELLOW}UNUSED IMPORT:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Remove unused import or use goimports -w${NC}"
            ;;
        *"declared and not used"*)
            echo -e "${YELLOW}UNUSED VARIABLE:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Use the variable or replace with underscore${NC}"
            ;;
        *"cannot find package"*)
            echo -e "${RED}MISSING PACKAGE:${NC} $error_line"
            echo -e "${YELLOW}  Fix: go get <package> or check import path${NC}"
            ;;
        *"syntax error"*)
            echo -e "${RED}SYNTAX ERROR:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Check brackets, semicolons, and syntax${NC}"
            ;;
        *"import cycle"*)
            echo -e "${RED}IMPORT CYCLE:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Refactor to break circular dependencies${NC}"
            ;;
        *"multiple-value"*)
            echo -e "${YELLOW}MULTIPLE VALUES:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Handle all return values or use blank identifier${NC}"
            ;;
        *"type mismatch"*|*"cannot convert"*)
            echo -e "${RED}TYPE MISMATCH:${NC} $error_line"
            echo -e "${YELLOW}  Fix: Check types and add proper conversions${NC}"
            ;;
        *)
            echo -e "${BLUE}OTHER:${NC} $error_line"
            ;;
    esac
}

# Attempt to build and capture detailed errors
echo -e "${YELLOW}Running build analysis...${NC}"

# Try building each package individually to isolate issues
packages=($(go list ./... 2>/dev/null || echo "."))

echo -e "${BLUE}Found ${#packages[@]} packages to analyze${NC}"

for package in "${packages[@]}"; do
    echo -e "\n${YELLOW}Analyzing package: $package${NC}"
    
    build_output=$(go build "$package" 2>&1 || true)
    
    if [[ -n "$build_output" ]]; then
        echo -e "${RED}Errors in $package:${NC}" | tee -a "$ERROR_LOG"
        echo "$build_output" | tee -a "$ERROR_LOG"
        
        # Analyze each error line
        echo "$build_output" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                analyze_error "$line"
            fi
        done
        
        echo "----------------------------------------" | tee -a "$ERROR_LOG"
    else
        echo -e "${GREEN}✓ Package builds successfully${NC}"
    fi
done

# Try full project build
echo -e "\n${YELLOW}Attempting full project build...${NC}"
full_build_output=$(go build ./... 2>&1 || true)

if [[ -n "$full_build_output" ]]; then
    echo -e "${RED}Full build errors:${NC}" | tee -a "$ERROR_LOG"
    echo "$full_build_output" | tee -a "$ERROR_LOG"
else
    echo -e "${GREEN}✓ Full project builds successfully!${NC}"
    exit 0
fi

# Provide specific fix suggestions
echo -e "\n${BLUE}=== Automated Fix Suggestions ===${NC}"

# Check for common fixable issues
if echo "$full_build_output" | grep -q "imported and not used"; then
    echo -e "${YELLOW}Found unused imports. Run: goimports -w .${NC}"
fi

if echo "$full_build_output" | grep -q "declared and not used"; then
    echo -e "${YELLOW}Found unused variables. Consider using _ or removing them${NC}"
fi

if echo "$full_build_output" | grep -q "undefined:"; then
    echo -e "${YELLOW}Found undefined references. Check:${NC}"
    echo "  - Import statements"
    echo "  - Function/variable names"
    echo "  - Package dependencies"
fi

if echo "$full_build_output" | grep -q "cannot find package"; then
    echo -e "${YELLOW}Missing packages detected. Run: go mod tidy${NC}"
fi

# Interactive fixes
echo -e "\n${BLUE}=== Interactive Fixes ===${NC}"
echo "1. Auto-fix imports (goimports)"
echo "2. Auto-fix formatting (go fmt)"
echo "3. Clean dependencies (go mod tidy)"
echo "4. Show detailed error for specific file"
echo "5. Attempt to build specific binary"
echo "0. Exit"

read -p "Choose fix option (0-5): " choice

case $choice in
    1)
        echo "Running goimports..."
        if command -v goimports &> /dev/null; then
            goimports -w .
            echo -e "${GREEN}Imports fixed${NC}"
        else
            echo "Installing goimports..."
            go install golang.org/x/tools/cmd/goimports@latest
            goimports -w .
            echo -e "${GREEN}Imports fixed${NC}"
        fi
        
        echo "Re-testing build..."
        if go build ./...; then
            echo -e "${GREEN}Build successful after import fixes!${NC}"
        fi
        ;;
    2)
        echo "Running go fmt..."
        go fmt ./...
        echo -e "${GREEN}Formatting applied${NC}"
        ;;
    3)
        echo "Cleaning dependencies..."
        go mod tidy
        go mod download
        echo -e "${GREEN}Dependencies cleaned${NC}"
        
        echo "Re-testing build..."
        if go build ./...; then
            echo -e "${GREEN}Build successful after dependency cleanup!${NC}"
        fi
        ;;
    4)
        read -p "Enter file path to analyze: " file_path
        if [[ -f "$file_path" ]]; then
            echo "Build errors for $file_path:"
            go build "$file_path" 2>&1 || true
        else
            echo -e "${RED}File not found: $file_path${NC}"
        fi
        ;;
    5)
        read -p "Enter main package path (e.g., ./cmd/myapp): " main_path
        read -p "Enter output binary name: " binary_name
        
        if [[ -d "$main_path" ]]; then
            echo "Attempting to build $binary_name from $main_path..."
            if go build -o "$binary_name" "$main_path"; then
                echo -e "${GREEN}Successfully built $binary_name${NC}"
                ls -la "$binary_name"
            else
                echo -e "${RED}Build failed. Check errors above.${NC}"
            fi
        else
            echo -e "${RED}Directory not found: $main_path${NC}"
        fi
        ;;
    0)
        echo "Exiting..."
        ;;
esac

echo -e "\n${YELLOW}Error analysis complete. Log saved to: $ERROR_LOG${NC}"

# Final summary
if go build ./... > /dev/null 2>&1; then
    echo -e "${GREEN}🎉 PROJECT BUILDS SUCCESSFULLY!${NC}"
else
    echo -e "${RED}❌ Project still has build issues${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review the error log: $ERROR_LOG"
    echo "  2. Fix issues manually based on suggestions above"
    echo "  3. Use fix-content.sh for string replacements"
    echo "  4. Consider running go-auto-fix.sh for automatic fixes"
fi