#!/usr/bin/env zsh
#  ╔════════════════════════════════════╗
#?     zBox Architecture System (Zsh)  <===== [name: zBox, version: 001]
#  ╚════════════════════════════════════╝
#!     zBOX CORE ARCHITECTURE
# ================================

# zBox Architecture Paths
zBOX_ROOT="${zBOX_ROOT:=$HOME/.zbox}"
zBOX_CORE="$zBOX_ROOT/core"
zBOX_SOURCE="$zBOX_ROOT/source"
zBOX_CONFIGS="$zBOX_SOURCE/configs"
zBOX_TOOLS="$zBOX_SOURCE/tools" 
zBOX_UTILS="$zBOX_SOURCE/utils"

# Core system state
zBOX_LOADED=0
zBOX_INITIALIZED=0

# Create the core bootstrap system
create_bootstrap_system() {
    echo "⚡ Creating bootstrap system..."
    
    # Main Bootstrap
    cat > "$zBOX_CORE/zbox_bootstrap.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Core Bootstrap System
#! BOOTSTRAP - CORE SYSTEM INITIALIZATION
# =======================================

# zBox Bootstrap - First thing that runs
zbox_bootstrap() {
    local zbox_root="${zBOX_ROOT:=$HOME/.zbox}"
    
    # Verify architecture exists
    if [[ ! -d "$zbox_root/core" ]]; then
        echo "❌ zBox architecture not found. Run: zbox init"
        return 1
    fi
    
    # Load core configurations
    source "$zbox_root/core/zbox_loader.zsh"
    
    # Initialize system
    zbox_load_system
    
    echo "✅ zBox bootstrapped successfully"
}

# Auto-bootstrap if sourced
if [[ "${(%):-%N}" == */zbox_bootstrap.zsh ]]; then
    zbox_bootstrap
fi
EOF

    # System Loader
    cat > "$zBOX_CORE/zbox_loader.zsh" << 'EOF'
#!/usr/bin/env zsh  
#? zBox Core Loader System
#! LOADER - DYNAMIC SYSTEM LOADING
# ================================

# Load zBox system components
zbox_load_system() {
    local zbox_root="${zBOX_ROOT:-$HOME/.zbox}"
    
    echo "📦 Loading zBox system components..."
    
    # Load configurations in order
    source "$zbox_root/core/configs/zbox_config-defaults.zsh"
    source "$zbox_root/core/configs/zbox_config-dynamics.zsh" 
    source "$zbox_root/core/configs/zbox_config_enterprise.zsh"
    
    # Load settings
    for setting in "$zbox_root/source/settings"/*.zsh; do
        [[ -f "$setting" ]] && source "$setting"
    done
    
    # Load function library
    for func in "$zbox_root/source/functions"/*.zsh; do
        [[ -f "$func" ]] && source "$func"
    done
    
    # Load controllers (on-demand)
    export zBOX_CONTROLLERS="$zbox_root/source/controllers"
    
    echo "✅ zBox system loaded"
    export zBOX_LOADED=1
}

# Controller loader
zbox_load_controller() {
    local controller="$1"
    local controller_path="$zBOX_CONTROLLERS/$controller/${controller}.zsh"
    
    if [[ -f "$controller_path" ]]; then
        source "$controller_path"
        echo "✅ Controller loaded: $controller"
    else
        echo "❌ Controller not found: $controller"
        return 1
    fi
}
EOF

    # Setup Script
    cat > "$zBOX_CORE/zbox_setup.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Core Setup System  
#! SETUP - FIRST-TIME CONFIGURATION
# =================================

# First-time zBox setup
zbox_setup() {
    echo "🎯 zBox First-Time Setup"
    echo "========================"
    
    # Create user directories
    mkdir -p "$HOME/.zbox"/{data,logs,tmp,cache}
    mkdir -p "$HOME/.zbox/data"/{archives,backups,sources}
    
    # Set permissions
    chmod 700 "$HOME/.zbox"
    chmod 755 "$HOME/.zbox/data"
    
    # Create environment file
    cat > "$HOME/.zbox/.env" << 'ENVEOF'
# zBox Environment Configuration
zBOX_USER="$USER"
zBOX_HOME="$HOME/.zbox"
zBOX_INITIALIZED="$(date)"
ENVEOF
    
    # Add to shell profile
    local shell_rc=""
    case "$SHELL" in
        */zsh) shell_rc="$HOME/.zshrc" ;;
        */bash) shell_rc="$HOME/.bashrc" ;;
    esac
    
    if [[ -n "$shell_rc" && -f "$shell_rc" ]]; then
        if ! grep -q "zbox_bootstrap" "$shell_rc"; then
            echo "" >> "$shell_rc"
            echo "# zBox Auto-Bootstrap" >> "$shell_rc"
            echo "[ -f \"$HOME/.zbox/core/zbox_bootstrap.zsh\" ] && source \"$HOME/.zbox/core/zbox_bootstrap.zsh\"" >> "$shell_rc"
        fi
    fi
    
    echo "✅ zBox setup complete!"
    echo "   Restart your shell or run: source $shell_rc"
}

