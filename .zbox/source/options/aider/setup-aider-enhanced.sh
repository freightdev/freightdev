#!/bin/bash

# Enhanced Project Aider Bootstrap Script
# Combines project setup with distributed Ollama network management

echo "========================================"
echo "Project Aider Bootstrap (Enhanced)"
echo "========================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_question() { echo -e "${YELLOW}[?]${NC} $1"; }

# ============================================
# NETWORK OLLAMA DISCOVERY
# ============================================

# Your laptop network (edit these IPs!)
LAPTOP_IPS=(
    "192.168.1.100"  # Laptop 1
    "192.168.1.101"  # Laptop 2
    "192.168.1.102"  # Laptop 3
    "192.168.1.103"  # Laptop 4
)

check_ollama() {
    local host=$1
    local port=$2
    timeout 2 curl -s "http://${host}:${port}/api/tags" >/dev/null 2>&1
    return $?
}

get_ollama_models() {
    local host=$1
    local port=$2
    curl -s "http://${host}:${port}/api/tags" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4
}

scan_network_ollama() {
    print_status "Scanning network for Ollama instances..."
    
    declare -gA OLLAMA_INSTANCES
    local idx=0
    
    # Check local first
    if check_ollama "localhost" "11434"; then
        OLLAMA_INSTANCES[$idx]="localhost:11434:local"
        print_success "Found: localhost:11434 (LOCAL)"
        ((idx++))
    fi
    
    # Check remote laptops
    for ip in "${LAPTOP_IPS[@]}"; do
        if check_ollama "$ip" "11434"; then
            OLLAMA_INSTANCES[$idx]="$ip:11434:remote"
            print_success "Found: $ip:11434 (REMOTE)"
            ((idx++))
        fi
    done
    
    if [ ${#OLLAMA_INSTANCES[@]} -eq 0 ]; then
        print_error "No Ollama instances found!"
        return 1
    fi
    
    echo ""
    print_success "Found ${#OLLAMA_INSTANCES[@]} Ollama instance(s)"
    return 0
}

# ============================================
# GIT CHECK
# ============================================

if [ ! -d .git ]; then
    print_error "Not in a git repository. Initialize git first:"
    echo "  git init"
    exit 1
fi

PROJECT_ROOT=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

echo "Project: $PROJECT_NAME"
echo "Path: $PROJECT_ROOT"
echo ""

# ============================================
# NETWORK SCAN
# ============================================

if ! scan_network_ollama; then
    print_error "Cannot continue without Ollama"
    exit 1
fi

# ============================================
# 1. PROJECT TYPE & STACK
# ============================================
print_question "What type of project is this?"
echo "  1) Full-stack web app"
echo "  2) Backend API only"
echo "  3) Frontend only"
echo "  4) CLI tool/script"
echo "  5) Library/package"
echo "  6) Data science/ML"
echo "  7) Other/custom"
read -p "Choice [1-7]: " PROJECT_TYPE

case $PROJECT_TYPE in
    1) PROJECT_TYPE_NAME="fullstack";;
    2) PROJECT_TYPE_NAME="backend";;
    3) PROJECT_TYPE_NAME="frontend";;
    4) PROJECT_TYPE_NAME="cli";;
    5) PROJECT_TYPE_NAME="library";;
    6) PROJECT_TYPE_NAME="datascience";;
    7) PROJECT_TYPE_NAME="custom";;
    *) PROJECT_TYPE_NAME="custom";;
esac

echo ""
print_question "Primary programming language?"
echo "  1) Python"
echo "  2) JavaScript/TypeScript"
echo "  3) Go"
echo "  4) Rust"
echo "  5) Java/Kotlin"
echo "  6) Other"
read -p "Choice [1-6]: " LANG_CHOICE

case $LANG_CHOICE in
    1) PRIMARY_LANG="Python";;
    2) PRIMARY_LANG="JavaScript/TypeScript";;
    3) PRIMARY_LANG="Go";;
    4) PRIMARY_LANG="Rust";;
    5) PRIMARY_LANG="Java/Kotlin";;
    6) read -p "Enter language: " PRIMARY_LANG;;
    *) PRIMARY_LANG="Python";;
esac

# ============================================
# 2. OLLAMA SELECTION
# ============================================
echo ""
echo "========================================"
echo "Ollama Instance Selection"
echo "========================================"
echo ""

