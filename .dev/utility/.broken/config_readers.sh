#!/bin/bash
# config_reader.sh - Utility to read YAML/JSON config files
# Usage: source this file, then use get_config() function

# Global variable to store config file path
CONFIG_FILE="${CONFIG_FILE:-.env.d/configs/config_reader.yaml}"

# Function to detect if jq or yq is available
check_dependencies() {
    if command -v yq &> /dev/null; then
        echo "yq"
    elif command -v jq &> /dev/null; then
        echo "jq"
    else
        echo "none"
    fi
}

# Function to read YAML using yq
read_yaml() {
    local path="$1"
    local file="$2"
    yq eval "$path" "$file" 2>/dev/null
}

# Function to read JSON using jq
read_json() {
    local path="$1"
    local file="$2"
    jq -r "$path" "$file" 2>/dev/null
}

# Simple YAML parser (fallback - supports basic key: value syntax)
simple_yaml_parse() {
    local path="$1"
    local file="$2"
    
    # Convert dot notation to nested lookup
    # e.g., "paths.src" becomes looking for "src" under "paths"
    IFS='.' read -ra KEYS <<< "$path"
    
    local current_indent=-1
    local target_key="${KEYS[-1]}"
    local parent_keys=("${KEYS[@]:0:${#KEYS[@]}-1}")
    
    # Simple grep-based extraction (works for basic YAML)
    if [ ${#parent_keys[@]} -eq 0 ]; then
        # Top-level key
        grep "^${target_key}:" "$file" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//'
    else
        # Nested key - basic implementation
        awk -v key="$target_key" '
            /^[[:space:]]*'${parent_keys[0]}':[[:space:]]*$/ { in_section=1; next }
            in_section && /^[[:space:]]*[a-zA-Z]/ && !/^[[:space:]]+/ { in_section=0 }
            in_section && $0 ~ "^[[:space:]]+" key ":" { 
                sub(/^[[:space:]]+/, "")
                sub(/^[^:]+:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file"
    fi
}

# Main function to get config value
get_config() {
    local path="$1"
    local config_file="${2:-$CONFIG_FILE}"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file not found: $config_file" >&2
        return 1
    fi
    
    # Detect file type
    local file_type=""
    if [[ "$config_file" == *.json ]]; then
        file_type="json"
    elif [[ "$config_file" == *.yaml ]] || [[ "$config_file" == *.yml ]]; then
        file_type="yaml"
    else
        echo "Error: Unsupported file type. Use .json, .yaml, or .yml" >&2
        return 1
    fi
    
    # Get value based on available tools
    local tool=$(check_dependencies)
    local value=""
    
    if [ "$file_type" = "yaml" ]; then
        if [ "$tool" = "yq" ]; then
            value=$(read_yaml ".$path" "$config_file")
        else
            # Fallback to simple parser
            value=$(simple_yaml_parse "$path" "$config_file")
        fi
    else
        if [ "$tool" = "jq" ]; then
            value=$(read_json ".$path" "$config_file")
        else
            echo "Error: jq is required for JSON parsing. Install with: apt install jq" >&2
            return 1
        fi
    fi
    
    # Return value
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "$value"
        return 0
    else
        echo "Error: Key '$path' not found in $config_file" >&2
        return 1
    fi
}

# Function to load all paths into variables (convenience function)
load_config_paths() {
    local prefix="${1:-PATH_}"
    local config_file="${2:-$CONFIG_FILE}"
    
    # Example: automatically load common paths
    # You can customize this based on your needs
    
    if [ ! -f "$config_file" ]; then
        echo "Warning: Config file not found: $config_file" >&2
        return 1
    fi
    
    # Common path keys to load
    local keys=("src" "dist" "build" "docs" "tests" "scripts" "data")
    
    for key in "${keys[@]}"; do
        local value=$(get_config "paths.$key" "$config_file" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local var_name="${prefix}${key^^}"  # Convert to uppercase
            export "$var_name"="$value"
            echo "Loaded: $var_name=$value"
        fi
    done
}

# Example usage function
show_usage() {
    cat << 'EOF'
Config Reader Utility
=====================

Usage:
    source config_reader.sh
    
    # Get a single value
    SRC_DIR=$(get_config "paths.src")
    
    # Use in commands
    cd "$(get_config 'paths.src')" && ls
    
    # Load all paths at once
    load_config_paths "MY_"
    
    # Use custom config file
    get_config "database.host" "config/db.yaml"

Example YAML (_meta/index.repo.yaml):
    paths:
      src: ./src
      dist: ./dist
      build: ./build
      scripts: ./scripts
    
    project:
      name: my-project
      version: 1.0.0

Example JSON (config.json):
    {
      "paths": {
        "src": "./src",
        "dist": "./dist"
      }
    }

Dependencies (optional but recommended):
    - yq: for YAML parsing (install: pip install yq or go install github.com/mikefarah/yq/v4@latest)
    - jq: for JSON parsing (install: apt install jq)
    
Note: Basic YAML parsing works without dependencies for simple key:value files.
EOF
}

# If script is executed directly (not sourced), show usage
if [ "${BASH_SOURCE[0]}" -eq "${0}" ]; then
    show_usage
fi
