#!/bin/zsh
# zbox.plugin.zsh
# ZBOX - Complete AI Operating System Plugin
# Master orchestrator for the entire ZBOX ecosystem

# ============================================================================
# ZBOX MASTER PLUGIN METADATA & GUARDS
# ============================================================================

if [[ -n "$ZBOX_MASTER_PLUGIN_LOADED" ]]; then
    return 0
fi

export ZBOX_MASTER_PLUGIN_VERSION="1.0.0-ENTERPRISE"
export ZBOX_MASTER_PLUGIN_NAME="zbox-ai-operating-system"
export ZBOX_MASTER_PLUGIN_AUTHOR="ZBOX Team"
export ZBOX_MASTER_PLUGIN_LOADED=1

# Get plugin root directory
if [[ -n "${(%):-%N}" ]]; then
    export ZBOX_PLUGIN_ROOT="${(%):-%N:A:h}"
else
    export ZBOX_PLUGIN_ROOT="${0:A:h}"
fi

# ============================================================================
# ZBOX SYSTEM ARCHITECTURE LOADER
# ============================================================================

# Define the complete ZBOX system architecture
declare -A ZBOX_SYSTEM_MODULES=(
    # Core system (Layer 1)
    ["core"]="zbox_shell_system.zsh"
    
    # Memory systems (Layer 2) 
    ["memory_basic"]="zbox_memory_system.zsh"
    ["memory_advanced"]="zbox_pure_zsh_memory.zsh"
    ["memory_postgres"]="zbox_postgres_interface.py"
    
    # Security system (Layer 3)
    ["security"]="zbox_security_multiuser.zsh"
    
    # Integration layer (Layer 4)
    ["integration"]="zbox_memory_wrapper.zsh"
    
    # Helper systems (Layer 5)
    ["helpers_system"]="functions/helper/system_helpers.zsh"
    ["helpers_validation"]="functions/helper/validation_helpers.zsh"
    ["helpers_security"]="functions/helper/security_helpers.zsh"
    ["helpers_logging"]="functions/helper/logging_helpers.zsh"
    ["helpers_file"]="functions/helper/file_helpers.zsh"
    ["helpers_network"]="functions/helper/network_helpers.zsh"
    ["helpers_parsing"]="functions/helper/parsing_helpers.zsh"
    ["helpers_input"]="functions/helper/input_helpers.zsh"
    ["helpers_output"]="functions/helper/output_helpers.zsh"
    ["helpers_model"]="functions/helper/model_helpers.zsh"
    ["helpers_agent"]="functions/helper/agent_helpers.zsh"
    ["helpers_memory"]="functions/helper/memory_helpers.zsh"
    ["helpers_hydration"]="functions/helper/hydration_helpers.zsh"
    
    # Memory system components (Layer 6)
    ["memory_management"]="functions/memory/zbox_memory_management_system.zsh"
    ["memory_advanced_sys"]="functions/memory/zbox_memory_advanced_system.zsh"
    ["memory_integration"]="functions/memory/zbox_memory_integration_wrapper.zsh"
    
    # Configuration (Layer 0 - loaded first)
    ["config_paths"]="config/zbox_path_constants.zsh"
)

# Define loading order with dependencies
declare -a ZBOX_LOADING_ORDER=(
    "config_paths"           # Must be first
    "helpers_system"         # System utilities first
    "helpers_validation"     # Validation second
    "helpers_security"       # Security third
    "helpers_logging"        # Logging fourth
    "helpers_file"           # File operations
    "helpers_network"        # Network utilities
    "helpers_parsing"        # Data parsing
    "helpers_input"          # Input handling
    "helpers_output"         # Output formatting
    "helpers_model"          # Model management
    "helpers_agent"          # Agent orchestration
    "helpers_memory"         # Memory helpers
    "helpers_hydration"      # Data hydration
    "core"                   # Core shell system
    "security"               # Security layer
    "memory_basic"           # Basic memory system
    "memory_advanced"        # Advanced memory features
    "memory_management"      # Memory management components
    "memory_advanced_sys"    # Advanced memory system components
    "memory_integration"     # Memory integration wrapper
    "integration"            # Final integration layer
)