# Show available instances
echo "Available Ollama instances:"
for idx in "${!OLLAMA_INSTANCES[@]}"; do
    IFS=':' read -r host port type <<< "${OLLAMA_INSTANCES[$idx]}"
    echo "  $((idx+1))) $host:$port ($type)"
done
echo "  0) Manual entry"
echo ""

read -p "Select Ollama instance [1]: " OLLAMA_IDX
OLLAMA_IDX=${OLLAMA_IDX:-1}
OLLAMA_IDX=$((OLLAMA_IDX - 1))

if [ "$OLLAMA_IDX" == "-1" ]; then
    read -p "Enter Ollama host: " OLLAMA_HOST
    read -p "Enter Ollama port [11434]: " OLLAMA_PORT
    OLLAMA_PORT=${OLLAMA_PORT:-11434}
    INSTANCE_TYPE="manual"
else
    if [ -n "${OLLAMA_INSTANCES[$OLLAMA_IDX]}" ]; then
        IFS=':' read -r OLLAMA_HOST OLLAMA_PORT INSTANCE_TYPE <<< "${OLLAMA_INSTANCES[$OLLAMA_IDX]}"
    else
        print_error "Invalid selection"
        exit 1
    fi
fi

# Fetch models
echo ""
print_status "Fetching models from $OLLAMA_HOST:$OLLAMA_PORT..."
MODELS=$(get_ollama_models "$OLLAMA_HOST" "$OLLAMA_PORT")

if [ -z "$MODELS" ]; then
    print_error "Could not fetch models from $OLLAMA_HOST:$OLLAMA_PORT"
    read -p "Enter model name manually: " MODEL_NAME
else
    print_success "Available models:"
    echo "$MODELS" | nl
    echo ""
    read -p "Enter model name (or select by number): " MODEL_INPUT
    
    # Check if input is a number
    if [[ "$MODEL_INPUT" =~ ^[0-9]+$ ]]; then
        MODEL_NAME=$(echo "$MODELS" | sed -n "${MODEL_INPUT}p")
    else
        MODEL_NAME="$MODEL_INPUT"
    fi
fi

# ============================================
# 3. FALLBACK CONFIGURATION
# ============================================
echo ""
print_question "Configure fallback Ollama instances for load distribution?"
read -p "Enable fallbacks? [y/N]: " ENABLE_FALLBACK
ENABLE_FALLBACK=${ENABLE_FALLBACK:-N}

FALLBACK_HOSTS=""
if [[ "$ENABLE_FALLBACK" =~ ^[Yy]$ ]]; then
    echo ""
    print_status "Select fallback instances (comma-separated numbers):"
    for idx in "${!OLLAMA_INSTANCES[@]}"; do
        IFS=':' read -r host port type <<< "${OLLAMA_INSTANCES[$idx]}"
        if [ "$host:$port" != "$OLLAMA_HOST:$OLLAMA_PORT" ]; then
            echo "  $((idx+1))) $host:$port ($type)"
        fi
    done
    read -p "Fallback instances (e.g., 2,3): " FALLBACK_INPUT
    
    IFS=',' read -ra FALLBACK_ARRAY <<< "$FALLBACK_INPUT"
    for fb_idx in "${FALLBACK_ARRAY[@]}"; do
        fb_idx=$((fb_idx - 1))
        if [ -n "${OLLAMA_INSTANCES[$fb_idx]}" ]; then
            IFS=':' read -r fb_host fb_port fb_type <<< "${OLLAMA_INSTANCES[$fb_idx]}"
            FALLBACK_HOSTS="${FALLBACK_HOSTS}http://${fb_host}:${fb_port},"
        fi
    done
    FALLBACK_HOSTS=${FALLBACK_HOSTS%,}  # Remove trailing comma
fi

# ============================================
# 4. PROJECT GOALS & CONTEXT
# ============================================
echo ""
echo "========================================"
echo "Project Goals & Context"
echo "========================================"
echo ""

read -p "Brief project description: " PROJECT_DESC

echo ""
print_question "What are the main goals for this project?"
echo "(Enter multiple goals, one per line. Empty line to finish)"
GOALS=""
while true; do
    read -p "Goal: " GOAL
    if [ -z "$GOAL" ]; then
        break
    fi
    GOALS="$GOALS- $GOAL"$'\n'
