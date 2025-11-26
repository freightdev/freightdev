#!/usr/bin/env zsh

# devtools/helpers/project/go-tools.zsh - Go-specific development tools

# Colors
autoload -U colors && colors

# Find Go function and provide context
find_go_function() {
    local func_name="$1"
    local found=false
    
    print "${BLUE}🔍 Searching for Go function: $func_name${RESET}"
    
    # Search for function definition
    local definitions=$(rg -n "func.*$func_name" --type go . 2>/dev/null || grep -rn "func.*$func_name" --include="*.go" .)
    
    if [[ -n "$definitions" ]]; then
        print "${GREEN}✅ Function definitions found:${RESET}"
        echo "$definitions" | while read line; do
            print "  ${CYAN}$line${RESET}"
        done
        found=true
    fi
    
    # Search for method definitions
    local methods=$(rg -n "func \([^)]+\) $func_name" --type go . 2>/dev/null || grep -rn "func ([^)]*) $func_name" --include="*.go" .)
    
    if [[ -n "$methods" ]]; then
        print "${GREEN}✅ Method definitions found:${RESET}"
        echo "$methods" | while read line; do
            print "  ${CYAN}$line${RESET}"
        done
        found=true
    fi
    
    # Search for function calls
    local calls=$(rg -n "$func_name\(" --type go . 2>/dev/null | head -10 || grep -rn "$func_name(" --include="*.go" . | head -10)
    
    if [[ -n "$calls" ]]; then
        print "${YELLOW}📞 Function calls found:${RESET}"
        echo "$calls" | while read line; do
            print "  ${YELLOW}$line${RESET}"
        done
        found=true
    fi
    
    # Search for interface definitions
    local interfaces=$(rg -n "type.*interface.*$func_name" --type go . 2>/dev/null || grep -rn "type.*interface.*$func_name" --include="*.go" .)
    
    if [[ -n "$interfaces" ]]; then
        print "${MAGENTA}🔌 Interface definitions found:${RESET}"
        echo "$interfaces" | while read line; do
            print "  ${MAGENTA}$line${RESET}"
        done
        found=true
    fi
    
    if ! $found; then
        print "${RED}❌ Function '$func_name' not found${RESET}"
        
        # Offer to create it
        print -n "${YELLOW}Create this function? [y/N]: ${RESET}"
        read create_func
        
        if [[ "$create_func" =~ ^[Yy]$ ]]; then
            create_go_function "$func_name"
        fi
        
        # Suggest similar functions
        print "${BLUE}🤔 Similar functions found:${RESET}"
        rg -i "func.*${func_name:0:3}" --type go . 2>/dev/null | head -5 || grep -ri "func.*${func_name:0:3}" --include="*.go" . | head -5
    fi
}

# Create a Go function stub
create_go_function() {
    local func_name="$1"
    
    print -n "${YELLOW}Which file should contain this function? ${RESET}"
    read target_file
    
    if [[ ! -f "$target_file" ]]; then
        print -n "${YELLOW}File doesn't exist. Create it? [y/N]: ${RESET}"
        read create_file
        
        if [[ "$create_file" =~ ^[Yy]$ ]]; then
            # Determine package name from directory
            local pkg_name=$(basename $(dirname "$target_file"))
            [[ "$pkg_name" == "." ]] && pkg_name=$(basename $(pwd))
            
            cat > "$target_file" << EOF
package $pkg_name

import (
    "fmt"
)
EOF
        else
            return
        fi
    fi
    
    # Determine function signature
    print "${BLUE}Function signature options:${RESET}"
    print "1. func $func_name() error"
    print "2. func $func_name() (string, error)" 
    print "3. func $func_name(ctx context.Context) error"
    print "4. func (r *Receiver) $func_name() error"
    print "5. Custom signature"
    
    print -n "${YELLOW}Choose option (1-5): ${RESET}"
    read sig_choice
    
    local func_signature
    case $sig_choice in
        1) func_signature="func $func_name() error" ;;
        2) func_signature="func $func_name() (string, error)" ;;
        3) func_signature="func $func_name(ctx context.Context) error" ;;
        4) 
            print -n "Enter receiver type: "
            read receiver_type
            func_signature="func (r *$receiver_type) $func_name() error"
            ;;
        5) 
            print -n "Enter custom signature: "
            read custom_sig
            func_signature="$custom_sig"
            ;;
        *) func_signature="func $func_name() error" ;;
    esac
    
    # Add function to file
    cat >> "$target_file" << EOF

