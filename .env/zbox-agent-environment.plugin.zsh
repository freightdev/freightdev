#!/bin/zsh
# zbox.plugin.zsh
# ZBOX - Custom AI Shell Environment Plugin
# Your own shell that people log into to interact with your models

# ============================================================================
# PLUGIN GUARD & METADATA
# ============================================================================

# Prevent multiple loads
if [[ -n "$ZBOX_PLUGIN_LOADED" ]]; then
    return 0
fi

# Plugin metadata
export ZBOX_PLUGIN_VERSION="1.0.0"
export ZBOX_PLUGIN_AUTHOR="Your Name"
export ZBOX_PLUGIN_LOADED=1

# Get plugin directory
if [[ -n "${(%):-%N}" ]]; then
    ZBOX_PLUGIN_DIR="${(%):-%N:A:h}"
else
    ZBOX_PLUGIN_DIR="${0:A:h}"
fi

# ============================================================================
# ZBOX CORE SYSTEM
# ============================================================================

export ZBOX_VERSION="1.0.0"
export ZBOX_HOME="${ZBOX_HOME:-/opt/zbox}"
export ZBOX_USER_HOME="$ZBOX_HOME/users/$USER"
export ZBOX_MODELS_PATH="$ZBOX_HOME/models"
export ZBOX_SCRIPTS_PATH="$ZBOX_HOME/scripts"
export ZBOX_LOGS_PATH="$ZBOX_HOME/logs"

# Add ZBOX binaries to PATH
export PATH="$ZBOX_HOME/bin:$PATH"

# ============================================================================
# ZBOX INITIALIZATION FUNCTION
# ============================================================================

function zbox_init() {
    echo "🚀 Initializing ZBOX Environment..."
    
    # Create directory structure
    mkdir -p "$ZBOX_USER_HOME"/{context,history,keys,models,scripts,temp}
    mkdir -p "$ZBOX_LOGS_PATH"
    mkdir -p "$ZBOX_MODELS_PATH"
    
    # Set up user session
    export ZBOX_SESSION_ID="zbox_$(date +%s)_$RANDOM"
    export ZBOX_API_KEY="$(zbox_generate_key)"
    
    # Initialize user context
    echo "{\"session_id\":\"$ZBOX_SESSION_ID\",\"user\":\"$USER\",\"started\":\"$(date -Iseconds)\"}" > "$ZBOX_USER_HOME/context/session.json"
    
    # Load user environment
    [[ -f "$ZBOX_USER_HOME/.zboxrc" ]] && source "$ZBOX_USER_HOME/.zboxrc"
    
    echo "✅ ZBOX initialized for user: $USER"
    echo "📦 Session ID: $ZBOX_SESSION_ID"
}

# Generate API key for user session
function zbox_generate_key() {
    if command -v openssl >/dev/null 2>&1; then
        echo "zbox_${USER}_$(date +%s)_$(openssl rand -hex 8)"
    else
        # Fallback if openssl isn't available
        echo "zbox_${USER}_$(date +%s)_$(od -An -N4 -tx4 < /dev/urandom | tr -d ' ')"
    fi
}

# ============================================================================
# ZBOX MODEL INTERFACE
# ============================================================================

