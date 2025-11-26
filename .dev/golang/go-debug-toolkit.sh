#!/bin/bash

# scripts/go-debug-toolkit.sh - Master debugging script for Go projects
# Usage: ./scripts/go-debug-toolkit.sh [project-path]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_PATH="${1:-.}"
SCRIPTS_DIR="$(dirname "$0")"

# Ensure we're in a Go project
check_go_project() {
    if [[ ! -f "$PROJECT_PATH/go.mod" ]]; then
        echo -e "${RED}Error: Not a Go module. Run 'go mod init <module-name>' first${NC}"
        exit 1
    fi
    cd "$PROJECT_PATH"
}

# Main menu
show_menu() {
    echo -e "${BLUE}=== Go Project Debug Toolkit ===${NC}"
    echo "1. Quick Health Check"
    echo "2. Deep Analysis & Fix"
    echo "3. Import Issues Fix"
    echo "4. Syntax & Build Errors"
    echo "5. Dependency Management"
    echo "6. Code Quality Check"
    echo "7. Generate Debug Report"
    echo "8. Interactive Content Replace"
    echo "9. Project Scaffold Check"
    echo "0. Exit"
}

# Quick health check
quick_health_check() {
    echo -e "${YELLOW}Running Quick Health Check...${NC}"
    
    echo "✓ Checking Go installation..."
    go version
    
    echo "✓ Checking module validity..."
    go mod verify || echo -e "${RED}Module verification failed${NC}"
    
    echo "✓ Checking for syntax errors..."
    if ! go build -o /dev/null ./... 2>/dev/null; then
        echo -e "${RED}Build errors found. Run option 4 for detailed analysis.${NC}"
    else
        echo -e "${GREEN}No build errors found${NC}"
    fi
    
    echo "✓ Checking imports..."
    if command -v goimports &> /dev/null; then
        goimports -l . | head -10
    else
        echo "goimports not installed. Run: go install golang.org/x/tools/cmd/goimports@latest"
    fi
}

# Deep analysis with automatic fixes
deep_analysis_fix() {
    echo -e "${YELLOW}Running Deep Analysis & Auto-Fix...${NC}"
    
    # Create backup
    backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    echo "Creating backup in $backup_dir..."
    cp -r . "../$backup_dir"
    
    # Run comprehensive checks
    "$SCRIPTS_DIR/go-comprehensive-check.sh"
    
    # Auto-fix common issues
    "$SCRIPTS_DIR/go-auto-fix.sh"
    
    # Re-run build test
    echo "Re-testing build..."
    if go build -o /dev/null ./...; then
        echo -e "${GREEN}Build successful after fixes!${NC}"
    else
        echo -e "${RED}Still has build issues. Check detailed errors below:${NC}"
        go build ./... 2>&1 | head -20
    fi
}

# Main execution
main() {
    check_go_project
    
    if [[ $# -eq 0 ]]; then
        while true; do
            show_menu
            read -p "Choose option (0-9): " choice
            
            case $choice in
                1) quick_health_check ;;
                2) deep_analysis_fix ;;
                3) "$SCRIPTS_DIR/go-import-fix.sh" ;;
                4) "$SCRIPTS_DIR/go-build-errors.sh" ;;
                5) "$SCRIPTS_DIR/go-deps-manager.sh" ;;
                6) "$SCRIPTS_DIR/go-quality-check.sh" ;;
                7) "$SCRIPTS_DIR/go-debug-report.sh" ;;
                8) "$SCRIPTS_DIR/go-fix-content.sh" ;;
                9) "$SCRIPTS_DIR/go-scaffold-check.sh" ;;
                0) echo "Goodbye!"; exit 0 ;;
                *) echo -e "${RED}Invalid option${NC}" ;;
            esac
            
            echo
            read -p "Press Enter to continue..."
            clear
        done
    else
        # Run specific function based on argument
        case "${2:-}" in
            "health") quick_health_check ;;
            "deep") deep_analysis_fix ;;
            *) quick_health_check ;;
        esac
    fi
}

main "$@"