// $func_name TODO: implement this function
$func_signature {
    return fmt.Errorf("$func_name not implemented")
}
EOF
    
    print "${GREEN}✅ Function stub created in $target_file${RESET}"
    
    # Try to build to see if it fixes errors
    if go build "$target_file" > /dev/null 2>&1; then
        print "${GREEN}✅ File compiles successfully${RESET}"
    else
        print "${RED}❌ File has compilation errors:${RESET}"
        go build "$target_file" 2>&1 | head -5
    fi
}

# Comprehensive Go error analysis
analyze_go_errors() {
    print "${YELLOW}🔍 Comprehensive Go Error Analysis${RESET}"
    
    local build_output=$(go build ./... 2>&1)
    local error_file="go-errors-$(date +%H%M%S).log"
    
    echo "$build_output" > "$error_file"
    
    if [[ -z "$build_output" ]]; then
        print "${GREEN}✅ No build errors found!${RESET}"
        return
    fi
    
    print "${RED}❌ Build errors detected${RESET}"
    
    # Categorize errors
    local undefined_errors=$(echo "$build_output" | grep "undefined:" || true)
    local unused_imports=$(echo "$build_output" | grep "imported and not used" || true)  
    local unused_vars=$(echo "$build_output" | grep "declared and not used" || true)
    local missing_packages=$(echo "$build_output" | grep "cannot find package" || true)
    local syntax_errors=$(echo "$build_output" | grep "syntax error" || true)
    local type_errors=$(echo "$build_output" | grep "cannot convert\|type.*does not implement" || true)
    
    [[ -n "$undefined_errors" ]] && {
        print "${RED}🔴 Undefined References:${RESET}"
        echo "$undefined_errors" | head -5 | while read line; do
            print "  $line"
        done
    }
    
    [[ -n "$unused_imports" ]] && {
        print "${YELLOW}🟡 Unused Imports:${RESET}"
        echo "$unused_imports" | head -5 | while read line; do
            print "  $line"
        done
        print "${BLUE}💡 Fix: run 'goimports -w .'${RESET}"
    }
    
    [[ -n "$unused_vars" ]] && {
        print "${YELLOW}🟡 Unused Variables:${RESET}"
        echo "$unused_vars" | head -5 | while read line; do
            print "  $line"
        done
        print "${BLUE}💡 Fix: replace with underscore or remove${RESET}"
    }
    
    [[ -n "$missing_packages" ]] && {
        print "${RED}🔴 Missing Packages:${RESET}"
        echo "$missing_packages" | head -5 | while read line; do
            print "  $line"
        done
        print "${BLUE}💡 Fix: run 'go mod tidy'${RESET}"
    }
    
    [[ -n "$syntax_errors" ]] && {
        print "${RED}🔴 Syntax Errors:${RESET}"
        echo "$syntax_errors" | head -5 | while read line; do
            print "  $line"
        done
    }
    
    [[ -n "$type_errors" ]] && {
        print "${RED}🔴 Type Errors:${RESET}"
        echo "$type_errors" | head -5 | while read line; do
            print "  $line"
        done
    }
    
    # Interactive fixes
    print "\n${BLUE}🛠️ Quick Fixes Available:${RESET}"
    print "1. Auto-fix imports (goimports -w .)"
    print "2. Clean dependencies (go mod tidy)" 
    print "3. Find and create undefined functions"
    print "4. Show detailed error for specific file"
    print "0. Back to main menu"
    
    print -n "${GREEN}Choose fix (0-4): ${RESET}"
    read fix_choice
    
    case $fix_choice in
        1)
            print "${YELLOW}Fixing imports...${RESET}"
            if command -v goimports &> /dev/null; then
                find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
                print "${GREEN}✅ Imports fixed${RESET}"
            else
                print "${YELLOW}Installing goimports...${RESET}"
                go install golang.org/x/tools/cmd/goimports@latest
                find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
                print "${GREEN}✅ Imports fixed${RESET}"
            fi
            
            # Re-test build
            if go build ./... > /dev/null 2>&1; then
                print "${GREEN}🎉 Build now successful!${RESET}"
            else
                print "${YELLOW}Some issues remain${RESET}"
            fi
            ;;
        2)
            print "${YELLOW}Cleaning dependencies...${RESET}"
            go mod tidy
            go mod download
            print "${GREEN}✅ Dependencies cleaned${RESET}"
            ;;
        3)
            # Extract undefined function names and offer to create them
            local undefined_funcs=$(echo "$undefined_errors" | sed -n 's/.*undefined: \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' | sort -u)
            
            if [[ -n "$undefined_funcs" ]]; then
                print "${BLUE}Undefined functions found:${RESET}"
                echo "$undefined_funcs" | nl -w2 -s'. '
                
                print -n "Enter number to create (or 0 to skip): "
                read func_num
                
                if [[ "$func_num" -gt 0 ]]; then
                    local selected_func=$(echo "$undefined_funcs" | sed -n "${func_num}p")
                    if [[ -n "$selected_func" ]]; then
                        create_go_function "$selected_func"
                    fi
                fi
            else
                print "${YELLOW}No undefined functions found${RESET}"
            fi
            ;;
        4)
            print -n "Enter file path to analyze: "
            read file_path
            if [[ -f "$file_path" ]]; then
                print "${BLUE}Errors in $file_path:${RESET}"
                go build "$file_path" 2>&1
            else
                print "${RED}File not found: $file_path${RESET}"
            fi
            ;;
    esac
    
    print "${BLUE}📁 Error log saved to: $error_file${RESET}"
}