function zbox_chat() {
    local prompt="$*"
    local model_type="${ZBOX_MODEL:-primary}"
    local context_file="$ZBOX_USER_HOME/context/current.json"
    
    if [[ -z "$prompt" ]]; then
        echo "💬 Usage: zbox_chat <your message>"
        return 1
    fi
    
    echo "🤖 Processing with model: $model_type..."
    
    # Log the interaction
    echo "[$(date -Iseconds)] User: $USER | Model: $model_type | Prompt: $prompt" >> "$ZBOX_LOGS_PATH/interactions.log"
    
    # Prepare context
    local context="{\"user\":\"$USER\",\"session\":\"$ZBOX_SESSION_ID\",\"model\":\"$model_type\",\"timestamp\":\"$(date -Iseconds)\"}"
    
    # Check if Rust binary exists
    if [[ ! -x "$ZBOX_HOME/bin/rust_llama_binary" ]]; then
        echo "❌ ZBOX Rust binary not found at $ZBOX_HOME/bin/rust_llama_binary"
        echo "💡 Make sure ZBOX is properly installed"
        return 1
    fi
    
    # Call your Rust FFI binary with ZBOX environment
    local response
    response=$(ZBOX_SESSION="$ZBOX_SESSION_ID" \
                ZBOX_USER="$USER" \
                ZBOX_API_KEY="$ZBOX_API_KEY" \
                "$ZBOX_HOME/bin/rust_llama_binary" \
                --prompt "$prompt" \
                --context "$context" \
                --session "$ZBOX_SESSION_ID" \
                --user "$USER" \
                --output-format "zbox" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        # Format and display response
        zbox_format_response "$response"
        
        # Save to history
        echo "$prompt" >> "$ZBOX_USER_HOME/history/prompts.log"
        echo "$response" >> "$ZBOX_USER_HOME/history/responses.log"
        
        return 0
    else
        echo "❌ Model interaction failed"
        echo "💡 Check that your Rust binary is working: $ZBOX_HOME/bin/rust_llama_binary"
        return 1
    fi
}

# Format model responses for ZBOX display
function zbox_format_response() {
    local response="$1"
    local terminal_width=${COLUMNS:-80}
    local box_width=$((terminal_width - 4))
    
    # Ensure minimum width
    [[ $box_width -lt 40 ]] && box_width=40
    
    echo ""
    printf "╭"
    printf "─%.0s" {1..$box_width}
    printf "╮\n"
    
    printf "│  🤖 ZBOX AI Response"
    printf " %.0s" {1..$((box_width - 18))}
    printf "│\n"
    
    printf "├"
    printf "─%.0s" {1..$box_width}
    printf "┤\n"
    
    # Pretty print the response with word wrapping
    echo "$response" | fold -s -w $((box_width - 4)) | while IFS= read -r line; do
        printf "│  %-*s│\n" $((box_width - 4)) "$line"
    done
    
    printf "├"
    printf "─%.0s" {1..$box_width}
    printf "┤\n"
    
    local session_short="${ZBOX_SESSION_ID:0:12}..."
    local timestamp="$(date '+%H:%M:%S')"
    local status_line="Session: $session_short | User: $USER | $timestamp"
    
    printf "│  %-*s│\n" $((box_width - 4)) "$status_line"
    
    printf "╰"
    printf "─%.0s" {1..$box_width}
    printf "╯\n"
    echo ""
}

# ============================================================================
# ZBOX AGENT ORCHESTRATION
# ============================================================================

function zbox_orchestrate() {
    local task="$*"
    local agents=("${(@s/,/)ZBOX_AGENTS:-primary,secondary,web_search}")
    
    echo "🎯 Orchestrating task through agent hierarchy..."
    echo "📋 Agents: ${(j:, :)agents}"
    echo ""
    
    for agent in $agents; do
        echo "🔄 Trying agent: $agent"
        
        # Call agent with ZBOX environment
        local result
        result=$(zbox_call_agent "$agent" "$task")
        
        if [[ $? -eq 0 && -n "$result" ]]; then
            echo "✅ Success with agent: $agent"
            return 0
        else
            echo "❌ Agent $agent failed, trying next..."
        fi
    done
    
    echo "💀 All agents failed to complete the task"
    return 1
}

function zbox_call_agent() {
    local agent="$1"
    local task="$2"
    
    # Route to different endpoints based on agent
    case "$agent" in
        "primary")
            zbox_chat "$task"
            ;;
        "secondary") 
            ZBOX_MODEL="secondary" zbox_chat "$task"
            ;;
        "web_search")
            zbox_web_search "$task"
            ;;
        "code")
            zbox_code_assistant "$task"
            ;;
        *)
            echo "Unknown agent: $agent"
            return 1
            ;;
    esac
}

# ============================================================================
# ZBOX SPECIALIZED FUNCTIONS
# ============================================================================

