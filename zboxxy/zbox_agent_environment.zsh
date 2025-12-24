#!/bin/zsh
# ZBOX - Custom AI Shell Environment
# Your own shell that people log into to interact with your models

# ============================================================================
# ZBOX CORE SYSTEM
# ============================================================================

export ZBOX_VERSION="1.0.0"
export ZBOX_HOME="/opt/zbox"
export ZBOX_USER_HOME="$ZBOX_HOME/users/$USER"
export ZBOX_MODELS_PATH="$ZBOX_HOME/models"
export ZBOX_SCRIPTS_PATH="$ZBOX_HOME/scripts"
export ZBOX_LOGS_PATH="$ZBOX_HOME/logs"

# Create ZBOX environment structure
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
    echo "zbox_${USER}_$(date +%s)_$(openssl rand -hex 8)"
}

# ============================================================================
# ZBOX MODEL INTERFACE
# ============================================================================

# Your main model interaction function
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
                --output-format "zbox")
    
    if [[ $? -eq 0 ]]; then
        # Format and display response
        zbox_format_response "$response"
        
        # Save to history
        echo "$prompt" >> "$ZBOX_USER_HOME/history/prompts.log"
        echo "$response" >> "$ZBOX_USER_HOME/history/responses.log"
        
        return 0
    else
        echo "❌ Model interaction failed"
        return 1
    fi
}

# Format model responses for ZBOX display
function zbox_format_response() {
    local response="$1"
    
    # ZBOX custom formatting
    echo ""
    echo "╭─────────────────────────────────────────────╮"
    echo "│  🤖 ZBOX AI Response                       │"
    echo "├─────────────────────────────────────────────┤"
    
    # Pretty print the response with word wrapping
    echo "$response" | fold -s -w 45 | sed 's/^/│  /'
    
    echo "├─────────────────────────────────────────────┤"
    echo "│  Session: ${ZBOX_SESSION_ID:0:12}...        │"
    echo "│  User: $USER | $(date '+%H:%M:%S')          │"
    echo "╰─────────────────────────────────────────────╯"
    echo ""
}

# ============================================================================
# ZBOX AGENT ORCHESTRATION
# ============================================================================

# Your agent hierarchy system
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
            zbox_format_response "$result"
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
    
    # Your web search implementation
    curl -s "http://localhost:8003/search" \
        -H "Authorization: Bearer $ZBOX_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"$query\",\"user\":\"$USER\",\"session\":\"$ZBOX_SESSION_ID\"}" \
    | jq -r '.response // "Search failed"'
}

function zbox_code_assistant() {
    local code_request="$*"
    echo "💻 Code assistance for: $code_request"
    
    # Call specialized code model
    ZBOX_MODEL="code" zbox_chat "Code assistance: $code_request"
}

# ============================================================================
# ZBOX USER INTERFACE
# ============================================================================

# Custom ZBOX prompt
function zbox_prompt() {
    local user_color="%F{cyan}"
    local session_color="%F{yellow}" 
    local model_color="%F{green}"
    local reset="%f"
    
    PROMPT="${user_color}┌─[ZBOX]─[${USER}]─[${ZBOX_SESSION_ID:0:8}]${reset}
${user_color}└─▶${reset} "
    
    # Right side prompt with model info
    RPROMPT="${model_color}[${ZBOX_MODEL:-primary}]${reset} ${session_color}$(date '+%H:%M')${reset}"
}

# ZBOX help system
function zbox_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│            🚀 ZBOX HELP SYSTEM              │
├─────────────────────────────────────────────┤
│                                             │
│  💬 Chat Commands:                          │
│    zbox_chat <message>    - Chat with AI    │
│    zbox_orchestrate <task> - Use agents     │
│                                             │
│  🔍 Search & Tools:                         │
│    zbox_web_search <query> - Web search     │
│    zbox_code_assistant <request> - Code     │
│                                             │
│  ⚙️  System Commands:                       │
│    zbox_status      - System status         │
│    zbox_history     - View chat history     │
│    zbox_models      - List available models │
│    zbox_config      - Configuration         │
│                                             │
│  🔑 Session Management:                     │
│    zbox_session     - Current session info  │
│    zbox_reset       - Reset session         │
│    zbox_export      - Export session data   │
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
    echo ""
    echo "🔧 Component Status:"
    echo "  Rust Binary: $(test -x "$ZBOX_HOME/bin/rust_llama_binary" && echo '✅' || echo '❌')"
    echo "  Models Dir: $(test -d "$ZBOX_MODELS_PATH" && echo '✅' || echo '❌')"
    echo "  User Context: $(test -f "$ZBOX_USER_HOME/context/session.json" && echo '✅' || echo '❌')"
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

# ============================================================================
# ZBOX ALIASES & SHORTCUTS
# ============================================================================

# Quick aliases for ZBOX
alias chat='zbox_chat'
alias ask='zbox_chat'
alias orchestrate='zbox_orchestrate'
alias search='zbox_web_search'
alias code='zbox_code_assistant'
alias help='zbox_help'
alias status='zbox_status'
alias history='zbox_history'

# Model switching
alias model='echo "Current model: ${ZBOX_MODEL:-primary}"'
alias switch_model='export ZBOX_MODEL'

# ============================================================================
# ZBOX INITIALIZATION
# ============================================================================

# Banner
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

# Auto-initialization when ZBOX is loaded
if [[ -z "$ZBOX_INITIALIZED" ]]; then
    zbox_banner
    zbox_init
    zbox_prompt
    export ZBOX_INITIALIZED=1
    
    echo ""
    echo "🎉 Welcome to ZBOX, $USER!"
    echo "💡 Type 'help' to see available commands"
    echo "💬 Type 'chat <message>' to start talking to your AI"
    echo ""
fi

# Set custom prompt
setopt PROMPT_SUBST
precmd() { zbox_prompt }

# ============================================================================
# ZBOX CONTAINER/APPIMAGE SUPPORT
# ============================================================================

# Export ZBOX environment for containerization
function zbox_export_env() {
    cat > "$ZBOX_USER_HOME/zbox.env" << EOF
export ZBOX_VERSION="$ZBOX_VERSION"
export ZBOX_HOME="$ZBOX_HOME"
export ZBOX_USER_HOME="$ZBOX_USER_HOME"
export ZBOX_SESSION_ID="$ZBOX_SESSION_ID"
export ZBOX_API_KEY="$ZBOX_API_KEY"
export ZBOX_MODEL="$ZBOX_MODEL"
EOF
    echo "🔄 Environment exported to $ZBOX_USER_HOME/zbox.env"
}

# NGINX routing helper - generates config for your user
function zbox_nginx_config() {
    cat << EOF
# NGINX config for ZBOX user: $USER
location /zbox/$USER/ {
    proxy_pass http://localhost:8080/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-ZBOX-User "$USER";
    proxy_set_header X-ZBOX-Session "$ZBOX_SESSION_ID";
}
EOF
}

echo "🚀 ZBOX Shell System Loaded!"
