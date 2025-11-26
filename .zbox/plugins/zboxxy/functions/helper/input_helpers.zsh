# ============================================================================
# INPUT HELPERS (helpers/input_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Input validation, sanitization, and parsing helpers

function input_validate_username() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        echo "ERROR: Username cannot be empty"
        return 1
    fi
    
    if [[ ! "$username" =~ ^[a-zA-Z0-9_]{3,20}$ ]]; then
        echo "ERROR: Username must be 3-20 alphanumeric characters"
        return 1
    fi
    
    return 0
}

function input_validate_email() {
    local email="$1"
    
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format"
        return 1
    fi
    
    return 0
}

function input_sanitize_prompt() {
    local prompt="$1"
    
    # Remove dangerous characters
    prompt=$(echo "$prompt" | sed 's/[`$\\]/\\&/g')
    
    # Remove excessive whitespace
    prompt=$(echo "$prompt" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    
    # Limit length
    if [[ ${#prompt} -gt 4000 ]]; then
        prompt="${prompt:0:4000}..."
    fi
    
    echo "$prompt"
}

function input_parse_key_value() {
    local input="$1"
    local separator="${2:-=}"
    
    if [[ "$input" == *"$separator"* ]]; then
        local key="${input%%$separator*}"
        local value="${input#*$separator}"
        echo "KEY:$key|VALUE:$value"
        return 0
    else
        echo "ERROR: Invalid key-value format"
        return 1
    fi
}

function input_get_user_choice() {
    local prompt="$1"
    local options="$2"  # comma-separated
    local default="$3"
    
    local IFS=','
    local choices=($options)
    
    echo "$prompt"
    for i in {1..${#choices}}; do
        echo "  $i) ${choices[i]}"
    done
    
    if [[ -n "$default" ]]; then
        echo -n "Choose (1-${#choices}) [default: $default]: "
    else
        echo -n "Choose (1-${#choices}): "
    fi
    
    read choice
    
    if [[ -z "$choice" && -n "$default" ]]; then
        choice="$default"
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#choices} ]]; then
        echo "${choices[choice]}"
        return 0
    else
        echo "ERROR: Invalid choice"
        return 1
    fi
}

function input_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    local default_text=""
    if [[ "$default" == "y" ]]; then
        default_text=" [Y/n]"
    else
        default_text=" [y/N]"
    fi
    
    echo -n "$prompt$default_text: "
    read response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

function input_read_secure() {
    local prompt="$1"
    local var_name="$2"
    
    echo -n "$prompt: "
    read -s response
    echo
    
    eval "$var_name=\"$response\""
}