done

# ============================================
# 5. PERMITTED TOOLS & TECHNOLOGIES
# ============================================
echo ""
echo "========================================"
echo "Permitted Tools & Technologies"
echo "========================================"
echo ""

print_question "Permitted frameworks/libraries? (comma-separated)"
read -p "Examples: flask,fastapi,react,vue: " FRAMEWORKS

print_question "Permitted external APIs/services? (comma-separated)"
read -p "Examples: stripe,openai,aws: " APIS

print_question "Database systems permitted? (comma-separated)"
read -p "Examples: postgresql,mongodb,redis: " DATABASES

# ============================================
# 6. PROJECT STRUCTURE & PATHS
# ============================================
echo ""
echo "========================================"
echo "Project Structure"
echo "========================================"
echo ""

print_question "Define important project paths:"
read -p "Source code directory [src]: " SRC_DIR
SRC_DIR=${SRC_DIR:-src}

read -p "Test directory [tests]: " TEST_DIR
TEST_DIR=${TEST_DIR:-tests}

read -p "Documentation directory [docs]: " DOCS_DIR
DOCS_DIR=${DOCS_DIR:-docs}

read -p "Configuration directory [config]: " CONFIG_DIR
CONFIG_DIR=${CONFIG_DIR:-config}

# ============================================
# 7. DEVELOPMENT CONSTRAINTS
# ============================================
echo ""
echo "========================================"
echo "Development Constraints"
echo "========================================"
echo ""

print_question "Code style/linting tools?"
read -p "Examples: black,eslint,prettier [none]: " LINTERS

print_question "Testing framework?"
read -p "Examples: pytest,jest,go test [none]: " TEST_FRAMEWORK

print_question "Any forbidden patterns or anti-patterns?"
read -p "(Enter forbidden patterns, comma-separated): " FORBIDDEN

# ============================================
# 8. AIDER BEHAVIOR CONFIGURATION
# ============================================
echo ""
echo "========================================"
echo "Aider Behavior"
echo "========================================"
echo ""

print_question "Auto-commit changes?"
read -p "Let aider auto-commit? [Y/n]: " AUTO_COMMIT
AUTO_COMMIT=${AUTO_COMMIT:-Y}

print_question "Edit format?"
echo "  1) Whole file (default)"
echo "  2) Unified diff"
echo "  3) Diff"
read -p "Choice [1-3]: " EDIT_FORMAT
case $EDIT_FORMAT in
    2) EDIT_FORMAT_VALUE="udiff";;
    3) EDIT_FORMAT_VALUE="diff";;
    *) EDIT_FORMAT_VALUE="whole";;
esac

read -p "Max tokens for context [8192]: " MAX_TOKENS
MAX_TOKENS=${MAX_TOKENS:-8192}

# ============================================
# GENERATE CONFIGURATION FILES
# ============================================
echo ""
print_status "Generating project configuration files..."

# Create .aider.conf.yml
cat > .aider.conf.yml <<EOF
# Aider configuration for: $PROJECT_NAME
# Generated: $(date)

# Ollama Configuration
model: ollama/$MODEL_NAME
$([ "$OLLAMA_HOST" != "localhost" ] && echo "ollama-api-base: http://$OLLAMA_HOST:$OLLAMA_PORT")

# Editor Settings
edit-format: $EDIT_FORMAT_VALUE
$([ "$AUTO_COMMIT" =~ ^[Yy]$ ] && echo "auto-commits: true" || echo "auto-commits: false")

# Context Settings
max-chat-history-tokens: $MAX_TOKENS

# Files to always include in context
read:
  - README.md
  - PROJECT_CONTEXT.md
$([ -f "ARCHITECTURE.md" ] && echo "  - ARCHITECTURE.md")

# Git settings
git: true
gitignore: true
$([ "$AUTO_COMMIT" =~ ^[Yy]$ ] || echo "dirty-commits: false")

# Display settings
dark-mode: true
pretty: true
show-diffs: true
EOF

print_success ".aider.conf.yml created"

# Create PROJECT_CONTEXT.md
cat > PROJECT_CONTEXT.md <<EOF
# $PROJECT_NAME - Project Context

**Generated:** $(date)

