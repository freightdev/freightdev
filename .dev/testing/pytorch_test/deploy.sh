#!/bin/bash
# AI Framework Deployment Script
# Deploys all framework files to correct locations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_ROOT="$HOME/WORKSPACE/ai/setup/framework/pytorch"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║           AI Training Framework - Deployment Script            ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}Warning: Not running as root. Some operations may require sudo.${NC}\n"
fi

# Function to copy file with status
copy_file() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [[ -f "$src" ]]; then
        cp "$src" "$dest"
        echo -e "  ${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "  ${YELLOW}⚠${NC} $name (not found)"
        return 1
    fi
}

# Step 1: Create directory structure
echo -e "${BLUE}[1/6] Creating directory structure...${NC}"
mkdir -p "$FRAMEWORK_ROOT"/{core,src,templates,docs,logs}
echo -e "${GREEN}✓ Directories created${NC}\n"

# Step 2: Deploy main.py
echo -e "${BLUE}[2/6] Deploying main entry point...${NC}"
copy_file "$CURRENT_DIR/main.py" "$FRAMEWORK_ROOT/main.py" "main.py"
chmod +x "$FRAMEWORK_ROOT/main.py" 2>/dev/null || true
echo ""

# Step 3: Deploy core modules
echo -e "${BLUE}[3/6] Deploying core modules...${NC}"
CORE_FILES=("config.py" "paths.py" "types.py" "packages.py" "logic.py")
CORE_COUNT=0

for file in "${CORE_FILES[@]}"; do
    if copy_file "$CURRENT_DIR/core/$file" "$FRAMEWORK_ROOT/core/$file" "core/$file"; then
        ((CORE_COUNT++))
    fi
done

if [[ $CORE_COUNT -eq ${#CORE_FILES[@]} ]]; then
    echo -e "${GREEN}✓ All core modules deployed ($CORE_COUNT/${#CORE_FILES[@]})${NC}\n"
else
    echo -e "${YELLOW}⚠ Partial deployment ($CORE_COUNT/${#CORE_FILES[@]} files)${NC}\n"
fi

# Step 4: Deploy src modules
echo -e "${BLUE}[4/6] Deploying source modules...${NC}"
SRC_FILES=("helpers.py" "handlers.py" "validators.py" "utils.py" "generate.py")
SRC_COUNT=0

for file in "${SRC_FILES[@]}"; do
    if copy_file "$CURRENT_DIR/src/$file" "$FRAMEWORK_ROOT/src/$file" "src/$file"; then
        ((SRC_COUNT++))
    fi
done

if [[ $SRC_COUNT -eq ${#SRC_FILES[@]} ]]; then
    echo -e "${GREEN}✓ All source modules deployed ($SRC_COUNT/${#SRC_FILES[@]})${NC}\n"
else
    echo -e "${YELLOW}⚠ Partial deployment ($SRC_COUNT/${#SRC_FILES[@]} files)${NC}\n"
fi

# Step 5: Create Python package markers
echo -e "${BLUE}[5/6] Creating Python package markers...${NC}"
touch "$FRAMEWORK_ROOT/__init__.py"
touch "$FRAMEWORK_ROOT/core/__init__.py"
touch "$FRAMEWORK_ROOT/src/__init__.py"
echo -e "${GREEN}✓ Package markers created${NC}\n"

# Step 6: Create optional config file
echo -e "${BLUE}[6/6] Creating configuration template...${NC}"

if [[ ! -f "$FRAMEWORK_ROOT/.frameworkrc" ]]; then
    cat > "$FRAMEWORK_ROOT/.frameworkrc" << 'EOF'
# AI Framework Configuration Override
# Uncomment and modify values to override defaults

# python_version: "3.11"
# cuda_version: "13.0"
# pytorch_version: "2.5.1"

# skip_cuda_check: false
# skip_pytorch_build: true
# jupyter_enable: true
# jupyter_port: 8888

# max_jobs: 4
# train_batch_size: 4
EOF
    echo -e "  ${GREEN}✓${NC} .frameworkrc template created"
else
    echo -e "  ${CYAN}ℹ${NC} .frameworkrc already exists (preserved)"
fi
echo ""

# Summary
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║                    ✅ DEPLOYMENT COMPLETE!                     ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo -e "${CYAN}Framework deployed to:${NC} $FRAMEWORK_ROOT"
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. cd $FRAMEWORK_ROOT"
echo -e "  2. python3 main.py ${YELLOW}# Interactive mode${NC}"
echo -e "  3. python3 main.py --force ${YELLOW}# No prompts${NC}"
echo -e "  4. python3 main.py --dry-run ${YELLOW}# Test run${NC}"
echo ""

# Verify deployment
echo -e "${BLUE}Deployment verification:${NC}"
REQUIRED_FILES=(
    "main.py"
    "core/config.py"
    "core/paths.py"
    "core/types.py"
    "core/packages.py"
    "core/logic.py"
    "src/helpers.py"
    "src/handlers.py"
    "src/validators.py"
    "src/utils.py"
    "src/generate.py"
)

MISSING_COUNT=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$FRAMEWORK_ROOT/$file" ]]; then
        echo -e "  ${RED}✗${NC} Missing: $file"
        ((MISSING_COUNT++))
    fi
done

if [[ $MISSING_COUNT -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All required files present${NC}"
else
    echo -e "  ${RED}✗ $MISSING_COUNT files missing${NC}"
    echo -e "\n${YELLOW}Warning: Deployment incomplete. Some files are missing.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 Ready to run setup!${NC}"