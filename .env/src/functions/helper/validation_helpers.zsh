# ============================================================================
# VALIDATION HELPERS (helpers/validation_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Data validation and type checking helpers

function validate_json() {
    local json_string="$1"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json_string" | jq empty 2>/dev/null
    else
        # Basic JSON validation
        if [[ "$json_string" =~ ^\{.*\}$ ]] || [[ "$json_string" =~ ^\[.*\]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

function validate_integer() {
    local value="$1"
    local min="$2"
    local max="$3"
    
    if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
        output_error "Invalid integer: $value"
        return 1
    fi
    
    if [[ -n "$min" && $value -lt $min ]]; then
        output_error "Value $value is less than minimum $min"
        return 1
    fi
    
    if [[ -n "$max" && $value -gt $max ]]; then
        output_error "Value $value is greater than maximum $max"
        return 1
    fi
    
    return 0
}

function validate_float() {
    local value="$1"
    local min="$2"
    local max="$3"
    
    if [[ ! "$value" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
        output_error "Invalid float: $value"
        return 1
    fi
    
    if [[ -n "$min" ]] && (( $(echo "$value < $min" | bc -l) )); then
        output_error "Value $value is less than minimum $min"
        return 1
    fi
    
    if [[ -n "$max" ]] && (( $(echo "$value > $max" | bc -l) )); then
        output_error "Value $value is greater than maximum $max"
        return 1
    fi
    
    return 0
}

function validate_file_exists() {
    local filepath="$1"
    local must_be_readable="${2:-true}"
    
    if [[ ! -f "$filepath" ]]; then
        output_error "File does not exist: $filepath"
        return 1
    fi
    
    if [[ "$must_be_readable" == "true" && ! -r "$filepath" ]]; then
        output_error "File is not readable: $filepath"
        return 1
    fi
    
    return 0
}

function validate_directory() {
    local dirpath="$1"
    local must_be_writable="${2:-false}"
    
    if [[ ! -d "$dirpath" ]]; then
        output_error "Directory does not exist: $dirpath"
        return 1
    fi
    
    if [[ "$must_be_writable" == "true" && ! -w "$dirpath" ]]; then
        output_error "Directory is not writable: $dirpath"
        return 1
    fi
    
    return 0
}

function validate_port() {
    local port="$1"
    
    if ! validate_integer "$port" 1 65535; then
        output_error "Invalid port number: $port"
        return 1
    fi
    
    return 0
}

function validate_url() {
    local url="$1"
    
    if [[ ! "$url" =~ ^https?://[^/]+.*$ ]]; then
        output_error "Invalid URL format: $url"
        return 1
    fi
    
    return 0
}

function validate_required_vars() {
    local vars=("$@")
    local missing_vars=()
    
    for var in "${vars[@]}"; do
        if [[ -z "${(P)var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars} -gt 0 ]]; then
        output_error "Missing required environment variables: ${(j:, :)missing_vars}"
        return 1
    fi
    
    return 0
}