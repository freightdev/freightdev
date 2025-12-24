# ============================================================================
# SECURITY HELPERS (helpers/security_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Encryption, hashing, and security helpers

function security_generate_password() {
    local length="${1:-16}"
    local use_special="${2:-true}"
    
    if command -v openssl >/dev/null 2>&1; then
        if [[ "$use_special" == "true" ]]; then
            openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$length"
        else
            openssl rand -base64 32 | tr -d "=+/0OIl" | cut -c1-"$length"
        fi
    else
        # Fallback using /dev/urandom
        if [[ "$use_special" == "true" ]]; then
            tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$length"
        else
            tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
        fi
        echo
    fi
}

function security_hash_string() {
    local input="$1"
    local algorithm="${2:-sha256}"
    
    case "$algorithm" in
        "md5")
            echo -n "$input" | md5sum | cut -d' ' -f1
            ;;
        "sha1")
            echo -n "$input" | sha1sum | cut -d' ' -f1
            ;;
        "sha256")
            echo -n "$input" | sha256sum | cut -d' ' -f1
            ;;
        "sha512")
            echo -n "$input" | sha512sum | cut -d' ' -f1
            ;;
        *)
            output_error "Unsupported hash algorithm: $algorithm"
            return 1
            ;;
    esac
}

function security_encrypt_string() {
    local input="$1"
    local password="$2"
    local algorithm="${3:-aes-256-cbc}"
    
    if command -v openssl >/dev/null 2>&1; then
        echo -n "$input" | openssl enc -"$algorithm" -pbkdf2 -base64 -pass pass:"$password"
    else
        output_error "OpenSSL not found"
        return 1
    fi
}

function security_decrypt_string() {
    local encrypted="$1"
    local password="$2"
    local algorithm="${3:-aes-256-cbc}"
    
    if command -v openssl >/dev/null 2>&1; then
        echo -n "$encrypted" | openssl enc -"$algorithm" -d -pbkdf2 -base64 -pass pass:"$password"
    else
        output_error "OpenSSL not found"
        return 1
    fi
}

function security_sanitize_input() {
    local input="$1"
    local mode="${2:-shell}"  # shell, sql, html, json
    
    case "$mode" in
        "shell")
            # Escape shell metacharacters
            printf '%q' "$input"
            ;;
        "sql")
            # Basic SQL sanitization (escape single quotes)
            echo "$input" | sed "s/'/''/g"
            ;;
        "html")
            # Escape HTML entities
            echo "$input" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
            ;;
        "json")
            # Escape for JSON
            echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n'
            ;;
        *)
            echo "$input"
            ;;
    esac
}

function security_generate_api_key() {
    local prefix="${1:-zbox}"
    local length="${2:-32}"
    
    local random_part=$(openssl rand -hex "$length")
    echo "${prefix}_${random_part}"
}

function security_mask_sensitive() {
    local sensitive_data="$1"
    local show_chars="${2:-4}"
    
    local length=${#sensitive_data}
    
    if [[ $length -le $((show_chars * 2)) ]]; then
        echo "${sensitive_data:0:2}***${sensitive_data: -2}"
    else
        echo "${sensitive_data:0:$show_chars}***${sensitive_data: -$show_chars}"
    fi
}