# Run setup if called directly
if [[ "${(%):-%N}" == */zbox_setup.zsh ]]; then
    zbox_setup
fi
EOF

    echo "✅ Bootstrap system created"
}

# Create configuration templates  
create_config_templates() {
    echo "⚙️  Creating configuration templates..."
    
    # Default Configuration
    cat > "$zBOX_CORE/configs/zbox_config-defaults.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Configuration - Defaults
#! CONFIGURATION - DEFAULT SETTINGS
# =================================

# Default zBox Configuration
export zBOX_VERSION="1.0.0"
export zBOX_ENV="development"
export zBOX_DEBUG=0
export zBOX_VERBOSE=0

# Path Configuration
export zBOX_DATA_DIR="$HOME/.zbox/data"
export zBOX_LOG_DIR="$HOME/.zbox/logs"  
export zBOX_TMP_DIR="$HOME/.zbox/tmp"
export zBOX_CACHE_DIR="$HOME/.zbox/cache"

# Archive & Backup Settings
export zBOX_ARCHIVE_DIR="$zBOX_DATA_DIR/archives"
export zBOX_BACKUP_DIR="$zBOX_DATA_DIR/backups"
export zBOX_SOURCE_DIR="$zBOX_DATA_DIR/sources"

# Compression Settings
export zBOX_COMPRESS_FORMAT="tar.gz"
export zBOX_COMPRESS_LEVEL="6"

# Logging Configuration
export zBOX_LOG_LEVEL="INFO"
export zBOX_LOG_FILE="$zBOX_LOG_DIR/zbox.log"
EOF

    # Dynamic Configuration
    cat > "$zBOX_CORE/configs/zbox_config-dynamics.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Configuration - Dynamics
#! CONFIGURATION - DYNAMIC SETTINGS  
# =================================

# Dynamic zBox Configuration
export zBOX_DYNAMIC_MODE=1
export zBOX_AUTO_UPDATE=1
export zBOX_LOAD_CONTROLLERS_ON_DEMAND=1

# Performance Settings
export zBOX_CACHE_SIZE="100M"
export zBOX_MAX_JOBS="4"
export zBOX_TIMEOUT="30"

# Development Settings
export zBOX_DEV_MODE=0
export zBOX_HOT_RELOAD=0
export zBOX_PROFILING=0

# Feature Flags
export zBOX_ENABLE_SSH=1
export zBOX_ENABLE_DOCKER=1
export zBOX_ENABLE_GITHUB=1
export zBOX_ENABLE_ENCRYPTION=1
EOF

    # Enterprise Configuration
    cat > "$zBOX_CORE/configs/zbox_config_enterprise.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Configuration - Enterprise
#! CONFIGURATION - ENTERPRISE SETTINGS
# ====================================

# Enterprise zBox Configuration
export zBOX_ENTERPRISE_MODE=0
export zBOX_AUDIT_LOGGING=0
export zBOX_COMPLIANCE_MODE=0

# Security Settings
export zBOX_TLS_ENABLED=1
export zBOX_TLS_MIN_VERSION="1.2"
export zBOX_CERT_VALIDATION="strict"

# Network Configuration
export zBOX_HTTP_PROXY=""
export zBOX_HTTPS_PROXY=""
export zBOX_NO_PROXY="localhost,127.0.0.1"
export zBOX_NETWORK_TIMEOUT="10"

# Enterprise Features
export zBOX_SSO_ENABLED=0
export zBOX_LDAP_ENABLED=0
export zBOX_VAULT_INTEGRATION=0
export zBOX_MONITORING_ENABLED=0
EOF

    echo "✅ Configuration templates created"
}

