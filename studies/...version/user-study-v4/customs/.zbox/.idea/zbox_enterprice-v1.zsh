#!/usr/bin/env zsh
#  ╔══════════════════════════════╗
#? ║   ZBox Enterprise System     ║
#  ╚══════════════════════════════╝
#!     CORE SYSTEM ARCHITECTURE
# ================================

# Z-Namespace Controller
ZBOX_ROOT="${HOME}/.zbox"
ZBIN_ROOT="${ZBOX_ROOT}/zbin"
ZLIB_ROOT="${ZBOX_ROOT}/zlib" 
ZENV_ROOT="${ZBOX_ROOT}/zenv"

# Header-based routing patterns
declare -A HEADER_ROUTES=(
    ["ZBox Configurations"]="$ZENV_ROOT/configs"
    ["ZBox Library"]="$ZLIB_ROOT"
    ["ZBox Binary"]="$ZBIN_ROOT" 
    ["ZBox Proxy"]="$ZENV_ROOT/proxy"
    ["ZBox Network"]="$ZENV_ROOT/network"
    ["ZBox Security"]="$ZENV_ROOT/security"
    ["ZBox Enterprise"]="$ZENV_ROOT/enterprise"
)

# Initialize Z-System
init_zsystem() {
    echo "🚀 Initializing Z-System Architecture..."
    
    # Create Z-namespace directories
    mkdir -p "$ZBOX_ROOT" "$ZBIN_ROOT" "$ZLIB_ROOT" "$ZENV_ROOT"
    mkdir -p "$ZENV_ROOT"/{configs,proxy,network,security,enterprise}
    
    # Create namespace markers
    echo "ZBOX_NAMESPACE=active" > "$ZBOX_ROOT/.zbox_active"
    echo "# ZBox Enterprise Environment" > "$ZENV_ROOT/.zenv"
    echo "# ZBox Binary Space" > "$ZBIN_ROOT/.zbin"  
    echo "# ZBox Library Collection" > "$ZLIB_ROOT/.zlib"
    
    echo "✅ Z-System initialized at $ZBOX_ROOT"
}

# The "Catcher" - Header-reading file router
route_by_header() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "❌ File not found: $file"
        return 1
    fi
    
    echo "📖 Reading header from: $(basename "$file")"
    
    # Read first 10 lines to find header pattern
    local header_content=$(head -10 "$file" | grep -E '^#\?' | head -1)
    
    if [[ -z "$header_content" ]]; then
        echo "⚠️  No header found - treating as generic ZSH"
        return 1
    fi
    
    # Extract the header type
    local header_type=$(echo "$header_content" | sed 's/^#\?[[:space:]]*//' | sed 's/[[:space:]]*-.*$//')
    
    echo "🔍 Detected header: '$header_type'"
    
    # Find matching route
    local target_dir=""
    for pattern in "${(@k)HEADER_ROUTES}"; do
        if [[ "$header_type" == *"$pattern"* ]]; then
            target_dir="${HEADER_ROUTES[$pattern]}"
            break
        fi
    done
    
    if [[ -n "$target_dir" ]]; then
        echo "📂 Routing to: $target_dir"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/$(basename "$file")"
        echo "✅ File routed successfully"
        return 0
    else
        echo "❓ Unknown header type - routing to generic configs"
        mkdir -p "$ZENV_ROOT/configs"
        cp "$file" "$ZENV_ROOT/configs/$(basename "$file")"
        return 0
    fi
}