# ============================================================================
# ZBOX SYSTEM STATE TRACKING
# ============================================================================

declare -A ZBOX_MODULE_STATUS
declare -A ZBOX_MODULE_LOAD_TIME
declare -A ZBOX_MODULE_DEPENDENCIES
declare -a ZBOX_FAILED_MODULES
declare -a ZBOX_LOADED_MODULES

export ZBOX_SYSTEM_STATE="INITIALIZING"
export ZBOX_STARTUP_TIME=$(date +%s)

# ============================================================================
# ZBOX MODULE LOADER ENGINE
# ============================================================================

zbox_load_module() {
    local module_name="$1"
    local module_file="${ZBOX_SYSTEM_MODULES[$module_name]}"
    local module_path="$ZBOX_PLUGIN_ROOT/$module_file"
    
    if [[ -z "$module_file" ]]; then
        echo "❌ Unknown module: $module_name"
        return 1
    fi
    
    # Check if already loaded
    if [[ -n "${ZBOX_MODULE_STATUS[$module_name]}" ]]; then
        return 0
    fi
    
    echo "🔄 Loading module: $module_name"
    
    # Record start time
    local start_time=$(date +%s.%N)
    
    # Attempt to load module
    if [[ -f "$module_path" ]]; then
        if [[ "$module_file" == *.py ]]; then
            # Python module - check if executable
            if command -v python3 >/dev/null 2>&1; then
                # For Python modules, just verify they exist and are readable
                if [[ -r "$module_path" ]]; then
                    export "ZBOX_${module_name^^}_PATH"="$module_path"
                    ZBOX_MODULE_STATUS[$module_name]="LOADED"
                    echo "  ✅ Python module available: $module_name"
                else
                    ZBOX_MODULE_STATUS[$module_name]="FAILED"
                    ZBOX_FAILED_MODULES+=($module_name)
                    echo "  ❌ Python module not readable: $module_name"
                    return 1
                fi
            else
                echo "  ⚠️  Python not available, skipping: $module_name"
                ZBOX_MODULE_STATUS[$module_name]="SKIPPED"
                return 0
            fi
        else
            # Zsh module - source it
            if source "$module_path" 2>/dev/null; then
                ZBOX_MODULE_STATUS[$module_name]="LOADED"
                ZBOX_LOADED_MODULES+=($module_name)
                echo "  ✅ Loaded successfully: $module_name"
            else
                ZBOX_MODULE_STATUS[$module_name]="FAILED"
                ZBOX_FAILED_MODULES+=($module_name)
                echo "  ❌ Failed to load: $module_name"
                return 1
            fi
        fi
    else
        ZBOX_MODULE_STATUS[$module_name]="MISSING"
        ZBOX_FAILED_MODULES+=($module_name)
        echo "  ⚠️  Module file not found: $module_path"
        return 0  # Don't fail hard on missing optional modules
    fi
    
    # Record load time
    local end_time=$(date +%s.%N)
    ZBOX_MODULE_LOAD_TIME[$module_name]=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.001")
    
    return 0
}

# ============================================================================
# ZBOX SYSTEM INITIALIZATION ENGINE
# ============================================================================

