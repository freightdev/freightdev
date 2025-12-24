#!/bin/zsh
# ZBOX Memory Management System
# Handles user context, conversation history, and persistent memory

# ============================================================================
# ZBOX MEMORY CORE
# ============================================================================

export ZBOX_MEMORY_PATH="$ZBOX_USER_HOME/memory"
export ZBOX_MEMORY_DB="$ZBOX_MEMORY_PATH/user_memory.json"
export ZBOX_CONTEXT_DB="$ZBOX_MEMORY_PATH/context.json"
export ZBOX_CONVERSATION_DB="$ZBOX_MEMORY_PATH/conversations.jsonl"
export ZBOX_PREFERENCES_DB="$ZBOX_MEMORY_PATH/preferences.json"
export ZBOX_MEMORY_INDEX="$ZBOX_MEMORY_PATH/memory_index.json"

# Initialize memory system for user
function zbox_memory_init() {
    echo "🧠 Initializing ZBOX Memory System for $USER..."
    
    # Create memory directory structure
    mkdir -p "$ZBOX_MEMORY_PATH"/{conversations,context,embeddings,snapshots}
    
    # Initialize databases if they don't exist
    [[ ! -f "$ZBOX_MEMORY_DB" ]] && echo '{"user":"'$USER'","created":"'$(date -Iseconds)'","memories":[]}' > "$ZBOX_MEMORY_DB"
    [[ ! -f "$ZBOX_CONTEXT_DB" ]] && echo '{"active_context":[],"context_window":4096,"max_context":8192}' > "$ZBOX_CONTEXT_DB"
    [[ ! -f "$ZBOX_PREFERENCES_DB" ]] && echo '{"model":"primary","temperature":0.7,"max_tokens":512,"memory_enabled":true}' > "$ZBOX_PREFERENCES_DB"
    [[ ! -f "$ZBOX_MEMORY_INDEX" ]] && echo '{"total_conversations":0,"total_memories":0,"last_cleanup":"'$(date -Iseconds)'"}' > "$ZBOX_MEMORY_INDEX"
    
    # Initialize conversation log
    [[ ! -f "$ZBOX_CONVERSATION_DB" ]] && touch "$ZBOX_CONVERSATION_DB"
    
    echo "✅ Memory system initialized"
}

# ============================================================================
# CONVERSATION MEMORY
# ============================================================================

# Store conversation turn
function zbox_memory_store_conversation() {
    local user_message="$1"
    local ai_response="$2"
    local model_used="${3:-primary}"
    local timestamp=$(date -Iseconds)
    local conversation_id="${4:-$ZBOX_SESSION_ID}"
    
    # Create conversation entry
    local entry=$(jq -n \
        --arg id "$conversation_id" \
        --arg user "$USER" \
        --arg timestamp "$timestamp" \
        --arg user_msg "$user_message" \
        --arg ai_resp "$ai_response" \
        --arg model "$model_used" \
        --arg session "$ZBOX_SESSION_ID" \
        '{
            id: $id,
            user: $user,
            timestamp: $timestamp,
            user_message: $user_msg,
            ai_response: $ai_resp,
            model_used: $model,
            session_id: $session,
            tokens: ($user_msg | length + $ai_resp | length),
            type: "conversation"
        }')
    
    # Append to conversation log (JSONL format)
    echo "$entry" >> "$ZBOX_CONVERSATION_DB"
    
    # Update conversation index
    local total_conversations=$(wc -l < "$ZBOX_CONVERSATION_DB")
    jq --arg count "$total_conversations" '.total_conversations = ($count | tonumber)' "$ZBOX_MEMORY_INDEX" > "$ZBOX_MEMORY_INDEX.tmp" && mv "$ZBOX_MEMORY_INDEX.tmp" "$ZBOX_MEMORY_INDEX"
    
    # Update active context
    zbox_memory_update_context "$user_message" "$ai_response"
    
    echo "💾 Conversation stored (ID: ${conversation_id:0:8}...)"
}

