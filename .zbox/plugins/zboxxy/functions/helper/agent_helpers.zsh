# ============================================================================
# AGENT HELPERS (helpers/agent_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Agent communication and orchestration helpers

function agent_call_with_retry() {
    local agent_name="$1"
    local message="$2"
    local max_retries="${3:-3}"
    local retry_delay="${4:-2}"
    
    local attempt=1
    
    while [[ $attempt -le $max_retries ]]; do
        output_debug "Agent call attempt $attempt/$max_retries to $agent_name"
        
        local response
        if response=$(agent_call_direct "$agent_name" "$message"); then
            echo "$response"
            return 0
        fi
        
        if [[ $attempt -lt $max_retries ]]; then
            output_warning "Agent call failed, retrying in ${retry_delay}s... (attempt $attempt/$max_retries)"
            sleep "$retry_delay"
        fi
        
        ((attempt++))
    done
    
    output_error "All agent call attempts failed for $agent_name"
    return 1
}

function agent_call_direct() {
    local agent_name="$1"
    local message="$2"
    local timeout="${3:-30}"
    
    # Get agent configuration
    local agent_endpoint=$(get_agent_endpoint "$agent_name")
    if [[ -z "$agent_endpoint" ]]; then
        output_error "Unknown agent: $agent_name"
        return 1
    fi
    
    # Prepare payload
    local payload=$(jq -n \
        --arg prompt "$message" \
        --arg agent "$agent_name" \
        --arg user "${ZBOX_CURRENT_USER:-unknown}" \
        --arg session "${ZBOX_SESSION_ID:-none}" \
        '{
            prompt: $prompt,
            agent: $agent,
            user: $user,
            session: $session,
            timestamp: now
        }')
    
    # Make request
    net_http_post "$agent_endpoint" "$payload" "application/json" "$timeout"
}

function agent_route_by_capability() {
    local task="$1"
    local required_capability="$2"
    
    # Analyze task to determine best agent
    local best_agent=""
    
    case "$required_capability" in
        "code")
            best_agent="code_agent"
            ;;
        "search")
            best_agent="web_search_agent"
            ;;
        "analysis")
            best_agent="analysis_agent"
            ;;
        "creative")
            best_agent="creative_agent"
            ;;
        *)
            # Use task content to determine agent
            if [[ "$task" == *"code"* || "$task" == *"program"* || "$task" == *"function"* ]]; then
                best_agent="code_agent"
            elif [[ "$task" == *"search"* || "$task" == *"find"* || "$task" == *"lookup"* ]]; then
                best_agent="web_search_agent"
            else
                best_agent="primary_agent"
            fi
            ;;
    esac
    
    echo "$best_agent"
}

function agent_parallel_call() {
    local agents=("$@")
    local message="$1"
    shift
    agents=("$@")
    
    local results=()
    local pids=()
    
    # Start parallel calls
    for agent in "${agents[@]}"; do
        {
            local result=$(agent_call_direct "$agent" "$message" 2>/dev/null)
            echo "AGENT:$agent|RESULT:$result"
        } &
        pids+=($!)
    done
    
    # Wait for all calls to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

function agent_health_check() {
    local agent_name="$1"
    
    local endpoint=$(get_agent_endpoint "$agent_name")
    local health_endpoint="${endpoint%/*}/health"
    
    if net_http_get "$health_endpoint" 5 >/dev/null 2>&1; then
        echo "healthy"
        return 0
    else
        echo "unhealthy"
        return 1
    fi
}

function agent_get_capabilities() {
    local agent_name="$1"
    
    case "$agent_name" in
        "primary")
            echo "general,reasoning,conversation,analysis"
            ;;
        "code")
            echo "programming,debugging,code_review,explanation"
            ;;
        "web_search")
            echo "search,information_retrieval,fact_checking"
            ;;
        "creative")
            echo "writing,storytelling,brainstorming,ideation"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}
