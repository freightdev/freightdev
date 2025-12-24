# ============================================================================
# NETWORK HELPERS (helpers/network_helpers.zsh)
# ============================================================================

#!/bin/zsh
# HTTP, socket, and network operation helpers

function net_http_get() {
    local url="$1"
    local timeout="${2:-30}"
    local headers="$3"
    
    local curl_opts=(-s -f --max-time "$timeout")
    
    if [[ -n "$headers" ]]; then
        while IFS='=' read -r key value; do
            curl_opts+=(-H "$key: $value")
        done <<< "$headers"
    fi
    
    if command -v curl >/dev/null 2>&1; then
        curl "${curl_opts[@]}" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout="$timeout" "$url"
    else
        output_error "Neither curl nor wget found"
        return 1
    fi
}

function net_http_post() {
    local url="$1"
    local data="$2"
    local content_type="${3:-application/json}"
    local timeout="${4:-30}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -f --max-time "$timeout" \
            -H "Content-Type: $content_type" \
            -d "$data" \
            "$url"
    else
        output_error "curl not found for POST request"
        return 1
    fi
}

function net_check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"
    
    if command -v nc >/dev/null 2>&1; then
        nc -z -w"$timeout" "$host" "$port" >/dev/null 2>&1
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" >/dev/null 2>&1
    else
        # Fallback method
        (echo >/dev/tcp/$host/$port) >/dev/null 2>&1 &
        local pid=$!
        sleep "$timeout"
        kill $pid >/dev/null 2>&1
        wait $pid >/dev/null 2>&1
        return $?
    fi
}

function net_get_external_ip() {
    local services=("httpbin.org/ip" "icanhazip.com" "ipecho.net/plain")
    
    for service in "${services[@]}"; do
        local ip=$(net_http_get "http://$service" 5 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    output_error "Could not determine external IP"
    return 1
}

function net_socket_send() {
    local socket_path="$1"
    local message="$2"
    local timeout="${3:-10}"
    
    if [[ -S "$socket_path" ]]; then
        echo "$message" | nc -U "$socket_path" -w "$timeout"
    else
        output_error "Socket not found: $socket_path"
        return 1
    fi
}

function net_wait_for_service() {
    local host="$1"
    local port="$2"
    local max_wait="${3:-60}"
    local check_interval="${4:-2}"
    
    local waited=0
    
    output_info "Waiting for $host:$port to be available..."
    
    while [[ $waited -lt $max_wait ]]; do
        if net_check_port "$host" "$port"; then
            output_success "Service available: $host:$port"
            return 0
        fi
        
        sleep "$check_interval"
        waited=$((waited + check_interval))
    done
    
    output_error "Service not available after ${max_wait}s: $host:$port"
    return 1
}

function net_download_file() {
    local url="$1"
    local output_path="$2"
    local show_progress="${3:-true}"
    
    local curl_opts=(-f -L)
    
    if [[ "$show_progress" == "true" ]]; then
        curl_opts+=(-#)  # Show progress bar
    else
        curl_opts+=(-s)  # Silent
    fi
    
    if command -v curl >/dev/null 2>&1; then
        curl "${curl_opts[@]}" -o "$output_path" "$url"
    elif command -v wget >/dev/null 2>&1; then
        if [[ "$show_progress" == "true" ]]; then
            wget --progress=bar -O "$output_path" "$url"
        else
            wget -q -O "$output_path" "$url"
        fi
    else
        output_error "Neither curl nor wget found"
        return 1
    fi
}