# Update active context window
function zbox_memory_update_context() {
    local user_message="$1"
    local ai_response="$2"
    
    # Read current context
    local current_context=$(jq '.active_context // []' "$ZBOX_CONTEXT_DB")
    local max_context=$(jq '.max_context // 4096' "$ZBOX_CONTEXT_DB")
    
    # Create new context entry
    local new_entry=$(jq -n \
        --arg user "$user_message" \
        --arg ai "$ai_response" \
        --arg timestamp "$(date -Iseconds)" \
        '{
            user_message: $user,
            ai_response: $ai,
            timestamp: $timestamp,
            tokens: ($user | length + $ai | length)
        }')
    
    # Add to context and trim if needed
    local updated_context=$(echo "$current_context" | jq --argjson entry "$new_entry" '. + [$entry]')
    
    # Calculate total tokens and trim if necessary
    local total_tokens=$(echo "$updated_context" | jq '[.[] | .tokens] | add // 0')
    
    while [[ $total_tokens -gt $max_context ]]; do
        updated_context=$(echo "$updated_context" | jq '.[1:]')  # Remove oldest entry
        total_tokens=$(echo "$updated_context" | jq '[.[] | .tokens] | add // 0')
    done
    
    # Update context database
    jq --argjson ctx "$updated_context" '.active_context = $ctx' "$ZBOX_CONTEXT_DB" > "$ZBOX_CONTEXT_DB.tmp" && mv "$ZBOX_CONTEXT_DB.tmp" "$ZBOX_CONTEXT_DB"
}

# Get active context for model
function zbox_memory_get_context() {
    local format="${1:-json}"
    local limit="${2:-10}"
    
    case "$format" in
        "json")
            jq --arg limit "$limit" '.active_context | .[-($limit | tonumber):]' "$ZBOX_CONTEXT_DB"
            ;;
        "text")
            jq -r --arg limit "$limit" '.active_context | .[-($limit | tonumber):] | .[] | "User: \(.user_message)\nAI: \(.ai_response)\n---"' "$ZBOX_CONTEXT_DB"
            ;;
        "prompt")
            # Format for sending to your model
            jq -r --arg limit "$limit" '.active_context | .[-($limit | tonumber):] | .[] | "Human: \(.user_message)\nAssistant: \(.ai_response)"' "$ZBOX_CONTEXT_DB" | tr '\n' ' '
            ;;
    esac
}

# ============================================================================
# LONG-TERM MEMORY
# ============================================================================

# Store important information as long-term memory
function zbox_memory_store_fact() {
    local fact="$1"
    local category="${2:-general}"
    local importance="${3:-5}"  # 1-10 scale
    local timestamp=$(date -Iseconds)
    local fact_id="fact_$(date +%s)_$RANDOM"
    
    # Read current memory
    local current_memories=$(jq '.memories // []' "$ZBOX_MEMORY_DB")
    
    # Create new memory entry
    local new_memory=$(jq -n \
        --arg id "$fact_id" \
        --arg fact "$fact" \
        --arg category "$category" \
        --arg importance "$importance" \
        --arg timestamp "$timestamp" \
        --arg session "$ZBOX_SESSION_ID" \
        '{
            id: $id,
            fact: $fact,
            category: $category,
            importance: ($importance | tonumber),
            timestamp: $timestamp,
            session_id: $session,
            access_count: 0,
            last_accessed: $timestamp
        }')
    
    # Add to memories
    local updated_memories=$(echo "$current_memories" | jq --argjson mem "$new_memory" '. + [$mem]')
    
    # Update memory database
    jq --argjson memories "$updated_memories" '.memories = $memories' "$ZBOX_MEMORY_DB" > "$ZBOX_MEMORY_DB.tmp" && mv "$ZBOX_MEMORY_DB.tmp" "$ZBOX_MEMORY_DB"
    
    # Update index
    local total_memories=$(echo "$updated_memories" | jq 'length')
    jq --arg count "$total_memories" '.total_memories = ($count | tonumber)' "$ZBOX_MEMORY_INDEX" > "$ZBOX_MEMORY_INDEX.tmp" && mv "$ZBOX_MEMORY_INDEX.tmp" "$ZBOX_MEMORY_INDEX"
    
    echo "🧠 Stored long-term memory: $fact (ID: ${fact_id:0:12}...)"
}

# Retrieve memories by category or search
function zbox_memory_recall() {
    local query="$1"
    local category="${2:-all}"
    local limit="${3:-5}"
    
    if [[ "$category" == "all" ]]; then
        # Search all memories
        jq --arg query "$query" --arg limit "$limit" '
            .memories | 
            map(select(.fact | test($query; "i"))) |
            sort_by(.importance, .access_count) |
            reverse |
            .[:($limit | tonumber)] |
            .[] |
            {id: .id, fact: .fact, category: .category, importance: .importance}
        ' "$ZBOX_MEMORY_DB"
    else
        # Search within category
        jq --arg query "$query" --arg category "$category" --arg limit "$limit" '
            .memories | 
            map(select(.category == $category and (.fact | test($query; "i")))) |
            sort_by(.importance, .access_count) |
            reverse |
            .[:($limit | tonumber)] |
            .[] |
            {id: .id, fact: .fact, category: .category, importance: .importance}
        ' "$ZBOX_MEMORY_DB"
    fi
}

