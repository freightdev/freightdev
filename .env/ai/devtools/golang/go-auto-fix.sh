#!/bin/bash

# scripts/go-auto-fix.sh - Automatically fix common Go issues
# This script attempts to fix issues that can be resolved programmatically

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FIXES_LOG="auto-fixes-$(date +%Y%m%d-%H%M%S).log"

log_fix() {
    echo -e "$1" | tee -a "$FIXES_LOG"
}

echo -e "${BLUE}=== Auto-Fix Go Project Issues ===${NC}"

# 1. Fix imports
echo -e "${YELLOW}1. Fixing imports...${NC}"
if command -v goimports &> /dev/null; then
    find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
        if goimports -w "$file"; then
            log_fix "${GREEN}Fixed imports in $file${NC}"
        fi
    done
else
    echo "Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
    export PATH="$PATH:$(go env GOPATH)/bin"
    
    find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
        if goimports -w "$file"; then
            log_fix "${GREEN}Fixed imports in $file${NC}"
        fi
    done
fi

# 2. Fix formatting
echo -e "${YELLOW}2. Fixing code formatting...${NC}"
if go fmt ./...; then
    log_fix "${GREEN}Code formatting applied${NC}"
fi

# 3. Update dependencies
echo -e "${YELLOW}3. Updating and cleaning dependencies...${NC}"
go mod tidy
go mod download
log_fix "${GREEN}Dependencies updated and cleaned${NC}"

# 4. Fix package declarations
echo -e "${YELLOW}4. Checking package declarations...${NC}"
find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
    dir_name=$(basename "$(dirname "$file")")
    
    # Skip main packages and root directory
    if [[ "$dir_name" == "." ]] || [[ "$dir_name" == "main" ]]; then
        continue
    fi
    
    # Check if package name matches directory
    current_package=$(head -n 10 "$file" | grep -E "^package " | awk '{print $2}' | head -n 1)
    
    if [[ -n "$current_package" && "$current_package" != "$dir_name" && "$current_package" != "main" ]]; then
        read -p "Fix package name '$current_package' to '$dir_name' in $file? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i.bak "s/^package $current_package/package $dir_name/" "$file"
            rm -f "$file.bak"
            log_fix "${GREEN}Fixed package declaration in $file${NC}"
        fi
    fi
done

# 5. Remove unused variables and imports (basic)
echo -e "${YELLOW}5. Attempting to fix unused variables...${NC}"
find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
    # Replace unused variable assignments with blank identifier
    if sed -i.bak -E 's/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*:=/\t_ =/g' "$file"; then
        # Only keep the change if it actually changed something and doesn't break syntax
        if ! cmp -s "$file" "$file.bak"; then
            if go build "$file" > /dev/null 2>&1; then
                log_fix "${GREEN}Fixed unused variables in $file${NC}"
                rm -f "$file.bak"
            else
                mv "$file.bak" "$file"  # Restore if it broke the syntax
            fi
        else
            rm -f "$file.bak"
        fi
    fi
done

# 6. Fix common error handling patterns
echo -e "${YELLOW}6. Adding basic error handling...${NC}"
find . -name "*.go" -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
    # Look for patterns like "_, err := someFunc()" without error checking
    if grep -q "_, err :=" "$file" && ! grep -q "if err != nil" "$file"; then
        read -p "Add basic error handling to $file? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # This is a simple example - in practice, you'd want more sophisticated error handling
            awk '
            /_, err := / { 
                print $0
                print "\tif err != nil {"
                print "\t\treturn err"
                print "\t}"
                next
            }
            { print }
            ' "$file" > "$file.tmp"
            
            if go build "$file.tmp" > /dev/null 2>&1; then
                mv "$file.tmp" "$file"
                log_fix "${GREEN}Added basic error handling to $file${NC}"
            else
                rm -f "$file.tmp"
                log_fix "${YELLOW}Could not auto-add error handling to $file - manual fix needed${NC}"
            fi
        fi
    fi
done

# 7. Fix go.mod issues
echo -e "${YELLOW}7. Fixing go.mod issues...${NC}"
if [[ -f "go.mod" ]]; then
    # Remove unused dependencies
    go mod tidy
    
    # Update to compatible versions if there are conflicts
    if ! go build ./... > /dev/null 2>&1; then
        echo "Attempting to resolve version conflicts..."
        go get -u ./...
        go mod tidy
        log_fix "${GREEN}Updated module versions${NC}"
    fi
fi

# 8. Run final verification
echo -e "${YELLOW}8. Running final verification...${NC}"
if go build -o /dev/null ./... 2>/dev/null; then
    log_fix "${GREEN}SUCCESS: Project builds successfully after auto-fixes!${NC}"
    
    # Run tests if they exist
    if go test -c ./... > /dev/null 2>&1; then
        log_fix "${GREEN}SUCCESS: Tests compile successfully!${NC}"
    fi
else
    log_fix "${RED}PARTIAL SUCCESS: Some issues remain. Check build output:${NC}"
    go build ./... 2>&1 | head -10 | tee -a "$FIXES_LOG"
fi

# Summary
echo -e "${BLUE}=== Auto-Fix Complete ===${NC}"
echo -e "${YELLOW}Fix log: $FIXES_LOG${NC}"
echo -e "${YELLOW}Next steps if issues remain:${NC}"
echo "  1. Review build errors manually"
echo "  2. Run go-comprehensive-check.sh for detailed analysis"
echo "  3. Use fix-content.sh for specific string replacements"
echo ""
echo -e "${BLUE}Quick verification:${NC}"
echo "  go build -o your-binary-name ./cmd/your-main-package/"