# Comprehensive Go analysis  
comprehensive_go_analysis() {
    print "${YELLOW}🔬 Comprehensive Go Project Analysis${RESET}"
    
    # Project overview
    print "${BLUE}📊 Project Overview:${RESET}"
    local module_name=$(head -1 go.mod 2>/dev/null || echo "No go.mod")
    local package_count=$(go list ./... 2>/dev/null | wc -l || echo "0")
    local go_file_count=$(find . -name "*.go" -not -path "./vendor/*" | wc -l)
    
    print "  Module: $module_name"
    print "  Packages: $package_count"
    print "  Go files: $go_file_count"
    
    # Build status
    print "\n${BLUE}🏗️ Build Status:${RESET}"
    if go build ./... > /dev/null 2>&1; then
        print "${GREEN}  ✅ All packages compile${RESET}"
    else
        print "${RED}  ❌ Build errors exist${RESET}"
        analyze_go_errors
        return
    fi
    
    # Test status
    print "\n${BLUE}🧪 Test Status:${RESET}"
    local test_output=$(go test ./... 2>&1)
    if echo "$test_output" | grep -q "PASS"; then
        local pass_count=$(echo "$test_output" | grep -c "PASS" || echo "0")
        print "${GREEN}  ✅ $pass_count packages pass tests${RESET}"
    elif echo "$test_output" | grep -q "no test files"; then
        print "${YELLOW}  ⚠️ No test files found${RESET}"
    else
        print "${RED}  ❌ Some tests failing${RESET}"
        echo "$test_output" | grep -E "FAIL|ERROR" | head -5
    fi
    
    # Dependency analysis
    print "\n${BLUE}📦 Dependencies:${RESET}"
    local direct_deps=$(go list -m all 2>/dev/null | grep -v "$(head -1 go.mod | cut -d' ' -f2)" | wc -l || echo "0")
    print "  Direct dependencies: $direct_deps"
    
    # Security check
    if command -v gosec &> /dev/null; then
        print "\n${BLUE}🔒 Security Scan:${RESET}"
        local sec_issues=$(gosec ./... 2>/dev/null | grep -c "Issues:" || echo "0")
        if [[ "$sec_issues" -eq 0 ]]; then
            print "${GREEN}  ✅ No security issues found${RESET}"
        else
            print "${YELLOW}  ⚠️ $sec_issues security issues found${RESET}"
        fi
    fi
    
    # Performance hints
    print "\n${BLUE}⚡ Performance Analysis:${RESET}"
    if go build -race ./... > /dev/null 2>&1; then
        print "${GREEN}  ✅ No race conditions detected${RESET}"
    else
        print "${YELLOW}  ⚠️ Potential race conditions${RESET}"
    fi
    
    # Code quality
    if command -v golangci-lint &> /dev/null; then
        print "\n${BLUE}✨ Code Quality:${RESET}"
        local lint_output=$(golangci-lint run --fast 2>/dev/null || echo "")
        if [[ -z "$lint_output" ]]; then
            print "${GREEN}  ✅ No linting issues${RESET}"
        else
            local issue_count=$(echo "$lint_output" | wc -l)
            print "${YELLOW}  ⚠️ $issue_count linting issues found${RESET}"
        fi
    fi
}

