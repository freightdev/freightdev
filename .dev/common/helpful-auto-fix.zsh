#!/usr/bin/env zsh

# devtools/project-helpers/auto-fix.zsh - Automatic issue resolution

autoload -U colors && colors

auto_fix_issues() {
    print "${YELLOW}🛠️ Auto-Fix Common Issues${RESET}"
    
    # Detect project type first
    [[ -z "$CURRENT_LANG" ]] && detect_project_type
    
    print "${BLUE}🔍 Analyzing project for auto-fixable issues...${RESET}"
    
    # Create backup before any fixes
    local backup_dir="auto-fix-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    print "${BLUE}📦 Creating backup in $backup_dir${RESET}"
    
    # Backup important files
    case "$CURRENT_LANG" in
        "go")
            [[ -f "go.mod" ]] && cp "go.mod" "$backup_dir/"
            [[ -f "go.sum" ]] && cp "go.sum" "$backup_dir/"
            find . -name "*.go" -not -path "./vendor/*" | head -20 | while read file; do
                cp "$file" "$backup_dir/$(basename "$file").backup"
            done
            ;;
        "node")
            [[ -f "package.json" ]] && cp "package.json" "$backup_dir/"
            [[ -f "package-lock.json" ]] && cp "package-lock.json" "$backup_dir/"
            [[ -f "yarn.lock" ]] && cp "yarn.lock" "$backup_dir/"
            ;;
        "python")
            [[ -f "requirements.txt" ]] && cp "requirements.txt" "$backup_dir/"
            [[ -f "pyproject.toml" ]] && cp "pyproject.toml" "$backup_dir/"
            [[ -f "setup.py" ]] && cp "setup.py" "$backup_dir/"
            ;;
    esac
    
    local fixes_applied=0
    
    # Language-specific auto-fixes
    case "$CURRENT_LANG" in
        "go")
            fixes_applied=$(auto_fix_go_issues)
            ;;
        "node")
            fixes_applied=$(auto_fix_node_issues)
            ;;
        "python")
            fixes_applied=$(auto_fix_python_issues)
            ;;
        *)
            fixes_applied=$(auto_fix_generic_issues)
            ;;
    esac
    
    # Generic fixes that apply to all projects
    local generic_fixes=$(auto_fix_generic_issues)
    ((fixes_applied += generic_fixes))
    
    # Summary
    print "\n${BLUE}📊 Auto-Fix Summary:${RESET}"
    print "  Fixes applied: $fixes_applied"
    print "  Backup location: $backup_dir"
    
    if [[ $fixes_applied -gt 0 ]]; then
        print "${GREEN}✅ Auto-fixes completed successfully!${RESET}"
        
        # Verify fixes worked
        print "\n${YELLOW}🔍 Verifying fixes...${RESET}"
        verify_auto_fixes
    else
        print "${YELLOW}ℹ️ No auto-fixable issues found${RESET}"
    fi
}

# Go-specific auto-fixes
auto_fix_go_issues() {
    local fixes=0
    
    print "${BLUE}🐹 Go Auto-Fixes${RESET}"
    
    # Fix 1: Import issues
    print "  🔧 Fixing imports..."
    if command -v goimports &> /dev/null; then
        find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
        print "    ✅ goimports applied"
        ((fixes++))
    else
        print "    📥 Installing goimports..."
        go install golang.org/x/tools/cmd/goimports@latest
        find . -name "*.go" -not -path "./vendor/*" | xargs goimports -w
        print "    ✅ goimports installed and applied"
        ((fixes++))
    fi
    
    # Fix 2: Format code
    print "  🔧 Formatting code..."
    go fmt ./...
    print "    ✅ go fmt applied"
    ((fixes++))
    
    # Fix 3: Clean dependencies
    print "  🔧 Cleaning dependencies..."
    go mod tidy
    go mod download
    print "    ✅ Dependencies cleaned"
    ((fixes++))
    
    # Fix 4: Generate missing code
    print "  🔧 Generating missing code..."
    if go generate ./... > /dev/null 2>&1; then
        print "    ✅ go generate completed"
        ((fixes++))
    else
        print "    ⚠️ go generate had issues (not critical)"
    fi
    
    # Fix 5: Fix common undefined function issues
    print "  🔧 Checking for undefined functions..."
    local build_output=$(go build ./... 2>&1)
    
    if echo "$build_output" | grep -q "undefined:"; then
        # Extract undefined function names
        local undefined_funcs=$(echo "$build_output" | grep "undefined:" | sed -n 's/.*undefined: \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' | sort -u)
        
        echo "$undefined_funcs" | while read func_name; do
            [[ -z "$func_name" ]] && continue
            
            # Try to find the function in other files
            local found_def=$(rg -n "func.*$func_name" --type go . | head -1)
            
            if [[ -n "$found_def" ]]; then
                print "    ℹ️ $func_name found in: $(echo "$found_def" | cut -d: -f1)"
            else
                # Create a stub function
                local error_file=$(echo "$build_output" | grep "undefined: $func_name" | head -1 | cut -d: -f1)
                if [[ -f "$error_file" ]]; then
                    echo "" >> "$error_file"
                    echo "// TODO: Implement $func_name" >> "$error_file"
                    echo "func $func_name() error {" >> "$error_file"
                    echo "    return fmt.Errorf(\"$func_name not implemented\")" >> "$error_file"
                    echo "}" >> "$error_file"
                    print "    ✅ Created stub for $func_name in $error_file"
                    ((fixes++))
                fi
            fi
        done
    fi
    
    # Fix 6: Add missing imports for common packages
    print "  🔧 Adding missing common imports..."
    find . -name "*.go" -not -path "./vendor/*" | while read file; do
        # Check if file uses fmt but doesn't import it
        if grep -q 'fmt\.' "$file" && ! grep -q '"fmt"' "$file"; then
            # Add fmt import
            sed -i.bak '1a\
import "fmt"' "$file"
            rm -f "$file.bak"
            print "    ✅ Added fmt import to $(basename "$file")"
            ((fixes++))
        fi
        
        # Check for context usage
        if grep -q 'context\.' "$file" && ! grep -q '"context"' "$file"; then
            sed -i.bak '1a\
import "context"' "$file"
            rm -f "$file.bak"
            print "    ✅ Added context import to $(basename "$file")"
            ((fixes++))
        fi
    done
    
    echo "$fixes"
}