# ============================================================================
# USER PREFERENCES & PERSONALIZATION
# ============================================================================

# Store user preference
function zbox_memory_set_preference() {
    local key="$1"
    local value="$2"
    
    jq --arg key "$key" --arg value "$value" --arg timestamp "$(date -Iseconds)" '
        .[$key] = $value |
        .last_updated = $timestamp
    ' "$ZBOX_PREFERENCES_DB" > "$ZBOX_PREFERENCES_DB.tmp" && mv "$ZBOX_PREFERENCES_DB.tmp" "$ZBOX_PREFERENCES_DB"
    
    echo "⚙️ Preference updated: $key = $value"
}

# Get user preference
function zbox_memory_get_preference() {
    local key="$1"
    local default="${2:-null}"
    
    jq -r --arg key "$key" --arg default "$default" '.[$key] // $default' "$ZBOX_PREFERENCES_DB"
}

# Learn from user behavior
function zbox_memory_learn_from_interaction() {
    local user_message="$1"
    local ai_response="$2"
    local user_feedback="${3:-neutral}"  # positive, negative, neutral
    
    # Analyze patterns in user messages
    local word_count=$(echo "$user_message" | wc -w)
    local message_length=$(echo "$user_message" | wc -c)
    local time_of_day=$(date +%H)
    
    # Update user interaction patterns
    local pattern=$(jq -n \
        --arg feedback "$user_feedback" \
        --arg word_count "$word_count" \
        --arg msg_length "$message_length" \
        --arg time "$time_of_day" \
        --arg timestamp "$(date -Iseconds)" \
        '{
            feedback: $feedback,
            word_count: ($word_count | tonumber),
            message_length: ($msg_length | tonumber),
            time_of_day: ($time | tonumber),
            timestamp: $timestamp
        }')
    
    # Store learning pattern
    echo "$pattern" >> "$ZBOX_MEMORY_PATH/interaction_patterns.jsonl"
}

# ============================================================================
# MEMORY SEARCH & RETRIEVAL
# ============================================================================

# Enhanced chat function with memory
function zbox_chat_with_memory() {
    local prompt="$*"
    local model_type="${ZBOX_MODEL:-primary}"
    
    if [[ -z "$prompt" ]]; then
        echo "💬 Usage: zbox_chat_with_memory <your message>"
        return 1
    fi
    
    echo "🧠 Retrieving relevant memories..."
    
    # Get relevant context and memories
    local context=$(zbox_memory_get_context "prompt" 5)
    local relevant_memories=$(zbox_memory_recall "$prompt" "all" 3 | jq -r '.fact // empty' | head -3)
    
    # Build enhanced prompt with memory
    local enhanced_prompt="Context from previous conversations:
$context

Relevant memories about user:
$relevant_memories

Current user message: $prompt"
    
    echo "🤖 Processing with enhanced context..."
    
    # Call your Rust binary with enhanced context
    local response
    response=$(ZBOX_SESSION="$ZBOX_SESSION_ID" \
               ZBOX_USER="$USER" \
               ZBOX_API_KEY="$ZBOX_API_KEY" \
               ZBOX_CONTEXT="$context" \
               "$ZBOX_HOME/bin/rust_llama_binary" \
               --prompt "$enhanced_prompt" \
               --session "$ZBOX_SESSION_ID" \
               --user "$USER" \
               --context-enabled \
               --output-format "zbox")
    
    if [[ $? -eq 0 ]]; then
        # Store the conversation
        zbox_memory_store_conversation "$prompt" "$response" "$model_type"
        
        # Format and display
        zbox_format_response "$response"
        
        # Extract any important facts from the conversation
        zbox_memory_extract_facts "$prompt" "$response"
        
        return 0
    else
        echo "❌ Model interaction failed"
        return 1
    fi
}

