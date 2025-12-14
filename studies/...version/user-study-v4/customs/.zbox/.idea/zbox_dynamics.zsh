#!/usr/bin/env zsh
#  ╔══════════════════════════════╗
#  ║   ZBox Dynamic Config v2.0   ║
#  ╚══════════════════════════════╝

# Core system state
ZBOX_STATE_FILE="$HOME/.zbox_state"
ZBOX_KEY_MAP="$HOME/.zbox_keymap"
ZBOX_ENABLED=1

# Function to generate random key names
generate_random_key() {
    local base_name="$1"
    echo "${base_name}_$(head -c 6 /dev/urandom | base64 | tr -d '=/+' | cut -c1-8)"
}

# Function to obfuscate/randomize all configuration keys
randomize_config() {
    echo "🎲 Randomizing configuration keys..."
    
    # Clear existing key map
    > "$ZBOX_KEY_MAP"
    
    # Original -> Randomized key mappings
    declare -A key_mappings=(
        ["HOME_DIR"]=$(generate_random_key "HD")
        ["NOTE_DIR"]=$(generate_random_key "ND") 
        ["DATA_DIR"]=$(generate_random_key "DD")
        ["ENV_DIR"]=$(generate_random_key "ED")
        ["SSH_DIR"]=$(generate_random_key "SD")
        ["GPG_DIR"]=$(generate_random_key "GD")
        ["LOG_DIR"]=$(generate_random_key "LD")
        ["ARC_DIR"]=$(generate_random_key "AD")
        ["BAK_DIR"]=$(generate_random_key "BD")
    )
    
    # Store the mappings and set randomized environment
    for original_key in "${(@k)key_mappings}"; do
        random_key="${key_mappings[$original_key]}"
        echo "$original_key=$random_key" >> "$ZBOX_KEY_MAP"
        
        # Set the randomized environment variable
        case $original_key in
            "HOME_DIR") eval "export $random_key='$HOME'" ;;
            "NOTE_DIR") eval "export $random_key='$HOME/.note'" ;;
            "DATA_DIR") eval "export $random_key='$HOME/data'" ;;
            "ENV_DIR") eval "export $random_key='$HOME/.zbox'" ;;
            "SSH_DIR") eval "export $random_key='$HOME/.ssh'" ;;
            "GPG_DIR") eval "export $random_key='$HOME/.gnupg'" ;;
            "LOG_DIR") eval "export $random_key='$HOME/data/logs'" ;;
            "ARC_DIR") eval "export $random_key='$HOME/data/archives'" ;;
            "BAK_DIR") eval "export $random_key='$HOME/data/backups'" ;;
        esac
        
        echo "  $original_key -> $random_key"
    done
    
    echo "✅ Configuration randomized and stored in $ZBOX_KEY_MAP"
}

# Function to get randomized key name
get_random_key() {
    local original_key="$1"
    if [[ -f "$ZBOX_KEY_MAP" ]]; then
        grep "^$original_key=" "$ZBOX_KEY_MAP" | cut -d'=' -f2
    else
        echo "$original_key"  # fallback to original
    fi
}

# Function to get path using randomized key
get_path() {
    local original_key="$1"
    local random_key=$(get_random_key "$original_key")
    echo "${(P)random_key}"  # Parameter expansion to get value of variable
}

# Toggle system access
toggle_zbox() {
    if [[ $ZBOX_ENABLED -eq 1 ]]; then
        echo "🚫 Disabling ZBox access..."
        ZBOX_ENABLED=0
        
        # Clear all environment variables
        if [[ -f "$ZBOX_KEY_MAP" ]]; then
            while IFS='=' read -r original_key random_key; do
                unset "$random_key"
            done < "$ZBOX_KEY_MAP"
        fi
        
        echo "ZBOX_ENABLED=0" > "$ZBOX_STATE_FILE"
        echo "❌ ZBox disabled - all paths cleared"
    else
        echo "✅ Enabling ZBox access..."
        ZBOX_ENABLED=1
        load_config
        echo "ZBOX_ENABLED=1" > "$ZBOX_STATE_FILE"
        echo "🟢 ZBox enabled"
    fi
}