# Go-specific project structure validation
validate_go_structure() {
    print "${YELLOW}🏗️ Go Project Structure Validation${RESET}"
    
    # Check for standard Go project structure
    local score=0
    local max_score=10
    
    # Essential files/dirs
    [[ -f "go.mod" ]] && { print "${GREEN}  ✅ go.mod${RESET}"; ((score++)); } || print "${RED}  ❌ go.mod missing${RESET}"
    [[ -f "go.sum" ]] && { print "${GREEN}  ✅ go.sum${RESET}"; ((score++)); } || print "${YELLOW}  ⚠️ go.sum missing (run go mod tidy)${RESET}"
    [[ -f "README.md" ]] && { print "${GREEN}  ✅ README.md${RESET}"; ((score++)); } || print "${YELLOW}  ⚠️ README.md missing${RESET}"
    
    # Standard directories
    [[ -d "cmd" ]] && { print "${GREEN}  ✅ cmd/ directory${RESET}"; ((score++)); } || print "${YELLOW}  ⚠️ cmd/ directory missing${RESET}"
    [[ -d "pkg" ]] && { print "${GREEN}  ✅ pkg/ directory${RESET}"; ((score++)); } || print "${BLUE}  ℹ️ pkg/ directory not used${RESET}"
    [[ -d "internal" ]] && { print "${GREEN}  ✅ internal/ directory${RESET}"; ((score++)); } || print "${BLUE}  ℹ️ internal/ directory not used${RESET}"
    
    # Build files
    [[ -f "Makefile" ]] && { print "${GREEN}  ✅ Makefile${RESET}"; ((score++)); } || print "${BLUE}  ℹ️ Makefile not present${RESET}"
    [[ -f "Dockerfile" ]] && { print "${GREEN}  ✅ Dockerfile${RESET}"; ((score++)); } || print "${BLUE}  ℹ️ Dockerfile not present${RESET}"
    
    # Config files
    [[ -f ".golangci.yml" ]] && { print "${GREEN}  ✅ .golangci.yml${RESET}"; ((score++)); } || print "${BLUE}  ℹ️ golangci-lint config not present${RESET}"
    [[ -f ".gitignore" ]] && { print "${GREEN}  ✅ .gitignore${RESET}"; ((score++)); } || print "${YELLOW}  ⚠️ .gitignore missing${RESET}"
    
    print "\n${BLUE}Structure Score: $score/$max_score${RESET}"
    
    if [[ $score -lt 5 ]]; then
        print "${RED}  🔴 Structure needs improvement${RESET}"
    elif [[ $score -lt 8 ]]; then
        print "${YELLOW}  🟡 Good structure, some improvements possible${RESET}"
    else
        print "${GREEN}  🟢 Excellent Go project structure${RESET}"
    fi
}

