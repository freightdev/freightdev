# ============================================================================
# PARSING HELPERS (helpers/parsing_helpers.zsh)
# ============================================================================

#!/bin/zsh
# JSON, config, and text parsing helpers

function parse_json_get() {
    local json="$1"
    local key="$2"
    local default="$3"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq -r ".$key // \"$default\"" 2>/dev/null || echo "$default"
    else
        # Basic JSON parsing without jq
        local value=$(echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | cut -d'"' -f4)
        echo "${value:-$default}"
    fi
}

function parse_json_set() {
    local json="$1"
    local key="$2"
    local value="$3"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq --arg key "$key" --arg value "$value" '.[$key] = $value'
    else
        # Basic JSON setting without jq
        echo "$json" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/"
    fi
}

function parse_config_file() {
    local config_file="$1"
    local section="${2:-}"
    
    if [[ ! -f "$config_file" ]]; then
        output_error "Config file not found: $config_file"
        return 1
    fi
    
    if [[ -n "$section" ]]; then
        # Parse specific section
        awk -v section="[$section]" '
            $0 == section { found=1; next }
            /^\[/ && found { found=0 }
            found && /^[^#]/ && /=/ { print }
        ' "$config_file"
    else
        # Parse entire file
        grep -v '^#' "$config_file" | grep '=' || true
    fi
}

function parse_csv_line() {
    local csv_line="$1"
    local delimiter="${2:-,}"
    
    # Handle quoted fields
    echo "$csv_line" | awk -F"$delimiter" '{
        for(i=1; i<=NF; i++) {
            gsub(/^"/, "", $i)
            gsub(/"$/, "", $i)
            print "FIELD_" i ": " $i
        }
    }'
}

function parse_url() {
    local url="$1"
    
    # Extract components
    local protocol=$(echo "$url" | grep -o '^[^:]*')
    local host=$(echo "$url" | sed 's|^[^:]*://||' | cut -d'/' -f1 | cut -d':' -f1)
    local port=$(echo "$url" | sed 's|^[^:]*://||' | cut -d'/' -f1 | grep -o ':[0-9]*' | cut -d':' -f2)
    local path=$(echo "$url" | sed 's|^[^:]*://[^/]*||')
    
    echo "PROTOCOL:$protocol"
    echo "HOST:$host"
    echo "PORT:${port:-80}"
    echo "PATH:${path:-/}"
}

function parse_command_args() {
    local command="$1"
    shift
    
    local -A parsed_args
    local positional_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --*=*)
                local key="${1%%=*}"
                local value="${1#*=}"
                parsed_args[${key#--}]="$value"
                ;;
            --*)
                local key="${1#--}"
                if [[ $# -gt 1 && ! "$2" =~ ^-- ]]; then
                    parsed_args[$key]="$2"
                    shift
                else
                    parsed_args[$key]="true"
                fi
                ;;
            -*)
                local key="${1#-}"
                if [[ ${#key} -eq 1 ]]; then
                    if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
                        parsed_args[$key]="$2"
                        shift
                    else
                        parsed_args[$key]="true"
                    fi
                fi
                ;;
            *)
                positional_args+=("$1")
                ;;
        esac
        shift
    done
    
    # Output parsed arguments
    for key in ${(k)parsed_args}; do
        echo "ARG_$key=${parsed_args[$key]}"
    done
    
    for i in {1..${#positional_args}}; do
        echo "POS_$i=${positional_args[i]}"
    done
}

function parse_log_entry() {
    local log_entry="$1"
    local format="${2:-standard}"  # standard, apache, nginx, json
    
    case "$format" in
        "standard")
            # [TIMESTAMP] LEVEL | Message
            local timestamp=$(echo "$log_entry" | grep -o '^\[[^\]]*\]' | tr -d '[]')
            local level=$(echo "$log_entry" | sed 's/^\[[^\]]*\] *//' | cut -d'|' -f1 | xargs)
            local message=$(echo "$log_entry" | sed 's/^\[[^\]]*\] *[^|]*| *//')
            
            echo "TIMESTAMP:$timestamp"
            echo "LEVEL:$level"
            echo "MESSAGE:$message"
            ;;
        "json")
            parse_json_get "$log_entry" "timestamp"
            parse_json_get "$log_entry" "level"
            parse_json_get "$log_entry" "message"
            ;;
    esac
}