## Project Overview
$PROJECT_DESC

## Project Type
- Type: $PROJECT_TYPE_NAME
- Primary Language: $PRIMARY_LANG

## Goals
$GOALS

## Technology Stack

### Permitted Frameworks/Libraries
$FRAMEWORKS

### Permitted APIs/Services
$APIS

### Databases
$DATABASES

## Project Structure

\`\`\`
$PROJECT_NAME/
├── $SRC_DIR/          # Source code
├── $TEST_DIR/         # Tests
├── $DOCS_DIR/         # Documentation
└── $CONFIG_DIR/       # Configuration
\`\`\`

### Key Paths
- Source: \`$SRC_DIR/\`
- Tests: \`$TEST_DIR/\`
- Docs: \`$DOCS_DIR/\`
- Config: \`$CONFIG_DIR/\`

## Development Guidelines

### Code Quality
$([ -n "$LINTERS" ] && echo "- Linters: $LINTERS")
$([ -n "$TEST_FRAMEWORK" ] && echo "- Testing: $TEST_FRAMEWORK")

### Forbidden Patterns
$([ -n "$FORBIDDEN" ] && echo "$FORBIDDEN" || echo "None specified")

## AI Assistant Instructions

When working on this project:
1. Follow the technology stack defined above
2. Respect the project structure
3. Write tests using $TEST_FRAMEWORK
4. Maintain code style with $LINTERS
5. Keep changes focused and atomic
6. Document significant changes
7. Never use forbidden patterns
8. Always validate against project goals

## Ollama Configuration
- Primary Model: $MODEL_NAME
- Primary Host: $OLLAMA_HOST:$OLLAMA_PORT ($INSTANCE_TYPE)
$([ -n "$FALLBACK_HOSTS" ] && echo "- Fallback Hosts: $FALLBACK_HOSTS")
EOF

print_success "PROJECT_CONTEXT.md created"

# Create smart startup script with fallback support
cat > start-aider.sh <<'SCRIPT_EOF'
#!/bin/bash
# Smart Aider Startup with Network Fallback

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PRIMARY_HOST="OLLAMA_HOST_PLACEHOLDER"
PRIMARY_PORT="OLLAMA_PORT_PLACEHOLDER"
FALLBACK_HOSTS="FALLBACK_HOSTS_PLACEHOLDER"

check_ollama() {
    local host=$1
    local port=$2
    timeout 2 curl -s "http://${host}:${port}/api/tags" >/dev/null 2>&1
    return $?
}

find_available_ollama() {
    echo -e "${BLUE}[*]${NC} Checking Ollama availability..."
    
    # Check primary
    if check_ollama "$PRIMARY_HOST" "$PRIMARY_PORT"; then
        echo -e "${GREEN}[✓]${NC} Primary Ollama available: $PRIMARY_HOST:$PRIMARY_PORT"
        export OLLAMA_API_BASE="http://$PRIMARY_HOST:$PRIMARY_PORT"
        return 0
    fi
    
    echo -e "${YELLOW}[!]${NC} Primary Ollama unavailable, checking fallbacks..."
    
    # Check fallbacks
    if [ -n "$FALLBACK_HOSTS" ]; then
        IFS=',' read -ra FALLBACKS <<< "$FALLBACK_HOSTS"
        for fb_url in "${FALLBACKS[@]}"; do
            fb_host=$(echo "$fb_url" | sed 's|http://||' | cut -d':' -f1)
            fb_port=$(echo "$fb_url" | sed 's|http://||' | cut -d':' -f2)
            
            if check_ollama "$fb_host" "$fb_port"; then
                echo -e "${GREEN}[✓]${NC} Fallback Ollama available: $fb_host:$fb_port"
                export OLLAMA_API_BASE="http://$fb_host:$fb_port"
                return 0
            fi
        done
    fi
    
    echo -e "${RED}[✗]${NC} No Ollama instances available!"
    return 1
}

# Load environment
source ~/.bashrc 2>/dev/null || true

# Activate venv if exists
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Find available Ollama
if ! find_available_ollama; then
    echo ""
    echo "Please start an Ollama instance or check network connectivity"
    exit 1
fi

# Start aider
echo ""
echo -e "${BLUE}[*]${NC} Starting aider for $(basename $(pwd))..."
echo -e "${BLUE}[*]${NC} Reading PROJECT_CONTEXT.md..."
echo ""

aider --read PROJECT_CONTEXT.md "$@"
SCRIPT_EOF

# Replace placeholders
sed -i "s|OLLAMA_HOST_PLACEHOLDER|$OLLAMA_HOST|g" start-aider.sh
sed -i "s|OLLAMA_PORT_PLACEHOLDER|$OLLAMA_PORT|g" start-aider.sh
sed -i "s|FALLBACK_HOSTS_PLACEHOLDER|$FALLBACK_HOSTS|g" start-aider.sh

chmod +x start-aider.sh
print_success "start-aider.sh created with network fallback"

# Create directories
mkdir -p "$SRC_DIR" "$TEST_DIR" "$DOCS_DIR" "$CONFIG_DIR"
mkdir -p .aider.tags.cache.v3
print_success "Project directories created"

# Update .gitignore
if [ ! -f .gitignore ]; then
    touch .gitignore
fi

if ! grep -q ".aider" .gitignore; then
    cat >> .gitignore <<EOF

# Aider
.aider*
!.aider.conf.yml
EOF
    print_success "Updated .gitignore"
fi

# Create/Update README
if [ ! -f README.md ]; then
    cat > README.md <<EOF
# $PROJECT_NAME

$PROJECT_DESC

## Project Type
$PROJECT_TYPE_NAME - $PRIMARY_LANG

## Quick Start

### Start Aider
\`\`\`bash
./start-aider.sh
\`\`\`

The startup script will automatically:
- Check primary Ollama instance
- Fall back to remote instances if needed
- Load project context

### Configuration
- Aider config: \`.aider.conf.yml\`
- Project context: \`PROJECT_CONTEXT.md\`
- Primary Ollama: \`$OLLAMA_HOST:$OLLAMA_PORT\` using \`$MODEL_NAME\`
$([ -n "$FALLBACK_HOSTS" ] && echo "- Fallback Ollama: \`$FALLBACK_HOSTS\`")

## Project Structure
- \`$SRC_DIR/\` - Source code
- \`$TEST_DIR/\` - Tests
- \`$DOCS_DIR/\` - Documentation
- \`$CONFIG_DIR/\` - Configuration

## Goals
$GOALS

## Development Guidelines
$([ -n "$LINTERS" ] && echo "- Code style: $LINTERS")
$([ -n "$TEST_FRAMEWORK" ] && echo "- Testing: $TEST_FRAMEWORK")
$([ -n "$FORBIDDEN" ] && echo "- Forbidden: $FORBIDDEN")
EOF
    print_success "README.md created"
fi

# ============================================
# FINAL SUMMARY
# ============================================
echo ""
echo "========================================"
echo -e "${GREEN}Bootstrap Complete!${NC}"
echo "========================================"
echo ""
echo "Project: $PROJECT_NAME"
echo "Type: $PROJECT_TYPE_NAME ($PRIMARY_LANG)"
echo "Primary Ollama: $OLLAMA_HOST:$OLLAMA_PORT ($MODEL_NAME)"
$([ -n "$FALLBACK_HOSTS" ] && echo "Fallback Ollama: $FALLBACK_HOSTS")
echo ""
echo "Files created:"
echo "  ✓ .aider.conf.yml          - Aider configuration"
echo "  ✓ PROJECT_CONTEXT.md       - Project context for AI"
echo "  ✓ start-aider.sh           - Smart startup with fallback"
echo "  ✓ README.md                - Project readme"
echo "  ✓ Project directories      - $SRC_DIR, $TEST_DIR, $DOCS_DIR, $CONFIG_DIR"
echo ""
echo "Network Features:"
echo "  ✓ Automatic Ollama discovery"
echo "  ✓ Primary/fallback configuration"
echo "  ✓ Connection health checks"
echo ""
echo "Next steps:"
echo "  1. Review PROJECT_CONTEXT.md"
echo "  2. Start aider: ./start-aider.sh"
echo "  3. The AI will understand your project rules!"
echo ""
echo "The AI assistant will now know:"
echo "  - Your project goals and constraints"
echo "  - Permitted/forbidden technologies"
echo "  - Project structure and conventions"
echo "  - Which Ollama to use (with fallback!)"
echo ""