# Z-Prefix Controller (your namespace idea)
activate_z_namespace() {
    local mode="${1:-on}"
    
    if [[ "$mode" == "on" ]]; then
        echo "🟢 Activating Z-Namespace..."
        
        # Add Z-prefixes to make ZBox "see" everything
        export ZBOX_ACTIVE=1
        export PATH="$ZBIN_ROOT:$PATH"
        
        # Load all Z-configurations
        for config_file in "$ZENV_ROOT"/configs/*.{zsh,sh} 2>/dev/null; do
            [[ -f "$config_file" ]] && source "$config_file"
        done
        
        echo "✅ Z-Namespace active - ZBox can see everything"
        
    elif [[ "$mode" == "off" ]]; then
        echo "🔴 Deactivating Z-Namespace..."
        
        # Remove Z-prefixes - now it's just 'box', 'bin', 'lib'
        unset ZBOX_ACTIVE
        export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$ZBIN_ROOT" | tr '\n' ':' | sed 's/:$//')
        
        echo "👤 Z-Namespace inactive - Pure ZSH mode"
    fi
}

# Enterprise-grade configuration templates
create_enterprise_config() {
    local config_type="$1"
    
    case "$config_type" in
        "proxy")
            cat > "$ZENV_ROOT/enterprise/proxy_config.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Proxy Configuration
#! PROXY SETTINGS - ENTERPRISE GRADE
# ===================================
export HTTP_PROXY="http://enterprise-proxy:8080"
export HTTPS_PROXY="https://enterprise-proxy:8443"
export NO_PROXY="localhost,127.0.0.1,*.internal.corp"
export PROXY_AUTH_METHOD="NTLM"
export PROXY_TIMEOUT="30"
EOF
            echo "✅ Enterprise proxy config created"
            ;;
            
        "network")
            cat > "$ZENV_ROOT/enterprise/network_config.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Network Configuration  
#! NETWORK SETTINGS - ENTERPRISE GRADE
# ====================================
export NETWORK_INTERFACE="eth0"
export DNS_PRIMARY="8.8.8.8"
export DNS_SECONDARY="8.8.4.4"
export NETWORK_TIMEOUT="10"
export MAX_CONNECTIONS="1000"
export KEEPALIVE_TIMEOUT="60"
EOF
            echo "✅ Enterprise network config created"
            ;;
            
        "security")
            cat > "$ZENV_ROOT/enterprise/security_config.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Security Configuration
#! SECURITY SETTINGS - ENTERPRISE GRADE  
# ======================================
export TLS_MIN_VERSION="1.2"
export CIPHER_SUITE="ECDHE-RSA-AES256-GCM-SHA384"
export CERT_VALIDATION="strict"
export SESSION_TIMEOUT="3600"
export MAX_LOGIN_ATTEMPTS="3"
export AUDIT_LOGGING="enabled"
EOF
            echo "✅ Enterprise security config created"
            ;;
            
        "routing")
            cat > "$ZENV_ROOT/enterprise/routing_config.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Enterprise Routing Configuration
#! ROUTING SETTINGS - ENTERPRISE GRADE
# ====================================
export DEFAULT_GATEWAY="192.168.1.1"
export ROUTING_TABLE="main"
export LOAD_BALANCER="round-robin"
export FAILOVER_TIMEOUT="5"
export HEALTH_CHECK_INTERVAL="30"
export ROUTE_METRIC="100"
EOF
            echo "✅ Enterprise routing config created"
            ;;
            
        *)
            echo "❓ Available enterprise configs: proxy, network, security, routing"
            ;;
    esac
}

# Simple ZBox library functions (your "simplest libraries")
create_zlib_essentials() {
    echo "📚 Creating essential ZBox libraries..."
    
    # Logging library
    cat > "$ZLIB_ROOT/logging.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Library - Logging
zlog() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

zlog_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

zlog_debug() {
    [[ -n "$ZBOX_DEBUG" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*"
}
EOF

    # Network utilities
    cat > "$ZLIB_ROOT/network.zsh" << 'EOF'
#!/usr/bin/env zsh  
#? ZBox Library - Network
zping() {
    ping -c 1 -W 1 "$1" &>/dev/null && echo "✅ $1" || echo "❌ $1"
}

zport() {
    nc -zv "$1" "$2" 2>&1 | grep -q "succeeded" && echo "✅ $1:$2" || echo "❌ $1:$2"
}

zcheck_proxy() {
    curl -x "$HTTP_PROXY" -I http://google.com &>/dev/null && echo "✅ Proxy OK" || echo "❌ Proxy failed"
}
EOF

    # File utilities  
    cat > "$ZLIB_ROOT/files.zsh" << 'EOF'
#!/usr/bin/env zsh
#? ZBox Library - Files
zbackup() {
    local file="$1"
    local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_name" && echo "✅ Backed up to: $backup_name"
}

zclean() {
    find . -name "*.tmp" -o -name "*.log" -o -name "*.bak" | head -10
    read "?Delete these files? (y/N): " response
    [[ "$response" =~ ^[Yy] ]] && find . -name "*.tmp" -o -name "*.log" -o -name "*.bak" -delete
}
EOF

    echo "✅ Essential ZBox libraries created"
}

# Status and info
zbox_info() {
    echo "╔════════════════════════════════════╗"
    echo "║        ZBox Enterprise System      ║"
    echo "╠════════════════════════════════════╣"
    echo "║ Z-Namespace: $([ -n "$ZBOX_ACTIVE" ] && echo '🟢 ACTIVE' || echo '⚪ INACTIVE')            ║"
    echo "║ Root Path:   $ZBOX_ROOT"
    echo "║ Configs:     $(ls "$ZENV_ROOT"/configs/*.{zsh,sh} 2>/dev/null | wc -l) files              ║"
    echo "║ Libraries:   $(ls "$ZLIB_ROOT"/*.zsh 2>/dev/null | wc -l) files              ║"
    echo "╚════════════════════════════════════╝"
}

# Main command dispatcher
case "${1:-info}" in
    "init")
        init_zsystem
        create_zlib_essentials
        ;;
    "route")
        shift
        for file in "$@"; do
            route_by_header "$file"
        done
        ;;
    "namespace")
        activate_z_namespace "$2"
        ;;
    "enterprise")
        create_enterprise_config "$2"
        ;;
    "libs"|"libraries")
        create_zlib_essentials
        ;;
    "info"|*)
        zbox_info
        ;;
esac

# Auto-activate if Z-namespace marker exists
[[ -f "$ZBOX_ROOT/.zbox_active" && -z "$ZBOX_ACTIVE" ]] && activate_z_namespace on