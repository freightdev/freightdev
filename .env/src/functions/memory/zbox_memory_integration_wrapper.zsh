#!/bin/zsh
# ZBOX Memory Integration Wrapper
# Connects ZSH shell to PostgreSQL memory system

export ZBOX_MEMORY_BACKEND="${ZBOX_MEMORY_BACKEND:-postgres}"  # postgres or json
export ZBOX_POSTGRES_INTERFACE="$ZBOX_HOME/bin/zbox_postgres_interface.py"

# ============================================================================
# MEMORY BACKEND DETECTION
# ============================================================================

function zbox_memory_backend_check() {
    if [[ "$ZBOX_MEMORY_BACKEND" == "postgres" ]]; then
        # Check if PostgreSQL interface is available
        if [[ -f "$ZBOX_POSTGRES_INTERFACE" ]] && python3 -c "import asyncpg" 2>/dev/null; then
            export ZBOX_MEMORY_ENABLED=true
            export ZBOX_MEMORY_TYPE="postgres"
            echo "🐘 PostgreSQL memory backend enabled"
        else
            echo "⚠️  PostgreSQL backend not available, falling back to JSON"
            export ZBOX_MEMORY_BACKEND="json"
            export ZBOX_MEMORY_TYPE="json"
            zbox_memory_init  # Initialize JSON backend
        fi
    else
        export ZBOX_MEMORY_TYPE="json"
        zbox_memory_init  # Initialize JSON backend
    fi
}

# ============================================================================
# UNIFIED MEMORY INTERFACE
# ============================================================================