# Create controller templates
create_controller_templates() {
    echo "🎮 Creating controller templates..."
    
    # API Controller
    cat > "$zBOX_CONTROLLERS/apictr/apictr.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Controller - API
#! CONTROLLER - API MANAGEMENT
# ============================

# API Controller Functions
api_request() {
    local method="$1"
    local url="$2" 
    local data="$3"
    
    curl -X "$method" \
        -H "Content-Type: application/json" \
        -H "User-Agent: zBox/1.0" \
        ${data:+-d "$data"} \
        "$url"
}

api_get() { api_request "GET" "$1"; }
api_post() { api_request "POST" "$1" "$2"; }
api_put() { api_request "PUT" "$1" "$2"; }
api_delete() { api_request "DELETE" "$1"; }

echo "✅ API Controller loaded"
EOF

    cat > "$zBOX_CONTROLLERS/apictr/README.md" << 'EOF'
# API Controller

Handles API requests and responses for zBox.

## Functions:
- `api_get(url)` - GET request
- `api_post(url, data)` - POST request  
- `api_put(url, data)` - PUT request
- `api_delete(url)` - DELETE request
EOF

    # Environment Controller
    cat > "$zBOX_CONTROLLERS/envctr/envctr.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Controller - Environment
#! CONTROLLER - ENVIRONMENT MANAGEMENT  
# ===================================

# Environment Controller Functions
env_switch() {
    local env_name="$1"
    export zBOX_ENV="$env_name"
    echo "🔄 Switched to environment: $env_name"
}

env_list() {
    echo "Available environments:"
    echo "  • development"
    echo "  • staging" 
    echo "  • production"
    echo ""
    echo "Current: $zBOX_ENV"
}

env_export() {
    local var_name="$1"
    local var_value="$2"
    export "$var_name"="$var_value"
    echo "✅ Exported: $var_name=$var_value"
}

echo "✅ Environment Controller loaded"
EOF

    # Create other controller placeholders
    for controller in llamactr reactctr; do
        cat > "$zBOX_CONTROLLERS/$controller/${controller}.zsh" << EOF
#!/usr/bin/env zsh
#? zBox Controller - ${controller^}
#! CONTROLLER - ${controller^} MANAGEMENT
# $(printf '=%.0s' {1..35})

# ${controller^} Controller Functions
${controller}_init() {
    echo "🚀 ${controller^} controller initialized"
}

echo "✅ ${controller^} Controller loaded"
EOF

        cat > "$zBOX_CONTROLLERS/$controller/README.md" << EOF
# ${controller^} Controller

Manages ${controller} functionality for zBox.

## Functions:
- \`${controller}_init()\` - Initialize ${controller}
EOF
    done

    echo "✅ Controller templates created"
}

# Create function library (sample functions)
create_function_library() {
    echo "📚 Creating function library..."
    
    # Quick functions
    cat > "$zBOX_FUNCTIONS/quick.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Functions - Quick
# Quick utility functions

# Quick directory navigation
q() { cd "$zBOX_ROOT" && ls -la; }
qc() { cd "$zBOX_CORE" && ls -la; }
qs() { cd "$zBOX_SOURCE" && ls -la; }

# Quick status
qstat() {
    echo "zBox Status:"
    echo "  Root: $zBOX_ROOT"
    echo "  Loaded: $([ $zBOX_LOADED -eq 1 ] && echo '✅' || echo '❌')"
    echo "  Environment: $zBOX_ENV"
}
EOF

    # System functions
    cat > "$zBOX_FUNCTIONS/system.zsh" << 'EOF'
#!/usr/bin/env zsh
#? zBox Functions - System
# System utility functions

# System information
zsys_info() {
    echo "System Information:"
    echo "  OS: $(uname -s)"
    echo "  Shell: $SHELL"
    echo "  User: $USER"
    echo "  zBox Version: $zBOX_VERSION"
}

# System cleanup
zsys_clean() {
    echo "🧹 Cleaning zBox temporary files..."
    rm -rf "$zBOX_TMP_DIR"/*
    rm -rf "$zBOX_CACHE_DIR"/*
    echo "✅ Cleanup complete"
}
EOF

    # Create placeholders for other functions
    local functions=(archive backup docker encryption environment github history network plugin prompt scan search ssh view)
    
    for func in $functions; do
        cat > "$zBOX_FUNCTIONS/${func}.zsh" << EOF
#!/usr/bin/env zsh
#? zBox Functions - ${func^}
# ${func^} utility functions

# ${func^} main function
z${func}() {
    echo "🔧 ${func^} function placeholder"
    echo "   Implement your ${func} functionality here"
}
EOF
    done

    echo "✅ Function library created"
}

# Create settings templates
create_settings_templates() {
    echo "⚙️  Creating settings templates..."
    
    # Aliases
    cat > "$zBOX_SETTINGS/alias.zsh" << 'EOF'
#!/usr/bin/env zsh
#!  ╔═══════════════════════════════════════════╗
#?    Alias Settings - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Helper (aliases)
alias h='history | grep'
alias path='echo -e ${PATH//:/\\n}'
alias cls='clear'
alias rlsrc='source ~/.zshrc'
alias rlenv='source ~/.zshenv'
alias prettier="prettier --config ~/.prettierrc"
alias finder='ranger --choosedir=$HOME/.rangerdir; cd $(<~/.config/ranger/.rangerdir)'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# List (aliases)
if command -v exa >/dev/null 2>&1; then    
    alias l='exa --group-directories-first --color=auto'
    alias ls='exa --group-directories-first --color=auto'
    alias ll='exa --group-directories-first --color=auto -alF --git'
    alias la='exa --group-directories-first --color=auto -a'
    alias lt='exa --group-directories-first --color=auto -alT'
    alias lh='exa --group-directories-first --color=auto -lah'
    alias lt='exa --group-directories-first --color=autor -altr'
    alias lstree='exa --tree --level=3 --group-directories-first'
    alias lssize='exa --group-directories-first --color=auto -laSh'
fi

if command -v bat &> /dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catt='bat --style=full'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
    alias fgrep='rg -F'
    alias egrep='rg'
else
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Safety net (aliases)
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Network (aliases)
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias localip='ip route get 1 | awk '"'"'{print $NF;exit}'"'"''
alias publicip='dig +short myip.opendns.com @resolver1.opendns.com'
alias ips='ip addr show'
alias routes='ip route show'

# Process Management (aliases)
alias k='kill'
alias k9='kill -9'
alias killall='killall -v'

# Package Management (aliases)
if command -v pacman &> /dev/null; then
    alias pacsearch='pacman -Ss'
    alias pacinit='sudo pacman -S'
    alias pacrm='sudo pacman -R'
    alias pacup='sudo pacman -Syu'
    alias paclist='pacman -Qi'
    alias pacclean='sudo pacman -Rns $(pacman -Qtdq)'
fi

if command -v yay &> /dev/null; then
    alias y='yay'
    alias ys='yay -Ss'
    alias yi='yay -S'
    alias yr='yay -R'
    alias yu='yay -Syu'
fi

# Clock (aliases)
alias time='date +"%T"'
alias date='date +"%d-%m-%Y"'
alias week='date +%V'

# Fun (aliases)
alias weather='curl wttr.in'
alias cheat='curl cheat.sh/'
EOF

    # Exports
    cat > "$zBOX_SETTINGS/export.zsh" << 'EOF'
#  ╔════════════════════════════════════════════╗
#?   Export Settings - Environment Source (Zsh)  
#  ╚════════════════════════════════════════════╝

#!        Custom Exports
# ================================
export zBOX_LOADED_TIMESTAMP="$(date +%s)"

#!        System Exports
# ================================
export TERM="xterm-256color"
export COLORTERM="truecolor"

#!        Lang Exports
# ================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

#!        Editor Exports
# ================================
export EDITOR="nano"
export VISUAL="$EDITOR"

#!        Pager Exports
# ================================
export PAGER="less"
export LESS="-R"

#!        Browser Exports
# ================================
export BROWSER="firefox"

#!        Secure Exports
# ================================
export GPG_TTY="$(tty)"
export gpgconf --launch gpg-agent 2>/dev/null
EOF

    # Create other settings placeholders
    local settings=(global optimization output)
    
    for setting in $settings; do
        cat > "$zBOX_SETTINGS/${setting}.zsh" << EOF
#!/usr/bin/env zsh
#? zBox Settings - ${setting^}
# ${setting^} configuration

# ${setting^} settings placeholder
echo "⚙️  ${setting^} settings loaded"
EOF
    done

    echo "✅ Settings templates created"
}

# Initialize the complete zBox architecture
init_zbox_architecture() {
    echo "🏗️  Initializing zBox Architecture..."
    
    # Create the complete directory structure
    mkdir -p "$zBOX_CORE"/{configs,}
    mkdir -p "$zBOX_SOURCE"/{controllers,functions,settings}
    mkdir -p "$zBOX_CONTROLLERS"/{apictr,envctr,llamactr,reactctr}
    
    echo "✅ Directory structure created"
    
    # Create core bootstrap system
    create_bootstrap_system
    
    # Create configuration templates
    create_config_templates
    
    # Create controller templates
    create_controller_templates
    
    # Create function library
    create_function_library
    
    # Create settings templates
    create_settings_templates
    
    echo "🚀 zBox Architecture initialized at: $zBOX_ROOT"
}

# Main zBox command interface
zbox_command() {
    case "$1" in
        "init")
            init_zbox_architecture
            ;;
        "load")
            shift
            zbox_load_controller "$@"
            ;;
        "bootstrap")
            source "$zBOX_CORE/zbox_bootstrap.zsh"
            ;;
        "setup")
            source "$zBOX_CORE/zbox_setup.zsh"
            ;;
        "status"|"stat")
            qstat 2>/dev/null || echo "zBox not loaded. Run: zbox bootstrap"
            ;;
        "help"|*)
            echo "zBox Architecture System"
            echo "========================"
            echo "Commands:"
            echo "  init      - Initialize complete zBox architecture"
            echo "  bootstrap - Bootstrap zBox system"
            echo "  setup     - First-time setup"
            echo "  load <ctrl> - Load a specific controller"
            echo "  status    - Show system status"
            echo ""
            echo "Controllers: apictr, envctr, llamactr, reactctr"
            ;;
    esac
}

# Export the main command
alias zbox='zbox_command'

# Auto-initialize if this is the first run
if [[ ! -d "$zBOX_ROOT" ]]; then
    echo "🚀 zBox not found. Initialize with: zbox init"
fi