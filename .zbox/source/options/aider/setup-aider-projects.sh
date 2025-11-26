#!/bin/bash

# Project Aider Bootstrap Script
# This creates a complete aider setup for a single project with custom configuration

echo "========================================"
echo "Project Aider Bootstrap"
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

# Check if in a git repo
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
    6) 
        read -p "Enter language: " PRIMARY_LANG
        ;;
    *) PRIMARY_LANG="Python";;
esac

# ============================================
# 2. OLLAMA CONFIGURATION
# ============================================
echo ""
echo "========================================"
echo "Ollama Configuration"
echo "========================================"
echo ""

print_question "Available Ollama instances:"
echo "  1) Local (this machine)"
echo "  2) Remote laptop 1"
echo "  3) Remote laptop 2"
echo "  4) Remote laptop 3"
echo "  5) Custom IP"
read -p "Which Ollama? [1-5]: " OLLAMA_CHOICE

case $OLLAMA_CHOICE in
    1)
        OLLAMA_HOST="localhost"
        OLLAMA_PORT="11434"
        ;;
    2|3|4)
        read -p "Enter laptop IP: " OLLAMA_HOST
        OLLAMA_PORT="11434"
        ;;
    5)
        read -p "Enter Ollama IP: " OLLAMA_HOST
        read -p "Enter Ollama port [11434]: " OLLAMA_PORT
        OLLAMA_PORT=${OLLAMA_PORT:-11434}
        ;;
esac

# Fetch available models
echo ""
print_status "Fetching available models from $OLLAMA_HOST:$OLLAMA_PORT..."
MODELS=$(curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

if [ -z "$MODELS" ]; then
    print_error "Could not connect to Ollama at $OLLAMA_HOST:$OLLAMA_PORT"
    echo "Available models (manual entry):"
    echo "  codellama:13b, mistral, deepseek-coder, llama2:13b, etc."
    read -p "Enter model name: " MODEL_NAME
else
    print_success "Available models:"
    echo "$MODELS" | nl
    echo ""
    read -p "Enter model name: " MODEL_NAME
fi

# ============================================
# 3. PROJECT GOALS & CONTEXT
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
# 4. PERMITTED TOOLS & TECHNOLOGIES
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
# 5. PROJECT STRUCTURE & PATHS
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
# 6. DEVELOPMENT CONSTRAINTS
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
# 7. AIDER BEHAVIOR CONFIGURATION
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
    2) EDIT_FORMAT_VALUE="diff";;
    3) EDIT_FORMAT_VALUE="udiff";;
    *) EDIT_FORMAT_VALUE="whole";;
esac

read -p "Max tokens for context [4096]: " MAX_TOKENS
MAX_TOKENS=${MAX_TOKENS:-4096}

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
$([ -f "ARCHITECTURE.md" ] && echo "  - ARCHITECTURE.md")
$([ -f "$SRC_DIR/main.py" ] && echo "  - $SRC_DIR/main.py")
$([ -f "$SRC_DIR/index.js" ] && echo "  - $SRC_DIR/index.js")

# Git settings
git: true
gitignore: true
$([ "$AUTO_COMMIT" =~ ^[Yy]$ ] || echo "dirty-commits: false")

# Voice settings
voice-language: en
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

## Ollama Configuration
- Model: $MODEL_NAME
- Host: $OLLAMA_HOST:$OLLAMA_PORT
EOF

print_success "PROJECT_CONTEXT.md created"

# Create .aider.tags.cache.v3 directory
mkdir -p .aider.tags.cache.v3
print_success ".aider.tags.cache.v3/ created"

# Create project directories if they don't exist
mkdir -p "$SRC_DIR" "$TEST_DIR" "$DOCS_DIR" "$CONFIG_DIR"
print_success "Project directories created"

# Create .gitignore additions for aider
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

# Create startup script
cat > start-aider.sh <<'EOF'
#!/bin/bash
# Start aider for this project

# Load environment
source ~/.bashrc 2>/dev/null || true

# Activate venv if exists
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Start aider with project context
echo "Starting aider for $(basename $(pwd))..."
echo "Reading PROJECT_CONTEXT.md..."
echo ""

aider --read PROJECT_CONTEXT.md "$@"
EOF

chmod +x start-aider.sh
print_success "start-aider.sh created"

# Create README if it doesn't exist
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

### Configuration
- Aider config: \`.aider.conf.yml\`
- Project context: \`PROJECT_CONTEXT.md\`
- Ollama: \`$OLLAMA_HOST:$OLLAMA_PORT\` using \`$MODEL_NAME\`

## Project Structure
- \`$SRC_DIR/\` - Source code
- \`$TEST_DIR/\` - Tests
- \`$DOCS_DIR/\` - Documentation
- \`$CONFIG_DIR/\` - Configuration

## Goals
$GOALS
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
echo "Ollama: $OLLAMA_HOST:$OLLAMA_PORT ($MODEL_NAME)"
echo ""
echo "Files created:"
echo "  ✓ .aider.conf.yml          - Aider configuration"
echo "  ✓ PROJECT_CONTEXT.md       - Project context for AI"
echo "  ✓ start-aider.sh           - Startup script"
echo "  ✓ README.md                - Project readme"
echo "  ✓ Project directories      - $SRC_DIR, $TEST_DIR, $DOCS_DIR, $CONFIG_DIR"
echo ""
echo "Next steps:"
echo "  1. Review and edit PROJECT_CONTEXT.md if needed"
echo "  2. Review .aider.conf.yml settings"
echo "  3. Start aider: ./start-aider.sh"
echo ""
echo "Usage:"
echo "  ./start-aider.sh              # Start with project context"
echo "  ./start-aider.sh --help       # See aider options"
echo "  aider --read PROJECT_CONTEXT.md  # Manual start"
echo ""
echo "The AI assistant will now understand:"
echo "  - Your project goals and constraints"
echo "  - Permitted tools and technologies"
echo "  - Project structure and paths"
echo "  - Development guidelines"
echo ""
