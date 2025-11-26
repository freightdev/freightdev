# ============================================================================
# MEMORY HELPERS (helpers/memory_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Memory operations and caching helpers

function memory_cache_get() {
    local cache_key="$1"
    local cache_dir="${2:-$ZBOX_HOME/cache}"
    local max_age="${3:-3600}"  # 1 hour default
    
    local cache_file="$cache_dir/$cache_key"
    
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        
        if [[ $file_age -le $max_age ]]; then
            cat "$cache_file"
            return 0
        else
            rm -f "$cache_file"
        fi
    fi
    
    return 1
}

function memory_cache_set() {
    local cache_key="$1"
    local data="$2"
    local cache_dir="${3:-$ZBOX_HOME/cache}"
    
    mkdir -p "$cache_dir"
    echo "$data" > "$cache_dir/$cache_key"
}

function memory_cache_clear() {
    local cache_dir="${1:-$ZBOX_HOME/cache}"
    local older_than="${2:-7d}"
    
    if [[ -d "$cache_dir" ]]; then
        find "$cache_dir" -type f -mtime "+${older_than%d}" -delete
        output_info "Cleared cache files older than $older_than"
    fi
}

function memory_get_conversation_summary() {
    local user="$1"
    local limit="${2:-10}"
    
    local conversation_file="$ZBOX_USER_HOME/memory/conversations.jsonl"
    
    if [[ -f "$conversation_file" ]]; then
        tail -n "$limit" "$conversation_file" | jq -r '.user_message + " -> " + .ai_response' | head -c 500
    else
        echo "No conversation history found"
    fi
}

function memory_store_fact_extracted() {
    local fact="$1"
    local category="$2"
    local confidence="${3:-0.8}"
    local source="$4"
    
    local fact_id="fact_$(date +%s)_$RANDOM"
    local timestamp=$(date -Iseconds)
    
    local fact_entry=$(jq -n \
        --arg id "$fact_id" \
        --arg fact "$fact" \
        --arg category "$category" \
        --arg confidence "$confidence" \
        --arg source "$source" \
        --arg timestamp "$timestamp" \
        '{
            id: $id,
            fact: $fact,
            category: $category,
            confidence: ($confidence | tonumber),
            source: $source,
            timestamp: $timestamp,
            verified: false
        }')
    
    echo "$fact_entry" >> "$ZBOX_USER_HOME/memory/extracted_facts.jsonl"
    output_debug "Stored extracted fact: $fact"
}

function memory_similarity_search() {
    local query="$1"
    local user="$2"
    local limit="${3:-5}"
    
    # Simple keyword-based similarity (can be enhanced with embeddings)
    local memory_file="$ZBOX_USER_HOME/memory/user_memory.json"
    
    if [[ -f "$memory_file" ]]; then
        jq -r --arg query "$query" --arg limit "$limit" '
            .memories | 
            map(select(.fact | test($query; "i"))) |
            sort_by(.importance) | 
            reverse | 
            .[:($limit | tonumber)] | 
            .[] | 
            .fact + " (importance: " + (.importance | tostring) + ")"
        ' "$memory_file"
    fi
}

function memory_consolidate_facts() {
    local user="$1"
    
    # Find and merge similar facts
    local extracted_facts="$ZBOX_USER_HOME/memory/extracted_facts.jsonl"
    local consolidated_file="$ZBOX_USER_HOME/memory/consolidated_facts.json"
    
    if [[ -f "$extracted_facts" ]]; then
        # Group similar facts by category and content similarity
        local consolidated=$(jq -s 'group_by(.category) | map({
            category: .[0].category,
            facts: map(.fact) | unique,
            count: length,
            last_updated: now
        })' "$extracted_facts")
        
        echo "$consolidated" > "$consolidated_file"
        output_info "Consolidated facts for user: $user"
    fi
}