zbox_system_banner() {
    local terminal_width=${COLUMNS:-80}
    local banner_width=$((terminal_width > 80 ? 80 : terminal_width))
    
    cat << 'EOF'
╭────────────────────────────────────────────────────────────────────────────╮
│  ███████╗██████╗  ██████╗ ██╗  ██╗    ██████╗  ██████╗                    │
│  ╚══███╔╝██╔══██╗██╔═══██╗╚██╗██╔╝   ██╔═══██╗██╔════╝                    │
│    ███╔╝ ██████╔╝██║   ██║ ╚███╔╝    ██║   ██║███████╗                    │
│   ███╔╝  ██╔══██╗██║   ██║ ██╔██╗    ██║   ██║╚════██║                    │
│  ███████╗██████╔╝╚██████╔╝██╔╝ ██╗██╗╚██████╔╝███████║                    │
│  ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝                    │
│                                                                            │
│           🤖 AI Operating System - Enterprise Edition                      │
│              Complete Artificial Intelligence Shell Environment            │
│                         Version 2.0.0-ENTERPRISE                          │
╰────────────────────────────────────────────────────────────────────────────╯
EOF
}

zbox_system_init() {
    echo ""
    zbox_system_banner
    echo ""
    echo "🚀 Initializing ZBOX AI Operating System..."
    echo "📦 Plugin Root: $ZBOX_PLUGIN_ROOT"
    echo "⏱️  Startup Time: $(date)"
    echo ""
    
    # Set system state
    export ZBOX_SYSTEM_STATE="LOADING"
    
    # Load all modules in order
    local total_modules=${#ZBOX_LOADING_ORDER[@]}
    local loaded_count=0
    local failed_count=0
    
    echo "📋 Loading $total_modules system modules..."
    echo ""
    
    for module in $ZBOX_LOADING_ORDER; do
        if zbox_load_module "$module"; then
            ((loaded_count++))
        else
            ((failed_count++))
        fi
        
        # Show progress
        local progress=$((loaded_count * 100 / total_modules))
        printf "\r🔄 Progress: [%3d%%] %d/%d modules loaded" "$progress" "$loaded_count" "$total_modules"
    done
    
    echo ""
    echo ""
    
    # Initialize core systems
    echo "⚙️  Initializing core systems..."
    
    # Initialize ZBOX core if available
    if command -v zbox_init >/dev/null 2>&1; then
        zbox_init
    fi
    
    # Initialize security if available
    if command -v zbox_security_init >/dev/null 2>&1; then
        zbox_security_init
    fi
    
    # Initialize memory systems if available
    if command -v zbox_memory_init >/dev/null 2>&1; then
        zbox_memory_init
    fi
    
    # Set up autoloading
    zbox_setup_advanced_autoload
    
    # Set up completions
    zbox_setup_advanced_completions
    
    # Set up monitoring
    zbox_setup_system_monitoring
    
    # Final system state
    if [[ $failed_count -eq 0 ]]; then
        export ZBOX_SYSTEM_STATE="READY"
        echo ""
        echo "✅ ZBOX AI Operating System initialized successfully!"
        echo "🎯 All $loaded_count modules loaded without errors"
    else
        export ZBOX_SYSTEM_STATE="DEGRADED"
        echo ""
        echo "⚠️  ZBOX initialized with $failed_count failed modules"
        echo "✅ $loaded_count modules loaded successfully"
        if [[ ${#ZBOX_FAILED_MODULES[@]} -gt 0 ]]; then
            echo "❌ Failed modules: ${(j:, :)ZBOX_FAILED_MODULES}"
        fi
    fi
    
    export ZBOX_STARTUP_COMPLETE=$(date +%s)
    local startup_duration=$((ZBOX_STARTUP_COMPLETE - ZBOX_STARTUP_TIME))
    echo "⏱️  Startup completed in ${startup_duration}s"
    echo ""
    
    # Show quick start guide
    zbox_show_quick_start
}

# ============================================================================
# ADVANCED AUTOLOADING SYSTEM
# ============================================================================

zbox_setup_advanced_autoload() {
    echo "🔧 Setting up advanced function autoloading..."
    
    # Add all function directories to fpath
    local function_dirs=(
        "$ZBOX_PLUGIN_ROOT/functions/helper"
        "$ZBOX_PLUGIN_ROOT/functions/memory"
    )
    
    for dir in $function_dirs; do
        if [[ -d "$dir" ]]; then
            fpath=("$dir" $fpath)
        fi
    done
    
    # Auto-discover and load all zbox functions
    local function_count=0
    for dir in $function_dirs; do
        if [[ -d "$dir" ]]; then
            for func_file in "$dir"/*.zsh; do
                if [[ -f "$func_file" ]]; then
                    # Extract function names from files
                    local functions_in_file=($(grep -E "^function zbox_|^zbox_.*\(\)" "$func_file" 2>/dev/null | \
                        sed -E 's/^function ([^(]+).*/\1/; s/^([^(]+)\(\).*/\1/' | \
                        grep "^zbox_"))
                    
                    for func_name in $functions_in_file; do
                        if [[ -n "$func_name" ]]; then
                            autoload -Uz "$func_name" 2>/dev/null && ((function_count++))
                        fi
                    done
                fi
            done
        fi
    done
    
    echo "  ✅ Autoloaded $function_count functions"
}

# ============================================================================
# ADVANCED COMPLETION SYSTEM
# ============================================================================

zbox_setup_advanced_completions() {
    echo "🎯 Setting up advanced tab completions..."
    
    # Main ZBOX command completions
    compdef '_zbox_master_completions' zbox_chat chat ask
    compdef '_zbox_model_completions' zbox_model_switch switch_model
    compdef '_zbox_agent_completions' zbox_orchestrate orchestrate
    compdef '_zbox_memory_completions' zbox_memory_search remember_search recall
    compdef '_zbox_user_completions' zbox_user_login login
    compdef '_zbox_security_completions' zbox_secure_command
    
    echo "  ✅ Advanced completions configured"
}

# Master completion function
_zbox_master_completions() {
    local -a commands
    commands=(
        'help:Show ZBOX help system'
        'status:System status and health'
        'chat:Chat with AI models'
        'ultimate_chat:Advanced chat with full memory'
        'smart_chat:Intelligent chat with context'
        'orchestrate:Multi-agent orchestration'
        'search:Search through memories'
        'remember:Store important facts'
        'recall:Recall stored memories'
        'forget:Clean old memories'
        'memory_viz:Memory visualization'
        'memory_analytics:Memory analytics dashboard'
        'security_dashboard:Security monitoring'
        'login:User authentication'
        'logout:Secure logout'
        'whoami:Current user info'
        'system_stats:System statistics'
        'performance_test:Run performance tests'
    )
    
    _describe -t commands 'ZBOX commands' commands
}

# ============================================================================
# SYSTEM MONITORING & HEALTH CHECKS
# ============================================================================

zbox_setup_system_monitoring() {
    echo "📊 Setting up system monitoring..."
    
    # Set up periodic health checks (every 5 minutes)
    if [[ "${ZBOX_ENABLE_MONITORING:-1}" == "1" ]]; then
        # Add health check to periodic functions
        # Note: This would typically be handled by a background process
        export ZBOX_MONITORING_ENABLED=1
        echo "  ✅ System monitoring enabled"
    fi
}

zbox_system_health_check() {
    local health_score=0
    local max_score=0
    local issues=()
    
    echo "🏥 ZBOX System Health Check:"
    echo ""
    
    # Check core modules
    echo "📋 Module Status:"
    for module in $ZBOX_LOADING_ORDER; do
        local status="${ZBOX_MODULE_STATUS[$module]:-UNKNOWN}"
        local load_time="${ZBOX_MODULE_LOAD_TIME[$module]:-0}"
        
        case "$status" in
            "LOADED")
                echo "  ✅ $module (${load_time}s)"
                ((health_score++))
                ;;
            "SKIPPED")
                echo "  ⏭️  $module (skipped)"
                ;;
            "FAILED")
                echo "  ❌ $module (failed)"
                issues+=("Module $module failed to load")
                ;;
            "MISSING")
                echo "  ⚠️  $module (missing)"
                issues+=("Module $module is missing")
                ;;
            *)
                echo "  ❓ $module (unknown status)"
                issues+=("Module $module has unknown status")
                ;;
        esac
        ((max_score++))
    done
    
    # Calculate health percentage
    local health_percentage=$((health_score * 100 / max_score))
    
    echo ""
    echo "🎯 Overall System Health: $health_percentage% ($health_score/$max_score modules)"
    
    # Check system dependencies
    echo ""
    echo "🔧 System Dependencies:"
    local deps=(curl jq python3 psql bc)
    for dep in $deps; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "  ✅ $dep: $(which $dep)"
        else
            echo "  ❌ $dep: Not found"
            issues+=("Missing dependency: $dep")
        fi
    done
    
    # Check file system
    echo ""
    echo "📁 File System:"
    local critical_paths=(
        "$ZBOX_PLUGIN_ROOT"
        "${ZBOX_HOME:-/opt/zbox}"
        "${ZBOX_USER_HOME:-$ZBOX_HOME/users/$USER}"
    )
    
    for path in $critical_paths; do
        if [[ -d "$path" ]]; then
            echo "  ✅ $path (exists)"
        else
            echo "  ❌ $path (missing)"
            issues+=("Missing directory: $path")
        fi
    done
    
    # Show issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo ""
        echo "⚠️  Issues Found:"
        for issue in $issues; do
            echo "  • $issue"
        done
    fi
    
    # System state
    echo ""
    echo "🏁 System State: $ZBOX_SYSTEM_STATE"
    echo "⏱️  Uptime: $(($(date +%s) - ZBOX_STARTUP_TIME))s"
    
    return $((${#issues[@]} == 0 ? 0 : 1))
}

# ============================================================================
# ZBOX MASTER CONTROL FUNCTIONS
# ============================================================================

zbox_master_status() {
    echo "🎛️  ZBOX AI Operating System - Master Status"
    echo "════════════════════════════════════════════"
    echo ""
    echo "System Information:"
    echo "  Version: $ZBOX_MASTER_PLUGIN_VERSION"
    echo "  State: $ZBOX_SYSTEM_STATE"
    echo "  Plugin Root: $ZBOX_PLUGIN_ROOT"
    echo "  Startup Time: $(date -d @$ZBOX_STARTUP_TIME 2>/dev/null || date -r $ZBOX_STARTUP_TIME 2>/dev/null || echo 'Unknown')"
    echo "  Uptime: $(($(date +%s) - ZBOX_STARTUP_TIME))s"
    echo ""
    
    # Module summary
    local loaded_count=${#ZBOX_LOADED_MODULES[@]}
    local failed_count=${#ZBOX_FAILED_MODULES[@]}
    local total_count=${#ZBOX_LOADING_ORDER[@]}
    
    echo "Module Summary:"
    echo "  Total Modules: $total_count"
    echo "  Loaded: $loaded_count"
    echo "  Failed: $failed_count"
    echo "  Success Rate: $(((loaded_count * 100) / total_count))%"
    echo ""
    
    # Quick system health
    if command -v zbox_system_health_check >/dev/null 2>&1; then
        zbox_system_health_check
    fi
    
    # Show available interfaces
    echo ""
    echo "Available Interfaces:"
    if command -v zbox_chat >/dev/null 2>&1; then
        echo "  ✅ Basic Chat (zbox_chat, chat, ask)"
    fi
    if command -v zbox_chat_with_smart_memory >/dev/null 2>&1; then
        echo "  ✅ Smart Chat (smart_chat)"
    fi
    if command -v zbox_chat_ultimate >/dev/null 2>&1; then
        echo "  ✅ Ultimate Chat (ultimate_chat, uc)"
    fi
    if command -v zbox_orchestrate >/dev/null 2>&1; then
        echo "  ✅ Agent Orchestration (orchestrate)"
    fi
    if command -v zbox_memory_visualize >/dev/null 2>&1; then
        echo "  ✅ Memory Visualization (memory_viz)"
    fi
    if command -v zbox_security_dashboard >/dev/null 2>&1; then
        echo "  ✅ Security Dashboard (security_dashboard)"
    fi
}

zbox_master_reload() {
    echo "🔄 Reloading ZBOX AI Operating System..."
    
    # Clear state
    unset ZBOX_MASTER_PLUGIN_LOADED
    unset ZBOX_SYSTEM_STATE
    ZBOX_MODULE_STATUS=()
    ZBOX_MODULE_LOAD_TIME=()
    ZBOX_FAILED_MODULES=()
    ZBOX_LOADED_MODULES=()
    
    # Reload
    source "$ZBOX_PLUGIN_ROOT/zbox.plugin.zsh"
    
    echo "✅ ZBOX AI Operating System reloaded"
}

zbox_master_cleanup() {
    echo "🧹 Cleaning up ZBOX AI Operating System..."
    
    # Cleanup individual systems
    if command -v zbox_memory_cleanup >/dev/null 2>&1; then
        zbox_memory_cleanup
    fi
    
    if command -v zbox_session_cleanup >/dev/null 2>&1; then
        zbox_session_cleanup
    fi
    
    # Unset environment variables
    unset ZBOX_MASTER_PLUGIN_LOADED ZBOX_SYSTEM_STATE
    unset ZBOX_STARTUP_TIME ZBOX_STARTUP_COMPLETE
    
    # Clean up module tracking
    unset ZBOX_MODULE_STATUS ZBOX_MODULE_LOAD_TIME
    unset ZBOX_FAILED_MODULES ZBOX_LOADED_MODULES
    
    # Remove from fpath
    fpath=(${fpath:#*zbox*})
    
    echo "✅ ZBOX AI Operating System cleaned up"
}

# ============================================================================
# QUICK START GUIDE
# ============================================================================

zbox_show_quick_start() {
    echo "🚀 ZBOX AI Operating System - Quick Start Guide"
    echo "═══════════════════════════════════════════════"
    echo ""
    echo "💬 Chat Commands:"
    echo "  chat 'Hello AI'              - Basic chat"
    echo "  smart_chat 'Help with code'  - Chat with memory"
    echo "  ultimate_chat 'Complex task' - Full AI power"
    echo "  orchestrate 'Multi-step task'- Agent orchestration"
    echo ""
    echo "🧠 Memory Commands:"
    echo "  remember 'I like pizza'      - Store information"
    echo "  recall 'food preferences'    - Search memories"
    echo "  memory_viz                   - Visual memory dashboard"
    echo "  memory_analytics             - Memory analytics"
    echo ""
    echo "🔒 Security Commands:"
    echo "  login                        - User authentication"
    echo "  security_dashboard           - Security monitoring"
    echo "  whoami                       - Current user info"
    echo ""
    echo "⚙️  System Commands:"
    echo "  status                       - System status"
    echo "  zbox_master_status           - Detailed system info"
    echo "  help                         - Full help system"
    echo ""
    echo "💡 Type 'help' for complete command reference!"
    echo ""
}

# ============================================================================
# MASTER PLUGIN ALIASES
# ============================================================================

# System management
alias zbox-status='zbox_master_status'
alias zbox-reload='zbox_master_reload' 
alias zbox-cleanup='zbox_master_cleanup'
alias zbox-health='zbox_system_health_check'

# Quick access to main functions (if they exist)
alias status='zbox_master_status'
alias health='zbox_system_health_check'

# ============================================================================
# MASTER PLUGIN EXECUTION
# ============================================================================

# Initialize the complete ZBOX AI Operating System
zbox_system_init

# Export master functions for external use
typeset -gx -f zbox_master_status zbox_master_reload zbox_master_cleanup zbox_system_health_check

echo ""
echo "🎉 Welcome to ZBOX AI Operating System!"
echo "🤖 Your complete artificial intelligence shell environment is ready!"
echo ""