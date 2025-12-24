#!/bin/bash

# scripts/go-comprehensive-check.sh - Deep analysis of Go project issues
# Identifies all types of problems that could prevent building/testing

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES_FILE="debug-issues-$(date +%Y%m%d-%H%M%S).log"

log_issue() {
    echo -e "$1" | tee -a "$ISSUES_FILE"
}

echo -e "${BLUE}=== Comprehensive Go Project Analysis ===${NC}"

# 1. Module and dependency issues
echo -e "${YELLOW}1. Analyzing module structure...${NC}"
if ! go list -m all > /dev/null 2>&1; then
    log_issue "${RED}CRITICAL: Module dependency issues detected${NC}"
    go list -m all 2>&1 | tee -a "$ISSUES_FILE"
fi

# 2. Import cycle detection
echo -e "${YELLOW}2. Checking for import cycles...${NC}"
if go list ./... > /dev/null 2>&1; then
    echo -e "${GREEN}No import cycles found${NC}"
else
    log_issue "${RED}CRITICAL: Import cycles detected${NC}"
    go list ./... 2>&1 | grep -E "(import cycle|cycle)" | tee -a "$ISSUES_FILE"
fi

# 3. Syntax and compilation errors
echo -e "${YELLOW}3. Analyzing syntax and compilation errors...${NC}"
BUILD_OUTPUT=$(go build ./... 2>&1 || true)
if [[ -n "$BUILD_OUTPUT" ]]; then
    log_issue "${RED}BUILD ERRORS:${NC}"
    echo "$BUILD_OUTPUT" | tee -a "$ISSUES_FILE"
    
    # Parse specific error types
    echo "$BUILD_OUTPUT" | grep -E "undefined:|not used|imported and not used" | while read -r line; do
        log_issue "${YELLOW}FIXABLE: $line${NC}"
    done
fi

# 4. Missing dependencies
echo -e "${YELLOW}4. Checking for missing dependencies...${NC}"
go mod tidy -v 2>&1 | tee -a "$ISSUES_FILE"

# 5. Unused imports and variables
echo -e "${YELLOW}5. Finding unused imports and variables...${NC}"
if command -v golangci-lint &> /dev/null; then
    golangci-lint run --enable=unused,deadcode,varcheck --out-format=tab 2>&1 | tee -a "$ISSUES_FILE"
else
    log_issue "${YELLOW}WARNING: golangci-lint not installed. Install with: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$(go env GOPATH)/bin${NC}"
fi

# 6. Vet analysis
echo -e "${YELLOW}6. Running go vet analysis...${NC}"
go vet ./... 2>&1 | tee -a "$ISSUES_FILE" || true

# 7. Race condition detection
echo -e "${YELLOW}7. Checking for potential race conditions...${NC}"
go build -race ./... 2>&1 | tee -a "$ISSUES_FILE" || true

# 8. Check for common problematic patterns
echo -e "${YELLOW}8. Scanning for problematic code patterns...${NC}"

# Find files with potential issues
find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
    # Check for common AI-generated code issues
    if grep -q "TODO:" "$file"; then
        log_issue "${YELLOW}TODO found in $file${NC}"
    fi
    
    if grep -q "panic(" "$file"; then
        log_issue "${YELLOW}Panic found in $file - line $(grep -n 'panic(' "$file" | cut -d: -f1)${NC}"
    fi
    
    # Check for missing error handling
    if grep -q "_, err :=" "$file" && ! grep -q "if err != nil" "$file"; then
        log_issue "${YELLOW}Potential unhandled error in $file${NC}"
    fi
    
    # Check for incorrect package declarations
    head -n 10 "$file" | grep -E "^package " | while read -r pkg_line; do
        expected_pkg=$(basename "$(dirname "$file")")
        if [[ "$expected_pkg" != "." ]] && ! echo "$pkg_line" | grep -q "$expected_pkg"; then
            log_issue "${YELLOW}Package name mismatch in $file: $pkg_line${NC}"
        fi
    done
done

# 9. Test compilation
echo -e "${YELLOW}9. Testing test compilation...${NC}"
if ! go test -c ./... > /dev/null 2>&1; then
    log_issue "${RED}TEST COMPILATION ERRORS:${NC}"
    go test -c ./... 2>&1 | tee -a "$ISSUES_FILE"
fi

# 10. Generate summary
echo -e "${BLUE}=== Analysis Complete ===${NC}"
echo -e "${YELLOW}Issues logged to: $ISSUES_FILE${NC}"

# Count different types of issues
critical_count=$(grep -c "CRITICAL:" "$ISSUES_FILE" 2>/dev/null || echo "0")
fixable_count=$(grep -c "FIXABLE:" "$ISSUES_FILE" 2>/dev/null || echo "0")
warning_count=$(grep -c "WARNING:" "$ISSUES_FILE" 2>/dev/null || echo "0")

echo -e "${RED}Critical Issues: $critical_count${NC}"
echo -e "${YELLOW}Fixable Issues: $fixable_count${NC}"
echo -e "${BLUE}Warnings: $warning_count${NC}"

if [[ $critical_count -eq 0 && $fixable_count -eq 0 ]]; then
    echo -e "${GREEN}Project appears to be in good shape!${NC}"
else
    echo -e "${YELLOW}Run go-auto-fix.sh to attempt automatic fixes${NC}"
fi