# Extract and store important facts from conversations
function zbox_memory_extract_facts() {
    local user_message="$1"
    local ai_response="$2"
    
    # Simple fact extraction (you can make this more sophisticated)
    # Look for patterns like "I am...", "I like...", "My name is...", etc.
    
    if echo "$user_message" | grep -qi "my name is\|I am\|I'm called"; then
        local fact=$(echo "$user_message" | grep -oi "my name is [^.]*\|I am [^.]*\|I'm called [^.]*")
        [[ -n "$fact" ]] && zbox_memory_store_fact "$fact" "personal" 8
    fi
    
    if echo "$user_message" | grep -qi "I like\|I love\|I prefer\|I hate"; then
        local fact=$(echo "$user_message" | grep -oi "I like [^.]*\|I love [^.]*\|I prefer [^.]*\|I hate [^.]*")
        [[ -n "$fact" ]] && zbox_memory_store_fact "$fact" "preferences" 6
    fi
    
    if echo "$user_message" | grep -qi "I work\|my job\|I'm a\|I am a"; then
        local fact=$(echo "$user_message" | grep -oi "I work [^.]*\|my job [^.]*\|I'm a [^.]*\|I am a [^.]*")
        [[ -n "$fact" ]] && zbox_memory_store_fact "$fact" "professional" 7
    fi
}

# ============================================================================
# MEMORY MANAGEMENT COMMANDS
# ============================================================================

function zbox_memory_status() {
    echo "🧠 ZBOX Memory Status for $USER:"
    echo ""
    
    # Get stats from index
    local stats=$(cat "$ZBOX_MEMORY_INDEX")
    local total_conversations=$(echo "$stats" | jq -r '.total_conversations')
    local total_memories=$(echo "$stats" | jq -r '.total_memories')
    
    # Context stats
    local context_size=$(jq '.active_context | length' "$ZBOX_CONTEXT_DB")
    local context_tokens=$(jq '[.active_context[] | .tokens] | add // 0' "$ZBOX_CONTEXT_DB")
    
    echo "  📊 Conversations: $total_conversations"
    echo "  🧠 Long-term memories: $total_memories"
    echo "  💭 Active context size: $context_size entries ($context_tokens tokens)"
    echo ""
    
    # Memory usage by category
    echo "  📂 Memory categories:"
    jq -r '.memories | group_by(.category) | .[] | "\(.length) \(.[0].category)"' "$ZBOX_MEMORY_DB" | while read count category; do
        echo "    - $category: $count memories"
    done
}

function zbox_memory_search() {
    local query="$1"
    local limit="${2:-10}"
    
    if [[ -z "$query" ]]; then
        echo "Usage: zbox_memory_search <query> [limit]"
        return 1
    fi
    
    echo "🔍 Searching memories for: '$query'"
    echo ""
    
    # Search conversations
    echo "📝 Recent conversations:"
    grep -i "$query" "$ZBOX_CONVERSATION_DB" | tail -5 | jq -r '"\(.timestamp) - \(.user_message | .[0:100])..."' | head -3
    
    echo ""
    
    # Search long-term memories
    echo "🧠 Long-term memories:"
    zbox_memory_recall "$query" "all" "$limit" | jq -r '"[\(.category)] \(.fact)"' | head -5
}

function zbox_memory_cleanup() {
    echo "🧹 Cleaning up memory..."
    
    # Archive old conversations (older than 30 days)
    local cutoff_date=$(date -d "30 days ago" -Iseconds)
    local archive_file="$ZBOX_MEMORY_PATH/conversations_archive_$(date +%Y%m%d).jsonl"
    
    # Move old conversations to archive
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | jq -r '.timestamp')
        if [[ "$timestamp" < "$cutoff_date" ]]; then
            echo "$line" >> "$archive_file"
        else
            echo "$line" >> "$ZBOX_CONVERSATION_DB.tmp"
        fi
    done < "$ZBOX_CONVERSATION_DB"
    
    [[ -f "$ZBOX_CONVERSATION_DB.tmp" ]] && mv "$ZBOX_CONVERSATION_DB.tmp" "$ZBOX_CONVERSATION_DB"
    
    # Update cleanup timestamp
    jq --arg timestamp "$(date -Iseconds)" '.last_cleanup = $timestamp' "$ZBOX_MEMORY_INDEX" > "$ZBOX_MEMORY_INDEX.tmp" && mv "$ZBOX_MEMORY_INDEX.tmp" "$ZBOX_MEMORY_INDEX"
    
    echo "✅ Memory cleanup complete"
}

# ============================================================================
# MEMORY ALIASES
# ============================================================================

alias memory='zbox_memory_status'
alias remember='zbox_memory_store_fact'
alias recall='zbox_memory_search'
alias forget='zbox_memory_cleanup'
alias chat_smart='zbox_chat_with_memory'
alias set_pref='zbox_memory_set_preference'
alias get_pref='zbox_memory_get_preference'

echo "🧠 ZBOX Memory System Loaded!"