function zbox_web_search() {
    local query="$*"
    echo "🔍 Searching web for: $query"
    
    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ curl not found - web search unavailable"
        return 1
    fi
    
    # Your web search implementation
    local result
    result=$(curl -s "http://localhost:8003/search" \
        -H "Authorization: Bearer $ZBOX_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"$query\",\"user\":\"$USER\",\"session\":\"$ZBOX_SESSION_ID\"}" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$result" ]]; then
        if command -v jq >/dev/null 2>&1; then
            echo "$result" | jq -r '.response // "Search failed"'
        else
            echo "$result"
        fi
    else
        echo "❌ Web search service unavailable"
        return 1
    fi
}

function zbox_code_assistant() {
    local code_request="$*"
    echo "💻 Code assistance for: $code_request"
    
    # Call specialized code model
    ZBOX_MODEL="code" zbox_chat "Code assistance: $code_request"
}

# ============================================================================
# ZBOX USER INTERFACE & PROMPT
# ============================================================================

function zbox_prompt() {
    local user_color="%F{cyan}"
    local session_color="%F{yellow}" 
    local model_color="%F{green}"
    local reset="%f"
    
    # Only set if not already customized
    if [[ -z "$ZBOX_CUSTOM_PROMPT" ]]; then
        PROMPT="${user_color}┌─[ZBOX]─[${USER}]─[${ZBOX_SESSION_ID:0:8}]${reset}
${user_color}└─▶${reset} "
        
        # Right side prompt with model info
        RPROMPT="${model_color}[${ZBOX_MODEL:-primary}]${reset} ${session_color}$(date '+%H:%M')${reset}"
    fi
}

# ============================================================================
# ZBOX HELP & STATUS FUNCTIONS
# ============================================================================

function zbox_help() {
    local width=${COLUMNS:-80}
    local box_width=$((width > 80 ? 80 : width))
    
    cat << EOF
╭─────────────────────────────────────────────╮
│            🚀 ZBOX HELP SYSTEM              │
├─────────────────────────────────────────────┤
│                                             │
│  💬 Chat Commands:                          │
│    zbox_chat <message>    - Chat with AI    │
│    chat <message>         - Alias           │
│    ask <message>          - Alias           │
│    orchestrate <task>     - Use agents      │
│                                             │
│  🔍 Search & Tools:                         │
│    search <query>         - Web search      │
│    code <request>         - Code assistant  │
│                                             │
│  ⚙️  System Commands:                       │
│    status                 - System status   │
│    history                - Chat history    │
│    zbox_models            - Available models│
│    zbox_config            - Configuration   │
│                                             │
│  🔑 Session Management:                     │
│    zbox_session           - Session info    │
│    zbox_reset             - Reset session   │
│    zbox_export_env        - Export env vars │
│                                             │
╰─────────────────────────────────────────────╯
EOF
}

function zbox_status() {
    echo "📊 ZBOX System Status:"
    echo "  User: $USER"
    echo "  Session: $ZBOX_SESSION_ID"
    echo "  Model: ${ZBOX_MODEL:-primary}"
    echo "  API Key: ${ZBOX_API_KEY:0:16}..."
    echo "  Home: $ZBOX_USER_HOME"
    echo "  Plugin Dir: $ZBOX_PLUGIN_DIR"
    echo ""
    echo "🔧 Component Status:"
    echo "  Rust Binary: $(test -x "$ZBOX_HOME/bin/rust_llama_binary" && echo '✅ Found' || echo '❌ Missing')"
    echo "  Models Dir: $(test -d "$ZBOX_MODELS_PATH" && echo '✅ Found' || echo '❌ Missing')"
    echo "  User Context: $(test -f "$ZBOX_USER_HOME/context/session.json" && echo '✅ Found' || echo '❌ Missing')"
    echo "  Dependencies:"
    echo "    - curl: $(command -v curl >/dev/null && echo '✅' || echo '❌')"
    echo "    - jq: $(command -v jq >/dev/null && echo '✅' || echo '❌')"
    echo "    - openssl: $(command -v openssl >/dev/null && echo '✅' || echo '❌')"
}

function zbox_history() {
    echo "📜 Recent ZBOX History:"
    echo ""
    if [[ -f "$ZBOX_USER_HOME/history/prompts.log" ]]; then
        tail -10 "$ZBOX_USER_HOME/history/prompts.log" | nl -w2 -s': '
    else
        echo "No history found."
    fi
}

function zbox_session() {
    echo "🔑 Current ZBOX Session:"
    echo "  Session ID: $ZBOX_SESSION_ID"
    echo "  API Key: ${ZBOX_API_KEY:0:20}..."
    echo "  Started: $(test -f "$ZBOX_USER_HOME/context/session.json" && cat "$ZBOX_USER_HOME/context/session.json" | grep -o '"started":"[^"]*"' | cut -d'"' -f4 || echo 'Unknown')"
    echo "  User Home: $ZBOX_USER_HOME"
}

function zbox_reset() {
    echo "🔄 Resetting ZBOX session..."
    unset ZBOX_SESSION_ID ZBOX_API_KEY
    zbox_init
}

# ============================================================================
# ZBOX CONFIGURATION FUNCTIONS
# ============================================================================

function zbox_config() {
    echo "⚙️ ZBOX Configuration:"
    echo ""
    echo "Environment Variables:"
    echo "  ZBOX_HOME=$ZBOX_HOME"
    echo "  ZBOX_MODEL=${ZBOX_MODEL:-primary}"
    echo "  ZBOX_AGENTS=${ZBOX_AGENTS:-primary,secondary,web_search}"
    echo ""
    echo "User Configuration File: $ZBOX_USER_HOME/.zboxrc"
    echo "$(test -f "$ZBOX_USER_HOME/.zboxrc" && echo '✅ Found' || echo '❌ Not found')"
}

function zbox_models() {
    echo "🤖 Available ZBOX Models:"
    echo "  • primary (default)"
    echo "  • secondary"
    echo "  • code"
    echo ""
    echo "Current model: ${ZBOX_MODEL:-primary}"
    echo ""
    echo "Switch models with: export ZBOX_MODEL=<model_name>"
}

# ============================================================================
# ZBOX EXPORT & NGINX FUNCTIONS
# ============================================================================

function zbox_export_env() {
    local env_file="$ZBOX_USER_HOME/zbox.env"
    cat > "$env_file" << EOF
# ZBOX Environment Variables
export ZBOX_VERSION="$ZBOX_VERSION"
export ZBOX_HOME="$ZBOX_HOME"
export ZBOX_USER_HOME="$ZBOX_USER_HOME"
export ZBOX_SESSION_ID="$ZBOX_SESSION_ID"
export ZBOX_API_KEY="$ZBOX_API_KEY"
export ZBOX_MODEL="$ZBOX_MODEL"
export ZBOX_AGENTS="$ZBOX_AGENTS"
EOF
    echo "🔄 Environment exported to $env_file"
}

function zbox_nginx_config() {
    cat << EOF
# NGINX config for ZBOX user: $USER
location /zbox/$USER/ {
    proxy_pass http://localhost:8080/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-ZBOX-User "$USER";
    proxy_set_header X-ZBOX-Session "$ZBOX_SESSION_ID";
    proxy_set_header X-ZBOX-API-Key "$ZBOX_API_KEY";
}
EOF
}

# ============================================================================
# ZBOX ALIASES & SHORTCUTS
# ============================================================================

# Core command aliases
alias chat='zbox_chat'
alias ask='zbox_chat'
alias orchestrate='zbox_orchestrate'
alias search='zbox_web_search'
alias code='zbox_code_assistant'

# System aliases
alias help='zbox_help'
alias status='zbox_status'
alias history='zbox_history'
alias session='zbox_session'
alias models='zbox_models'
alias config='zbox_config'

# Model management
alias model='echo "Current model: ${ZBOX_MODEL:-primary}"'
alias switch_model='export ZBOX_MODEL'

# ============================================================================
# ZBOX BANNER & AUTO-INITIALIZATION
# ============================================================================

function zbox_banner() {
    cat << 'EOF'
╭───────────────────────────────────────────────────────╮
│  ███████╗██████╗  ██████╗ ██╗  ██╗                   │
│  ╚══███╔╝██╔══██╗██╔═══██╗╚██╗██╔╝                   │
│    ███╔╝ ██████╔╝██║   ██║ ╚███╔╝                    │
│   ███╔╝  ██╔══██╗██║   ██║ ██╔██╗                    │
│  ███████╗██████╔╝╚██████╔╝██╔╝ ██╗                   │
│  ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝                   │
│                                                       │
│           🤖 Your AI-Powered Shell Environment       │
│                    Version 1.0.0                     │
╰───────────────────────────────────────────────────────╯
EOF
}

# ============================================================================
# PLUGIN INITIALIZATION
# ============================================================================

# Auto-initialization when plugin loads
function zbox_plugin_init() {
    # Only show banner if not already initialized
    if [[ -z "$ZBOX_INITIALIZED" ]]; then
        zbox_banner
        echo ""
        echo "🔌 Loading ZBOX Plugin..."
    fi
    
    # Initialize ZBOX system
    zbox_init
    
    # Set up prompt (only if user wants it)
    if [[ "${ZBOX_AUTO_PROMPT:-1}" == "1" ]]; then
        setopt PROMPT_SUBST
        # Add to precmd_functions array to avoid overriding existing prompts
        precmd_functions+=(zbox_prompt)
    fi
    
    export ZBOX_INITIALIZED=1
    
    if [[ -z "$ZBOX_QUIET" ]]; then
        echo ""
        echo "🎉 Welcome to ZBOX, $USER!"
        echo "💡 Type 'help' to see available commands"
        echo "💬 Type 'chat <message>' to start talking to your AI"
        echo "📊 Type 'status' to check system status"
        echo ""
    fi
}

# Run initialization
zbox_plugin_init

# ============================================================================
# PLUGIN CLEANUP (for completeness)
# ============================================================================

function zbox_plugin_cleanup() {
    unset ZBOX_PLUGIN_LOADED
    unset ZBOX_INITIALIZED
    unset ZBOX_SESSION_ID
    unset ZBOX_API_KEY
    
    # Remove aliases
    unalias chat ask orchestrate search code help status history session models config model switch_model 2>/dev/null
    
    # Remove from precmd_functions
    precmd_functions=(${precmd_functions:#zbox_prompt})
    
    echo "🧹 ZBOX plugin cleaned up"
}

# Export main functions for external use
typeset -gx -f zbox_chat zbox_orchestrate zbox_help zbox_status