# Store conversation with automatic backend selection
function zbox_memory_store_conversation_unified() {
    local user_message="$1"
    local ai_response="$2"
    local model_used="${3:-primary}"
    local conversation_id="${4:-$ZBOX_SESSION_ID}"
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        # Use PostgreSQL backend
        local result
        result=$(python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import cli_store_conversation

async def main():
    result = await cli_store_conversation('$USER', '$ZBOX_SESSION_ID', '''$user_message''', '''$ai_response''', '$model_used')
    print(f'Stored conversation: {result}')

asyncio.run(main())
" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            echo "🐘 $result"
        else
            echo "❌ PostgreSQL storage failed, falling back to JSON"
            zbox_memory_store_conversation "$user_message" "$ai_response" "$model_used" "$conversation_id"
        fi
    else
        # Use JSON backend
        zbox_memory_store_conversation "$user_message" "$ai_response" "$model_used" "$conversation_id"
    fi
}

# Recall memories with backend selection
function zbox_memory_recall_unified() {
    local query="$1"
    local limit="${2:-5}"
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        # Use PostgreSQL backend
        python3 -c "
import asyncio
import sys
import json
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import cli_recall_memories

async def main():
    memories = await cli_recall_memories('$USER', '''$query''', $limit)
    for memory in memories:
        category = memory['category'].upper().ljust(12)
        score = f\"{memory['similarity_score']:.2f}\"
        fact = memory['fact'][:80] + '...' if len(memory['fact']) > 80 else memory['fact']
        print(f'  🧠 [{category}] {fact} (score: {score})')

asyncio.run(main())
" 2>/dev/null
    else
        # Use JSON backend
        zbox_memory_recall "$query" "all" "$limit"
    fi
}

# Get enhanced context for model
function zbox_memory_get_enhanced_context() {
    local current_message="$1"
    local format="${2:-prompt}"
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        # Use PostgreSQL backend
        python3 -c "
import asyncio
import sys
import json
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import cli_get_context

async def main():
    context = await cli_get_context('$USER', '$ZBOX_SESSION_ID', '''$current_message''')
    
    if '$format' == 'json':
        print(json.dumps(context, indent=2, default=str))
    elif '$format' == 'prompt':
        # Format for model consumption
        history = context.get('conversation_history', [])
        memories = context.get('relevant_memories', [])
        
        print('Previous conversation:')
        for turn in history[-3:]:  # Last 3 turns
            print(f\"Human: {turn['user_message']}\")
            print(f\"Assistant: {turn['ai_response'][:100]}...\")
        
        if memories:
            print('\nRelevant memories:')
            for memory in memories[:3]:  # Top 3 memories
                print(f\"- {memory['fact']}\")

asyncio.run(main())
" 2>/dev/null
    else
        # Use JSON backend
        if [[ "$format" == "json" ]]; then
            zbox_memory_get_context "json"
        else
            zbox_memory_get_context "prompt"
        fi
    fi
}

# Get user statistics
function zbox_memory_user_stats() {
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        python3 -c "
import asyncio
import sys
import json
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import cli_user_stats

async def main():
    stats = await cli_user_stats('$USER')
    
    print('🧠 ZBOX Memory Statistics:')
    print(f'  📊 Total Conversations: {stats.get(\"total_conversations\", 0)}')
    print(f'  🧠 Total Memories: {stats.get(\"total_memories\", 0)}')
    print(f'  💭 Active Context: {stats.get(\"active_context_entries\", 0)} entries ({stats.get(\"active_context_tokens\", 0)} tokens)')
    print(f'  📈 Recent Activity (24h): {stats.get(\"recent_conversations_24h\", 0)} conversations')
    
    categories = stats.get('memory_categories', [])
    if categories:
        print('  📂 Memory Categories:')
        for cat in categories[:5]:  # Top 5 categories
            print(f'    - {cat[\"category\"]}: {cat[\"count\"]} memories (avg importance: {cat[\"avg_importance\"]:.1f})')

asyncio.run(main())
" 2>/dev/null
    else
        zbox_memory_status
    fi
}

# ============================================================================
# ENHANCED CHAT WITH MEMORY
# ============================================================================

function zbox_chat_with_smart_memory() {
    local prompt="$*"
    local model_type="${ZBOX_MODEL:-primary}"
    
    if [[ -z "$prompt" ]]; then
        echo "💬 Usage: zbox_chat_with_smart_memory <your message>"
        return 1
    fi
    
    echo "🧠 Retrieving enhanced context..."
    
    # Get enhanced context from appropriate backend
    local context_file="/tmp/zbox_context_${ZBOX_SESSION_ID}.txt"
    zbox_memory_get_enhanced_context "$prompt" "prompt" > "$context_file"
    
    # Build enhanced prompt
    local enhanced_prompt="ZBOX User Context for $USER:

$(cat "$context_file")

Current user message: $prompt

Instructions: Use the above context to provide a personalized, contextually aware response. Reference previous conversations and stored memories when relevant."
    
    echo "🤖 Processing with enhanced memory context..."
    
    # Call your Rust binary with enhanced context
    local response
    local start_time=$(date +%s%3N)
    
    response=$(ZBOX_SESSION="$ZBOX_SESSION_ID" \
               ZBOX_USER="$USER" \
               ZBOX_API_KEY="$ZBOX_API_KEY" \
               ZBOX_MEMORY_ENABLED="true" \
               ZBOX_CONTEXT_FILE="$context_file" \
               "$ZBOX_HOME/bin/rust_llama_binary" \
               --prompt "$enhanced_prompt" \
               --session "$ZBOX_SESSION_ID" \
               --user "$USER" \
               --context-enabled \
               --max-tokens "${ZBOX_MAX_TOKENS:-512}" \
               --temperature "${ZBOX_TEMPERATURE:-0.7}" \
               --output-format "zbox")
    
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        # Store the conversation with timing
        zbox_memory_store_conversation_unified "$prompt" "$response" "$model_type"
        
        # Extract and store important facts
        zbox_extract_and_store_facts "$prompt" "$response"
        
        # Format and display
        zbox_format_memory_response "$response" "$response_time"
        
        # Clean up temp file
        rm -f "$context_file"
        
        return 0
    else
        echo "❌ Model interaction failed"
        rm -f "$context_file"
        return 1
    fi
}

# Enhanced response formatting with memory indicators
function zbox_format_memory_response() {
    local response="$1"
    local response_time_ms="${2:-0}"
    local backend_indicator
    
    case "$ZBOX_MEMORY_TYPE" in
        "postgres") backend_indicator="🐘" ;;
        "json") backend_indicator="📄" ;;
        *) backend_indicator="🤖" ;;
    esac
    
    echo ""
    echo "╭─────────────────────────────────────────────╮"
    echo "│  $backend_indicator ZBOX AI Response (Memory-Enhanced)  │"
    echo "├─────────────────────────────────────────────┤"
    
    # Pretty print the response with word wrapping
    echo "$response" | fold -s -w 45 | sed 's/^/│  /'
    
    echo "├─────────────────────────────────────────────┤"
    echo "│  Session: ${ZBOX_SESSION_ID:0:12}...        │"
    echo "│  User: $USER | Backend: $ZBOX_MEMORY_TYPE | ${response_time_ms}ms │"
    echo "│  $(date '+%Y-%m-%d %H:%M:%S') | Memory: ✅     │"
    echo "╰─────────────────────────────────────────────╯"
    echo ""
}

# ============================================================================
# INTELLIGENT FACT EXTRACTION
# ============================================================================

function zbox_extract_and_store_facts() {
    local user_message="$1"
    local ai_response="$2"
    
    # Enhanced fact extraction patterns
    local facts_found=()
    
    # Personal information patterns
    if echo "$user_message" | grep -qi "my name is\|I'm called\|call me\|I am .*"; then
        local name_fact=$(echo "$user_message" | grep -oi "my name is [^.]*\|I'm called [^.]*\|call me [^.]*\|I am [a-zA-Z ]*" | head -1)
        [[ -n "$name_fact" ]] && facts_found+=("personal:$name_fact")
    fi
    
    # Preferences and interests
    if echo "$user_message" | grep -qi "I like\|I love\|I prefer\|I hate\|I dislike\|my favorite"; then
        local pref_fact=$(echo "$user_message" | grep -oi "I like [^.]*\|I love [^.]*\|I prefer [^.]*\|I hate [^.]*\|I dislike [^.]*\|my favorite [^.]*" | head -1)
        [[ -n "$pref_fact" ]] && facts_found+=("preferences:$pref_fact")
    fi
    
    # Work and professional information
    if echo "$user_message" | grep -qi "I work\|my job\|I'm a\|I am a\|I do\|my company"; then
        local work_fact=$(echo "$user_message" | grep -oi "I work [^.]*\|my job [^.]*\|I'm a [^.]*\|I am a [^.]*\|I do [^.]*\|my company [^.]*" | head -1)
        [[ -n "$work_fact" ]] && facts_found+=("professional:$work_fact")
    fi
    
    # Location information
    if echo "$user_message" | grep -qi "I live\|I'm from\|I am from\|my city\|my country"; then
        local location_fact=$(echo "$user_message" | grep -oi "I live [^.]*\|I'm from [^.]*\|I am from [^.]*\|my city [^.]*\|my country [^.]*" | head -1)
        [[ -n "$location_fact" ]] && facts_found+=("location:$location_fact")
    fi
    
    # Technical skills and tools
    if echo "$user_message" | grep -qi "I use\|I know\|I'm learning\|I'm good at\|I program in"; then
        local tech_fact=$(echo "$user_message" | grep -oi "I use [^.]*\|I know [^.]*\|I'm learning [^.]*\|I'm good at [^.]*\|I program in [^.]*" | head -1)
        [[ -n "$tech_fact" ]] && facts_found+=("technical:$tech_fact")
    fi
    
    # Store extracted facts
    for fact_entry in "${facts_found[@]}"; do
        local category="${fact_entry%%:*}"
        local fact="${fact_entry#*:}"
        
        if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
            python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    memory_id = await zbox_db.store_memory('$USER', '''$fact''', '$category', 7)
    print(f'📝 Stored fact: {memory_id}')

asyncio.run(main())
" 2>/dev/null && echo "🧠 Auto-learned: [$category] $fact"
        else
            zbox_memory_store_fact "$fact" "$category" 7
        fi
    done
}

# ============================================================================
# MEMORY SEARCH AND MANAGEMENT COMMANDS
# ============================================================================

function zbox_memory_search_unified() {
    local query="$1"
    local limit="${2:-10}"
    
    if [[ -z "$query" ]]; then
        echo "Usage: zbox_memory_search <query> [limit]"
        return 1
    fi
    
    echo "🔍 Searching memories for: '$query'"
    echo ""
    
    # Search using appropriate backend
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        echo "📊 PostgreSQL Results:"
        zbox_memory_recall_unified "$query" "$limit"
        
        echo ""
        echo "📝 Recent Conversations:"
        python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    user = await zbox_db.get_user('$USER')
    if user:
        async with zbox_db.pool.acquire() as conn:
            conversations = await conn.fetch('''
                SELECT user_message, ai_response, timestamp 
                FROM zbox_conversations 
                WHERE user_id = \$1 
                AND (to_tsvector('english', user_message || ' ' || ai_response) @@ plainto_tsquery('english', \$2))
                ORDER BY timestamp DESC 
                LIMIT 3
            ''', user['id'], '''$query''')
            
            for conv in conversations:
                timestamp = conv['timestamp'].strftime('%Y-%m-%d %H:%M')
                user_msg = conv['user_message'][:60] + '...' if len(conv['user_message']) > 60 else conv['user_message']
                print(f'  💬 [{timestamp}] {user_msg}')

asyncio.run(main())
" 2>/dev/null
    else
        zbox_memory_search "$query" "$limit"
    fi
}

function zbox_memory_categories() {
    echo "📂 Memory Categories:"
    echo ""
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    categories = await zbox_db.get_memory_categories('$USER')
    for cat in categories:
        category = cat['category'].upper().ljust(15)
        count = str(cat['count']).rjust(3)
        avg_imp = f\"{cat['avg_importance']:.1f}\"
        print(f'  📁 {category} {count} memories (avg importance: {avg_imp})')

asyncio.run(main())
" 2>/dev/null
    else
        jq -r '.memories | group_by(.category) | .[] | "\(.length) \(.[0].category)"' "$ZBOX_MEMORY_DB" | while read count category; do
            printf "  📁 %-15s %3d memories\n" "${category^^}" "$count"
        done
    fi
}

# ============================================================================
# MEMORY PERFORMANCE MONITORING
# ============================================================================

function zbox_memory_performance() {
    echo "⚡ ZBOX Memory Performance:"
    echo ""
    
    # Test memory backend response time
    local start_time=$(date +%s%3N)
    zbox_memory_recall_unified "test query" 1 > /dev/null 2>&1
    local end_time=$(date +%s%3N)
    local recall_time=$((end_time - start_time))
    
    echo "  🔍 Memory recall time: ${recall_time}ms"
    
    # Test conversation storage time
    start_time=$(date +%s%3N)
    zbox_memory_store_conversation_unified "test message" "test response" "test" > /dev/null 2>&1
    end_time=$(date +%s%3N)
    local store_time=$((end_time - start_time))
    
    echo "  💾 Conversation storage time: ${store_time}ms"
    
    # Backend-specific performance info
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        echo "  🐘 PostgreSQL backend: Optimized for complex queries"
        python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    # Check connection pool status
    if zbox_db.pool:
        print(f'  🔗 Connection pool: {zbox_db.pool._queue.qsize()} available connections')

asyncio.run(main())
" 2>/dev/null
    else
        echo "  📄 JSON backend: Fast local storage"
        local db_size=$(du -h "$ZBOX_MEMORY_DB" 2>/dev/null | cut -f1)
        echo "  💽 Memory database size: ${db_size:-unknown}"
    fi
}

# ============================================================================
# MEMORY BACKUP AND EXPORT
# ============================================================================

function zbox_memory_export() {
    local export_format="${1:-json}"
    local output_file="${2:-zbox_memory_export_$(date +%Y%m%d_%H%M%S).$export_format}"
    
    echo "📤 Exporting memory data..."
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        python3 -c "
import asyncio
import sys
import json
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    # Export user data
    export_data = {}
    
    # Get user info
    user = await zbox_db.get_user('$USER')
    if user:
        export_data['user_info'] = dict(user)
        
        # Get conversations
        async with zbox_db.pool.acquire() as conn:
            conversations = await conn.fetch('''
                SELECT * FROM zbox_conversations 
                WHERE user_id = \$1 
                ORDER BY timestamp DESC
            ''', user['id'])
            
            export_data['conversations'] = [dict(conv) for conv in conversations]
            
            # Get memories
            memories = await conn.fetch('''
                SELECT * FROM zbox_memories 
                WHERE user_id = \$1 
                ORDER BY created_at DESC
            ''', user['id'])
            
            export_data['memories'] = [dict(mem) for mem in memories]
    
    with open('$output_file', 'w') as f:
        json.dump(export_data, f, indent=2, default=str)
    
    print(f'✅ Memory exported to: $output_file')

asyncio.run(main())
" 2>/dev/null
    else
        # Export JSON backend data
        jq '.' "$ZBOX_MEMORY_DB" "$ZBOX_CONTEXT_DB" "$ZBOX_PREFERENCES_DB" > "$output_file"
        echo "✅ Memory exported to: $output_file"
    fi
}

# ============================================================================
# MEMORY MAINTENANCE
# ============================================================================

function zbox_memory_maintenance() {
    echo "🔧 Running memory maintenance..."
    
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    # Cleanup old data
    cleaned = await zbox_db.cleanup_old_data(30)  # 30 days
    print(f'🧹 Cleaned up {cleaned} old records')
    
    # Update statistics
    stats = await zbox_db.get_user_stats('$USER')
    print(f'📊 Current stats: {stats.get(\"total_conversations\", 0)} conversations, {stats.get(\"total_memories\", 0)} memories')

asyncio.run(main())
" 2>/dev/null
    else
        zbox_memory_cleanup
    fi
    
    echo "✅ Memory maintenance completed"
}

# ============================================================================
# ENHANCED ALIASES AND SHORTCUTS
# ============================================================================

# Memory-enhanced aliases
alias smart_chat='zbox_chat_with_smart_memory'
alias chat_smart='zbox_chat_with_smart_memory'
alias remember_search='zbox_memory_search_unified'
alias memory_stats='zbox_memory_user_stats'
alias memory_perf='zbox_memory_performance'
alias memory_export='zbox_memory_export'
alias memory_backup='zbox_memory_export'
alias memory_categories='zbox_memory_categories'
alias memory_maintenance='zbox_memory_maintenance'

# Quick memory operations
alias quick_recall='zbox_memory_recall_unified'
alias store_fact='zbox_memory_store_fact'

# Backend switching
alias memory_backend='echo "Current backend: $ZBOX_MEMORY_TYPE"'
alias switch_to_postgres='export ZBOX_MEMORY_BACKEND=postgres && zbox_memory_backend_check'
alias switch_to_json='export ZBOX_MEMORY_BACKEND=json && zbox_memory_backend_check'

# ============================================================================
# MEMORY SYSTEM INITIALIZATION
# ============================================================================

function zbox_memory_system_init() {
    echo "🧠 Initializing ZBOX Memory System..."
    
    # Check and initialize backend
    zbox_memory_backend_check
    
    # Create necessary directories
    mkdir -p "$ZBOX_MEMORY_PATH"/{backups,exports,temp}
    
    # Initialize user session
    if [[ "$ZBOX_MEMORY_TYPE" == "postgres" ]]; then
        python3 -c "
import asyncio
import sys
sys.path.append('$ZBOX_HOME/bin')
from zbox_postgres_interface import zbox_db

async def main():
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    # Create user and session
    await zbox_db.create_user('$USER')
    await zbox_db.create_session('$USER', '$ZBOX_SESSION_ID', '$ZBOX_API_KEY')
    print('✅ PostgreSQL user session initialized')

asyncio.run(main())
" 2>/dev/null
    else
        # Initialize JSON backend if not already done
        [[ -z "$ZBOX_MEMORY_INITIALIZED" ]] && zbox_memory_init
    fi
    
    export ZBOX_MEMORY_SYSTEM_INITIALIZED=1
    echo "✅ Memory system ready: $ZBOX_MEMORY_TYPE backend"
}

# Auto-initialize if not already done
if [[ -z "$ZBOX_MEMORY_SYSTEM_INITIALIZED" ]]; then
    zbox_memory_system_init
fi

echo "🧠 ZBOX Memory System Loaded ($ZBOX_MEMORY_TYPE backend)!"