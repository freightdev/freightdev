#!/bin/zsh
################
# ZSH Pluggins
################

# Plugin directory
: "${ZSH_DIR:=$HOME/.zsh}"
: "${PLUGGIN_DIR:=$ZSH_DIR/pluggins}"
[[ ! -d "$PLUGGIN_DIR" ]] && mkdir -p "$PLUGGIN_DIR"

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
    local plugin_name="${repo:t}"  # zsh built-in: gets basename
    local plugin_path="$PLUGGIN_DIR/$plugin_name"
    
    if [[ ! -d "$plugin_path" ]]; then
        echo "Installing $plugin_name..."
        git clone "https://github.com/$repo.git" "$plugin_path"
    fi
}

# Function to load plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_file="$2"
    local plugin_path="$PLUGGIN_DIR/$plugin_name"
    
    if [[ -f "$plugin_path/$plugin_file" ]]; then
        source "$plugin_path/$plugin_file"
    else
        echo "Plugin $plugin_name not found at $plugin_path/$plugin_file"
    fi
}

# Install and load plugins
for plugin_info in "${plugins[@]}"; do
    local repo="${plugin_info%:*}"
    local file="${plugin_info#*:}"
    local name="${repo:t}"  # zsh built-in: gets basename
    
    # Install if not present
    install_plugin "$repo"
    
    # Load plugin
    load_plugin "$name" "$file"
done

# Plugin configurations
if [[ -f "$PLUGGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    # Autosuggestions config
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=1
fi

if [[ -f "$PLUGGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
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
if [[ ! -f "$PLUGGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    # Fallback to basic zsh highlighting
    autoload -Uz select-word-style
    select-word-style bash
fi

# Plugin status function
plugin-status() {
    for plugin_info in "${plugins[@]}"; do
        local repo="${plugin_info%:*}"
        local file="${plugin_info#*:}"
        local name="${repo:t}"  # zsh built-in: gets basename
        local plugin_path="$PLUGGIN_DIR/$name"
        
        if [[ -d "$plugin_path" ]]; then
            echo "✅ $name - installed"
        else
            echo "❌ $name - missing"
        fi
    done
    
    echo
    echo "Commands:"
    echo "  - plugin-update: Update all plugins"
    echo "  - plugin-status: Show this status"
}

# Plugin update function
plugin-update() {
    for plugin_info in "${plugins[@]}"; do
        local repo="${plugin_info%:*}"
        local name="${repo:t}"  # zsh built-in: gets basename
        local plugin_path="$PLUGGIN_DIR/$name"
        
        if [[ -d "$plugin_path" ]]; then
            echo "Updating $name..."
            (cd "$plugin_path" && git pull)
        else
            echo "Installing $name..."
            install_plugin "$repo"
        fi
    done
    echo "Plugin update complete! Restart your shell to apply changes."
}

# Auto-install on first run
if [[ ! -f "$ZSH_DIR/.zsh_plugins_installed" ]]; then
    echo "First time setup - installing ZSH plugins..."
    plugin-update
    touch "$ZSH_DIR/.zsh_plugins_installed"
    echo "Plugins installed! Restart your shell for full functionality."
fi