# Load configuration (randomized or normal)
load_config() {
    if [[ -f "$ZBOX_KEY_MAP" ]]; then
        echo "📋 Loading randomized configuration..."
        randomize_config  # Reload with current mappings
    else
        echo "📋 Loading standard configuration..."
        # Standard configuration
        export HOME_DIR="$HOME"
        export NOTE_DIR="$HOME/.note"
        export DATA_DIR="$HOME/data"
        export ENV_DIR="$HOME/.zbox"
        export SSH_DIR="$HOME/.ssh"
        export GPG_DIR="$HOME/.gnupg"
        export LOG_DIR="$HOME/data/logs"
        export ARC_DIR="$HOME/data/archives"
        export BAK_DIR="$HOME/data/backups"
    fi
}

# Remove the 'z' (your stealth idea)
stealth_mode() {
    echo "🥷 Entering stealth mode - removing 'z' identifiers..."
    
    # Rename .zbox to .box (removing the z)
    if [[ -d "$HOME/.zbox" ]]; then
        mv "$HOME/.zbox" "$HOME/.box"
        echo "  .zbox -> .box"
    fi
    
    # Update environment to use .box instead
    if [[ -f "$ZBOX_KEY_MAP" ]]; then
        sed -i 's/\.zbox/\.box/g' "$ZBOX_KEY_MAP"
    fi
    
    # Update any references in environment
    export ENV_DIR="$HOME/.box"
    
    echo "👤 Stealth mode activated"
}

# Restore from stealth mode
restore_from_stealth() {
    echo "🔍 Restoring from stealth mode..."
    
    if [[ -d "$HOME/.box" ]]; then
        mv "$HOME/.box" "$HOME/.zbox"
        echo "  .box -> .zbox"
    fi
    
    export ENV_DIR="$HOME/.zbox"
    echo "🎯 Normal mode restored"
}

# Status check
zbox_status() {
    echo "╔════════════════════════════════════╗"
    echo "║           ZBox Status              ║"
    echo "╠════════════════════════════════════╣"
    echo "║ Enabled: $([ $ZBOX_ENABLED -eq 1 ] && echo '🟢 YES' || echo '❌ NO')                        ║"
    echo "║ Randomized: $([ -f "$ZBOX_KEY_MAP" ] && echo '🎲 YES' || echo '📝 NO')                     ║"
    echo "║ Stealth: $([ -d "$HOME/.box" ] && echo '🥷 YES' || echo '👁️  NO')                      ║"
    echo "╚════════════════════════════════════╝"
    
    if [[ $ZBOX_ENABLED -eq 1 ]]; then
        echo "\n📂 Current Paths:"
        if [[ -f "$ZBOX_KEY_MAP" ]]; then
            echo "  DATA_DIR: $(get_path 'DATA_DIR')"
            echo "  ENV_DIR:  $(get_path 'ENV_DIR')"
            echo "  LOG_DIR:  $(get_path 'LOG_DIR')"
        else
            echo "  DATA_DIR: $DATA_DIR"
            echo "  ENV_DIR:  $ENV_DIR"  
            echo "  LOG_DIR:  $LOG_DIR"
        fi
    fi
}

# Main command dispatcher
case "${1:-status}" in
    "randomize"|"rand")
        randomize_config
        ;;
    "toggle"|"switch")
        toggle_zbox
        ;;
    "stealth"|"hide")
        stealth_mode
        ;;
    "restore"|"show")
        restore_from_stealth
        ;;
    "reset")
        echo "🔄 Resetting ZBox to default state..."
        rm -f "$ZBOX_KEY_MAP" "$ZBOX_STATE_FILE"
        restore_from_stealth 2>/dev/null
        ZBOX_ENABLED=1
        load_config
        echo "✅ Reset complete"
        ;;
    "status"|*)
        zbox_status
        ;;
esac

# Load saved state if exists
if [[ -f "$ZBOX_STATE_FILE" ]]; then
    source "$ZBOX_STATE_FILE"
fi

# Auto-load config if enabled
if [[ $ZBOX_ENABLED -eq 1 ]]; then
    load_config >/dev/null
fi