# Go dependency analyzer
analyze_go_dependencies() {
    print "${YELLOW}📦 Go Dependency Analysis${RESET}"
    
    if [[ ! -f "go.mod" ]]; then
        print "${RED}❌ No go.mod found${RESET}"
        return
    fi
    
    # Direct vs indirect dependencies
    local all_deps=$(go list -m all 2>/dev/null | tail -n +2)
    local direct_deps=$(go list -m -f '{{if not .Indirect}}{{.Path}}{{end}}' all 2>/dev/null | grep -v '^
    )
    local indirect_deps=$(go list -m -f '{{if .Indirect}}{{.Path}}{{end}}' all 2>/dev/null | grep -v '^
    )
    
    print "${BLUE}📊 Dependency Summary:${RESET}"
    print "  Direct: $(echo "$direct_deps" | wc -l)"
    print "  Indirect: $(echo "$indirect_deps" | wc -l)"
    print "  Total: $(echo "$all_deps" | wc -l)"
    
    # Show largest dependencies
    print "\n${BLUE}🔝 Top Direct Dependencies:${RESET}"
    echo "$direct_deps" | head -10 | while read dep; do
        [[ -n "$dep" ]] && print "  • $dep"
    done
    
    # Check for updates
    print "\n${BLUE}📅 Update Check:${RESET}"
    local updates=$(go list -u -m all 2>/dev/null | grep '\[')
    if [[ -n "$updates" ]]; then
        print "${YELLOW}⚠️ Updates available:${RESET}"
        echo "$updates" | head -5 | while read update; do
            print "  $update"
        done
    else
        print "${GREEN}✅ All dependencies up to date${RESET}"
    fi
    
    # Vulnerability check (if govulncheck is available)
    if command -v govulncheck &> /dev/null; then
        print "\n${BLUE}🔒 Vulnerability Check:${RESET}"
        local vulns=$(govulncheck ./... 2>/dev/null)
        if echo "$vulns" | grep -q "No vulnerabilities found"; then
            print "${GREEN}✅ No vulnerabilities found${RESET}"
        else
            print "${RED}⚠️ Vulnerabilities detected${RESET}"
            echo "$vulns" | head -5
        fi
    fi
}

# Go performance analyzer
analyze_go_performance() {
    print "${YELLOW}⚡ Go Performance Analysis${RESET}"
    
    # Build with race detection
    print "${BLUE}🏃 Race Condition Check:${RESET}"
    if go build -race ./... > /dev/null 2>&1; then
        print "${GREEN}  ✅ No race conditions in build${RESET}"
    else
        print "${RED}  ❌ Race conditions detected${RESET}"
        go build -race ./... 2>&1 | head -5
    fi
    
    # Memory usage check
    print "\n${BLUE}💾 Memory Analysis:${RESET}"
    if [[ -d "cmd" ]]; then
        local main_pkg=$(ls cmd/ | head -1)
        if [[ -n "$main_pkg" ]]; then
            # Build and check binary size
            if go build -o "/tmp/test_binary" "./cmd/$main_pkg" 2>/dev/null; then
                local size=$(ls -lah "/tmp/test_binary" | awk '{print $5}')
                print "  Binary size: $size"
                rm -f "/tmp/test_binary"
            fi
        fi
    fi
    
    # Benchmark tests
    print "\n${BLUE}📊 Benchmark Tests:${RESET}"
    local bench_output=$(go test -bench=. ./... 2>/dev/null | grep -E "Benchmark|PASS|FAIL")
    if [[ -n "$bench_output" ]]; then
        echo "$bench_output" | head -10
    else
        print "${YELLOW}  ⚠️ No benchmark tests found${RESET}"
    fi
}

# Smart Go import fixer
fix_go_imports() {
    print "${YELLOW}📦 Smart Go Import Fixer${RESET}"
    
    # Install goimports if needed
    if ! command -v goimports &> /dev/null; then
        print "${YELLOW}Installing goimports...${RESET}"
        go install golang.org/x/tools/cmd/goimports@latest
    fi
    
    # Find files with import issues
    local files_with_issues=()
    local build_output=$(go build ./... 2>&1)
    
    # Extract files with unused imports
    while read -r line; do
        if [[ "$line" =~ (.*):[0-9]+:[0-9]+:.*imported.and.not.used ]]; then
            local file="${match[1]}"
            files_with_issues+=("$file")
        fi
    done <<< "$build_output"
    
    if [[ ${#files_with_issues[@]} -gt 0 ]]; then
        print "${BLUE}🔧 Fixing imports in ${#files_with_issues[@]} files...${RESET}"
        for file in "${files_with_issues[@]}"; do
            goimports -w "$file"
            print "  ✅ Fixed: $file"
        done
    else
        print "${BLUE}🔧 Running goimports on all Go files...${RESET}"
        find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
    fi
    
    # Re-check build
    if go build ./... > /dev/null 2>&1; then
        print "${GREEN}🎉 All import issues resolved!${RESET}"
    else
        print "${YELLOW}⚠️ Some issues remain${RESET}"
        go build ./... 2>&1 | grep -E "imported and not used|undefined:" | head -3
    fi
}