# ============================================================================
# HYDRATION HELPERS (helpers/hydration_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Data transformation and enrichment helpers

function hydrate_user_context() {
    local username="$1"
    local base_context="$2"
    
    # Enrich context with user data
    local user_info=$(get_user_info "$username")
    local user_prefs=$(get_user_preferences "$username")
    local recent_activity=$(get_recent_activity "$username" 5)
    
    local hydrated_context="$base_context

User Information:
$user_info

User Preferences:
$user_prefs

Recent Activity:
$recent_activity"
    
    echo "$hydrated_context"
}

function hydrate_prompt_with_memory() {
    local user="$1"
    local prompt="$2"
    local max_memories="${3:-3}"
    
    # Get relevant memories
    local relevant_memories=$(recall_relevant_memories "$user" "$prompt" "$max_memories")
    
    # Get conversation context
    local conversation_context=$(get_conversation_context "$user" 5)
    
    local hydrated_prompt="Context and Memory for $user:

Recent Conversations:
$conversation_context

Relevant Memories:
$relevant_memories

Current Request: $prompt"
    
    echo "$hydrated_prompt"
}

function hydrate_model_response() {
    local response="$1"
    local user="$2"
    local model="$3"
    
    # Add metadata and formatting
    local timestamp=$(date -Iseconds)
    local word_count=$(echo "$response" | wc -w)
    local char_count=${#response}
    
    cat << EOF
{
    "response": "$response",
    "metadata": {
        "user": "$user",
        "model": "$model", 
        "timestamp": "$timestamp",
        "word_count": $word_count,
        "character_count": $char_count,
        "generated_by": "ZBOX"
    }
}
EOF
}

function hydrate_system_info() {
    local base_info="$1"
    
    # Add current system metrics
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    local load_average=$(uptime | awk '{print $10}')
    
    cat << EOF
$base_info

System Metrics:
- CPU Usage: $cpu_usage%
- Memory Usage: $memory_usage%
- Disk Usage: $disk_usage%
- Load Average: $load_average
- Timestamp: $(date -Iseconds)
EOF
}

function hydrate_error_context() {
    local error_message="$1"
    local function_name="$2"
    local line_number="$3"
    
    # Enrich error with debugging context
    local stack_trace=$(get_call_stack)
    local system_state=$(get_system_state_summary)
    
    cat << EOF
Error Details:
- Message: $error_message
- Function: $function_name
- Line: $line_number
- Timestamp: $(date -Iseconds)
- User: ${ZBOX_CURRENT_USER:-unknown}
- Session: ${ZBOX_SESSION_ID:-none}

Call Stack:
$stack_trace

System State:
$system_state
EOF
}

function hydrate_api_response() {
    local data="$1"
    local status="${2:-200}"
    local message="${3:-OK}"
    
    cat << EOF
{
    "status": $status,
    "message": "$message",
    "data": $data,
    "timestamp": "$(date -Iseconds)",
    "request_id": "$(uuidgen 2>/dev/null || echo req_$(date +%s)_$RANDOM)"
}
EOF
}