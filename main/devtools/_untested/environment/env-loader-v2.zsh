#!/bin/zsh
# Master Environment Loader for Zsh

# The directory where all env files live
ENV_DIR="$HOME/.zshlocal.d/env"

# Make sure directory exists
if [[ ! -d "$ENV_DIR" ]]; then
    echo "❌ Environment directory not found: $ENV_DIR"
    return 1
fi

# Function to load a specific env file
load_env() {
    local env_name="$1"
    local env_file="$ENV_DIR/.env.${env_name}"

    # Special case: plain .env
    [[ "$env_name" == "default" ]] && env_file="$ENV_DIR/.env"

    if [[ -f "$env_file" ]]; then
        source "$env_file"
        echo "✅ Loaded environment: $env_file"
    else
        echo "⚠️ Env file not found: $env_file"
    fi
}

# Prompt user for which env to load if not given
choose_env() {
    echo "Select environment to load:"
    echo "  1) default (.env)"
    echo "  2) local (.env.local)"
    echo "  3) development (.env.development)"
    echo "  4) production (.env.production)"
    read -k1 "choice?Enter choice (1-4): "
    echo

    case "$choice" in
        1) load_env "default" ;;
        2) load_env "local" ;;
        3) load_env "development" ;;
        4) load_env "production" ;;
        *) echo "❌ Invalid choice" ;;
    esac
}

# If a parameter is passed, load directly
if [[ -n "${1:-}" ]]; then
    load_env "$1"
else
    choose_env
fi