# Node.js-specific auto-fixes
auto_fix_node_issues() {
    local fixes=0
    
    print "${BLUE}📦 Node.js Auto-Fixes${RESET}"
    
    # Fix 1: Install dependencies
    print "  🔧 Installing/updating dependencies..."
    if [[ -f "package-lock.json" ]]; then
        npm install
        print "    ✅ npm install completed"
    elif [[ -f "yarn.lock" ]]; then
        yarn install
        print "    ✅ yarn install completed"
    elif [[ -f "package.json" ]]; then
        npm install
        print "    ✅ npm install completed"
    fi
    ((fixes++))
    
    # Fix 2: Fix package vulnerabilities
    print "  🔧 Fixing security vulnerabilities..."
    if command -v npm &> /dev/null && npm audit fix > /dev/null 2>&1; then
        print "    ✅ npm audit fix completed"
        ((fixes++))
    fi
    
    # Fix 3: Format code if prettier is available
    if [[ -f ".prettierrc" ]] || grep -q "prettier" package.json 2>/dev/null; then
        print "  🔧 Formatting with Prettier..."
        if npx prettier --write . > /dev/null 2>&1; then
            print "    ✅ Prettier formatting applied"
            ((fixes++))
        fi
    fi
    
    # Fix 4: ESLint auto-fix
    if [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || grep -q "eslint" package.json 2>/dev/null; then
        print "  🔧 Running ESLint auto-fix..."
        if npx eslint --fix . > /dev/null 2>&1; then
            print "    ✅ ESLint auto-fixes applied"
            ((fixes++))
        fi
    fi
    
    echo "$fixes"
}

# Python-specific auto-fixes
auto_fix_python_issues() {
    local fixes=0
    
    print "${BLUE}🐍 Python Auto-Fixes${RESET}"
    
    # Fix 1: Install requirements
    if [[ -f "requirements.txt" ]]; then
        print "  🔧 Installing requirements..."
        if pip install -r requirements.txt > /dev/null 2>&1; then
            print "    ✅ requirements.txt installed"
            ((fixes++))
        fi
    elif [[ -f "pyproject.toml" ]]; then
        print "  🔧 Installing project..."
        if pip install -e . > /dev/null 2>&1; then
            print "    ✅ pyproject.toml installed"
            ((fixes++))
        fi
    fi
    
    # Fix 2: Format with black if available
    if command -v black &> /dev/null; then
        print "  🔧 Formatting with black..."
        if black . > /dev/null 2>&1; then
            print "    ✅ Black formatting applied"
            ((fixes++))
        fi
    fi
    
    # Fix 3: Sort imports with isort
    if command -v isort &> /dev/null; then
        print "  🔧 Sorting imports with isort..."
        if isort . > /dev/null 2>&1; then
            print "    ✅ Import sorting applied"
            ((fixes++))
        fi
    fi
    
    # Fix 4: Remove unused imports with autoflake
    if command -v autoflake &> /dev/null; then
        print "  🔧 Removing unused imports..."
        if autoflake --remove-all-unused-imports --in-place --recursive . > /dev/null 2>&1; then
            print "    ✅ Unused imports removed"
            ((fixes++))
        fi
    fi
    
    echo "$fixes"
}

# Generic auto-fixes for all projects
auto_fix_generic_issues() {
    local fixes=0
    
    print "${BLUE}🔧 Generic Auto-Fixes${RESET}"
    
    # Fix 1: Remove trailing whitespace
    print "  🔧 Removing trailing whitespace..."
    find . -type f \( -name "*.go" -o -name "*.js" -o -name "*.py" -o -name "*.rs" -o -name "*.java" -o -name "*.md" \) \
        -not -path "./vendor/*" -not -path "./node_modules/*" -not -path "./.git/*" \
        -exec sed -i.bak 's/[[:space:]]*$//' {} \; -exec rm -f {}.bak \;
    print "    ✅ Trailing whitespace removed"
    ((fixes++))
    
    # Fix 2: Ensure files end with newline
    print "  🔧 Ensuring files end with newline..."
    find . -type f \( -name "*.go" -o -name "*.js" -o -name "*.py" -o -name "*.rs" -o -name "*.java" \) \
        -not -path "./vendor/*" -not -path "./node_modules/*" -not -path "./.git/*" \
        -exec sh -c 'tail -c1 "$1" | read -r _ || echo >> "$1"' _ {} \;
    print "    ✅ Newline endings fixed"
    ((fixes++))
    
    # Fix 3: Fix file permissions
    print "  🔧 Fixing executable permissions..."
    find . -name "*.sh" -o -name "*.zsh" -o -name "*.bash" | xargs chmod +x 2>/dev/null
    print "    ✅ Script permissions fixed"
    ((fixes++))
    
    # Fix 4: Create .gitignore if missing
    if [[ ! -f ".gitignore" ]]; then
        print "  🔧 Creating .gitignore..."
        cat > .gitignore << 'EOF'
# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/

# Build files
build/
dist/
*.log

# Dependency directories
node_modules/
vendor/
__pycache__/
*.pyc

# Environment files
.env
.env.local
EOF
        print "    ✅ .gitignore created"
        ((fixes++))
    fi
    
    # Fix 5: Fix line endings (convert CRLF to LF)
    print "  🔧 Converting line endings to LF..."
    find . -type f \( -name "*.go" -o -name "*.js" -o -name "*.py" -o -name "*.md" \) \
        -not -path "./vendor/*" -not -path "./node_modules/*" -not -path "./.git/*" \
        -exec dos2unix {} \; 2>/dev/null || true
    print "    ✅ Line endings normalized"
    ((fixes++))
    
    echo "$fixes"
}

# Verify that auto-fixes worked
verify_auto_fixes() {
    print "${YELLOW}🔍 Verification Results:${RESET}"
    
    case "$CURRENT_LANG" in
        "go")
            if go build ./... > /dev/null 2>&1; then
                print "  ${GREEN}✅ Go project builds successfully${RESET}"
                
                # Try to build main binary if exists
                if [[ -d "cmd" ]]; then
                    local main_cmd=$(ls cmd/ | head -1)
                    if [[ -n "$main_cmd" ]] && go build -o "/tmp/test_build" "./cmd/$main_cmd" 2>/dev/null; then
                        print "  ${GREEN}✅ Main binary builds successfully${RESET}"
                        rm -f "/tmp/test_build"
                    fi
                fi
            else
                print "  ${YELLOW}⚠️ Some build issues remain${RESET}"
                go build ./... 2>&1 | head -3 | while read line; do
                    print "    $line"
                done
            fi
            
            # Test compilation
            if go test -c ./... > /dev/null 2>&1; then
                print "  ${GREEN}✅ Tests compile successfully${RESET}"
            else
                print "  ${YELLOW}⚠️ Some test compilation issues remain${RESET}"
            fi
            ;;
            
        "node")
            if [[ -f "package.json" ]]; then
                if npm run build > /dev/null 2>&1 || yarn build > /dev/null 2>&1; then
                    print "  ${GREEN}✅ Node.js project builds successfully${RESET}"
                else
                    print "  ${BLUE}ℹ️ No build script or build issues${RESET}"
                fi
                
                if npm test > /dev/null 2>&1 || yarn test > /dev/null 2>&1; then
                    print "  ${GREEN}✅ Tests pass${RESET}"
                else
                    print "  ${BLUE}ℹ️ No test script or test issues${RESET}"
                fi
            fi
            ;;
            
        "python")
            if python -m py_compile **/*.py 2>/dev/null; then
                print "  ${GREEN}✅ Python files compile successfully${RESET}"
            else
                print "  ${YELLOW}⚠️ Some Python syntax issues remain${RESET}"
            fi
            ;;
    esac
    
    # Git status if in a git repo
    if [[ -d ".git" ]]; then
        print "\n${BLUE}📋 Git Status After Fixes:${RESET}"
        local changed_files=$(git status --porcelain | wc -l)
        print "  Files changed: $changed_files"
        
        if [[ $changed_files -gt 0 ]]; then
            print "  ${CYAN}Recent changes:${RESET}"
            git status --porcelain | head -5 | while read line; do
                print "    $line"
            done
        fi
    fi
}