#!/bin/bash
set -e

# OpenVINO Symlink Script
# Creates symlinks to OpenVINO runtime in project root

echo "🔗 Creating OpenVINO symlinks in project root"
echo "============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# OpenVINO source paths - ACTUAL structure
OPENVINO_ROOT="/usr/local/runtime"
PROJECT_ROOT="$(pwd)"

# Verify we're in project root
if [ ! -f "Cargo.toml" ]; then
    log_error "Not in project root! Run this script from openvino-controller directory"
    exit 1
fi

log_info "Project root: $PROJECT_ROOT"
log_info "OpenVINO root: $OPENVINO_ROOT"

# Create openvino directory in project root
mkdir -p openvino

# Function to create symlink safely
create_symlink() {
    local source=$1rm
    local target=$2
    local name=$3

    if [ ! -e "$source" ]; then
        log_warning "$name not found at $source - skipping"
        return 1
    fi

    # Remove existing link/directory
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -rf "$target"
    fi

    # Create symlink
    ln -sf "$source" "$target"
    log_success "$name -> $target"
    return 0
}

echo ""
log_info "Creating include directories..."

# Include directories (ACTUAL paths)
create_symlink "$OPENVINO_ROOT/runtime/bin" "openvino/bin" "OpenVINO Binaries"
create_symlink "$OPENVINO_ROOT/runtime/include" "openvino/include" "OpenVINO Headers"
create_symlink "$OPENVINO_ROOT/runtime/3rdparty" "openvino/3rdparty" "3rd Party Libraries"

echo ""
log_info "Creating library directories..."

# Library directories (ACTUAL paths)
create_symlink "$OPENVINO_ROOT/runtime/lib/intel64" "openvino/lib" "OpenVINO Libraries"

echo ""
log_info "Creating tools and executables..."

# Tools (ACTUAL paths)
create_symlink "$OPENVINO_ROOT/setupvars.sh" "openvino/setupvars.sh" "Environment Setup"

echo ""
log_info "Creating optional references..."

# Optional samples and deps
create_symlink "$OPENVINO_ROOT/samples" "openvino/samples" "Sample Code"
create_symlink "$OPENVINO_ROOT/licenses" "openvino/licenses" "Licenses"
create_symlink "$OPENVINO_ROOT/install_dependencies" "openvino/install_dependencies" "Install Dependencies"

# Create a convenience script to source environment
cat > setup_env.sh << 'EOF'
#!/bin/bash
# OpenVINO Environment Setup (Project Local)

PROJECT_ROOT="$(pwd)"

export OPENVINO_ROOT="$PROJECT_ROOT/openvino"
export OPENVINO_BIN="$OPENVINO_ROOT/bin"
export OPENVINO_LIB="$OPENVINO_ROOT/lib"
export OPENVINO_INC="$OPENVINO_ROOT/include"
export LD_LIBRARY="$OPENVINO_LIB:$LD_LIBRARY"

# Add TBB if it exists
if [ -d "$OPENVINO_ROOT/3rdparty/tbb/lib" ]; then
    export LD_LIBRARY_PATH="$OPENVINO_ROOT/3rdparty/tbb/lib:$LD_LIBRARY_PATH"
fi

echo "🔧 OpenVINO environment configured for project"
echo "   Binaries: $OPENVINO_BIN"
echo "   Libraries: $OPENVINO_LIB"
echo "   Headers: $OPENVINO_INC"
EOF

chmod +x setup_env.sh

# Verify symlinks
echo ""
log_info "Verifying symlinks..."

critical_files=(
    "openvino/bin/compile_tool"
    "openvino/bin/benchmark_app"
    "openvino/lib/libopenvino.so"
    "openvino/lib/libopenvino_c.so"
    "openvino/include/openvino"
)

all_good=true
for file in "${critical_files[@]}"; do
    if [ -e "$file" ]; then
        log_success "$file ✓"
    else
        log_error "$file ✗"
        all_good=false
    fi
done

echo ""
if $all_good; then
    log_success "🎉 All OpenVINO symlinks created successfully!"
    echo ""
    log_info "Project structure now:"
    echo "openvino-controller/"
    echo "├── openvino/"
    echo "│   ├── lib/           # OpenVINO libraries"
    echo "│   ├── tbb_lib/       # TBB libraries"
    echo "│   ├── include/       # OpenVINO headers"
    echo "│   ├── tbb_include/   # TBB headers"
    echo "│   ├── bin/           # Tools (benchmark_app, etc.)"
    echo "│   ├── compile_tool/  # Model compilation"
    echo "│   ├── samples/       # Reference code"
    echo "│   └── setup_env.sh   # Environment setup"
    echo "├── src/"
    echo "├── Cargo.toml"
    echo "└── ..."
    echo ""
    log_info "To build with local OpenVINO:"
    echo "  source openvino/setup_env.sh"
    echo "  cargo build --release"
    echo ""
    log_info "To test OpenVINO:"
    echo "  ./openvino/bin/benchmark_app --help"

else
    log_error "Some symlinks failed. Check OpenVINO installation."
    exit 1
fi
