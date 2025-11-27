#!  ╔═══════════════════════════════════════════╗
#?    Plugin Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Plugin directory
PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

# Auto-install and load essential plugins
plugins=(
    "zsh-users/zsh-autosuggestions:zsh-autosuggestions.zsh"
    "zsh-users/zsh-syntax-highlighting:zsh-syntax-highlighting.zsh"
    "zsh-users/zsh-history-substring-search:zsh-history-substring-search.zsh"
    "zsh-users/zsh-completions:zsh-completions.plugin.zsh"
)

# Function to install plugin from GitHub
install_plugin() {
    local repo="$1"
    local plugin_name=$(basename "$repo")
    local plugin_path="$PLUGIN_DIR/$plugin_name"
    
    if [[ ! -d "$plugin_path" ]]; then
        log_info "Installing $plugin_name..."
        git clone "https://github.com/$repo.git" "$plugin_path"
    fi
}

# Function to load plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_file="$2"
    local plugin_path="$PLUGIN_DIR/$plugin_name"
    
    if [[ -f "$plugin_path/$plugin_file" ]]; then
        source "$plugin_path/$plugin_file"
    else
        log_error "Plugin $plugin_name not found at $plugin_path/$plugin_file"
    fi
}

# Install and load plugins
for plugin_info in "${plugins[@]}"; do
    local repo="${plugin_info%:*}"
    local file="${plugin_info#*:}"
    local name=$(basename "$repo")
    
    # Install if not present
    install_plugin "$repo"
    
    # Load plugin
    load_plugin "$name" "$file"
done

# Plugin configurations
if [[ -f "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    # Autosuggestions config
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=1
fi

if [[ -f "$PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    # History substring search config
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=green,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
    
    # Key bindings for history substring search
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
fi

# Fast syntax highlighting alternative (built-in)
if [[ ! -f "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    # Fallback to basic zsh highlighting
    autoload -Uz select-word-style
    select-word-style bash
fi

# Plugin status function
plugin-status() {
    for plugin_info in "${plugins[@]}"; do
        local repo="${plugin_info%:*}"
        local file="${plugin_info#*:}"
        local name=$(basename "$repo")
        local plugin_path="$PLUGIN_DIR/$name"
        
        if [[ -d "$plugin_path" ]]; then
            log_ok "✅ $name - installed"
        else
            log_error "❌ $name - missing"
        fi
    done
    
    echo
    log_info "Commands:"
    log_info "- plugin-update: Update all plugins"
    log_info "- plugin-status: Show this status"
}

# Plugin update function
plugin-update() {
    for plugin_info in "${plugins[@]}"; do
        local repo="${plugin_info%:*}"
        local name=$(basename "$repo")
        local plugin_path="$PLUGIN_DIR/$name"
        
        if [[ -d "$plugin_path" ]]; then
            log_info "Updating $name..."
            (cd "$plugin_path" && git pull)
        else
            log_info "Installing $name..."
            install_plugin "$repo"
        fi
    done
    log_ok "Plugin update complete! Restart your shell to apply changes."
}

# Auto-install on first run
if [[ ! -f "$HOME/.zsh/.zsh_plugins_installed" ]]; then
    log_info "First time setup - installing ZSH plugins..."
    plugin-update
    touch "$HOME/.zsh/.zsh_plugins_installed"
    log_ok "Plugins installed! Restart your shell for full functionality."
fi
