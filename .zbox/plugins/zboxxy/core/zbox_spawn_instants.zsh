#!/bin/zsh
# ZBOX Instant Model Spawning System
# Models spawn INSTANTLY when needed, die INSTANTLY when done

# ============================================================================
# INSTANT MODEL ARCHITECTURE
# ============================================================================

export ZBOX_MODEL_POOL_SIZE=3          # Max concurrent model instances
export ZBOX_MODEL_WARMUP_ENABLED=true  # Keep models pre-warmed
export ZBOX_MODEL_SPAWN_TIMEOUT=2      # Max seconds to spawn
export ZBOX_MODEL_IDLE_TIMEOUT=30      # Kill model after 30s idle
export ZBOX_MODEL_PRELOAD_CONTEXT=true # Preload common contexts

# Model instance tracking
typeset -gA ZBOX_MODEL_INSTANCES        # Active model processes
typeset -gA ZBOX_MODEL_SPAWN_QUEUE      # Models being spawned
typeset -gA ZBOX_MODEL_LAST_USED        # Last access time
typeset -gA ZBOX_MODEL_WARMUP_POOL      # Pre-warmed models

export ZBOX_MODEL_BINARY="$ZBOX_HOME/bin/rust_llama_binary"
export ZBOX_MODEL_SOCKETS_DIR="$ZBOX_HOME/sockets"

# ============================================================================
# INSTANT MODEL SPAWNING ENGINE
# ============================================================================

function zbox_model_spawn_instant() {
    local user="$1"
    local model_type="${2:-primary}"
    local priority="${3:-normal}"  # high, normal, low
    
    echo "⚡ Spawning INSTANT model for $user..."
    
    # Check if model already exists and is warm
    local instance_key="${user}_${model_type}"
    local existing_instance="${ZBOX_MODEL_INSTANCES[$instance_key]}"
    
    if [[ -n "$existing_instance" ]]; then
        local pid="${existing_instance%%:*}"
        if kill -0 "$pid" 2>/dev/null; then
            echo "🔥 Model already running: PID $pid"
            # Update last used time
            ZBOX_MODEL_LAST_USED[$instance_key]=$(date +%s)
            echo "$pid"
            return 0
        else
            # Clean up dead instance
            unset "ZBOX_MODEL_INSTANCES[$instance_key]"
        fi
    fi
    
    # Check warmup pool for pre-spawned instance
    local warmup_instance="${ZBOX_MODEL_WARMUP_POOL[$model_type]}"
    if [[ -n "$warmup_instance" && "$ZBOX_MODEL_WARMUP_ENABLED" == "true" ]]; then
        local warmup_pid="${warmup_instance%%:*}"
        if kill -0 "$warmup_pid" 2>/dev/null; then
            echo "🚀 Using pre-warmed model: PID $warmup_pid"
            
            # Move from warmup pool to active instances
            ZBOX_MODEL_INSTANCES[$instance_key]="$warmup_instance"
            unset "ZBOX_MODEL_WARMUP_POOL[$model_type]"
            ZBOX_MODEL_LAST_USED[$instance_key]=$(date +%s)
            
            # Spawn replacement for warmup pool
            zbox_model_warmup_spawn "$model_type" &
            
            echo "$warmup_pid"
            return 0
        fi
    fi
    
    # Spawn new instance INSTANTLY
    local socket_path="$ZBOX_MODEL_SOCKETS_DIR/${user}_${model_type}.sock"
    local start_time=$(date +%s%3N)
    
    echo "🚀 Spawning new model instance..."
    
    # Your Rust binary with instant startup parameters
    local model_pid
    {
        # Run model in background with socket communication
        "$ZBOX_MODEL_BINARY" \
            --mode "daemon" \
            --socket "$socket_path" \
            --user "$user" \
            --model-type "$model_type" \
            --instant-mode \
            --preload-embeddings \
            --memory-map-model \
            --threads $(nproc) \
            --batch-size 1 \
            --ctx-size 4096 \
            --no-warmup \
            --fast-startup &
        
        model_pid=$!
        echo $model_pid > "$ZBOX_MODEL_SOCKETS_DIR/${user}_${model_type}.pid"
    }
    
    # Wait for socket to be ready (should be INSTANT)
    local timeout_count=0
    while [[ ! -S "$socket_path" && $timeout_count -lt 20 ]]; do
        sleep 0.1  # 100ms intervals
        ((timeout_count++))
    done
    
    local end_time=$(date +%s%3N)
    local spawn_time=$((end_time - start_time))
    
    if [[ -S "$socket_path" ]]; then
        # Store instance info
        ZBOX_MODEL_INSTANCES[$instance_key]="$model_pid:$socket_path:$(date +%s)"
        ZBOX_MODEL_LAST_USED[$instance_key]=$(date +%s)
        
        echo "✅ Model spawned in ${spawn_time}ms - PID: $model_pid"
        echo "   🔌 Socket: $socket_path"
        
        # Set up auto-cleanup timer
        zbox_model_auto_cleanup "$instance_key" &
        
        echo "$model_pid"
        return 0
    else
        echo "❌ Model spawn failed after ${spawn_time}ms"
        kill $model_pid 2>/dev/null
        return 1
    fi
}

# ============================================================================
# INSTANT MODEL COMMUNICATION
# ============================================================================

function zbox_model_call_instant() {
    local user="$1"
    local prompt="$2"
    local model_type="${3:-primary}"
    local max_tokens="${4:-512}"
    
    echo "💬 Instant model call for $user..."
    
    # Spawn model if needed (INSTANT)
    local model_pid
    model_pid=$(zbox_model_spawn_instant "$user" "$model_type")
    
    if [[ -z "$model_pid" ]]; then
        echo "❌ Failed to spawn model"
        return 1
    fi
    
    # Get socket path
    local instance_key="${user}_${model_type}"
    local instance_data="${ZBOX_MODEL_INSTANCES[$instance_key]}"
    local socket_path="${instance_data#*:}"
    socket_path="${socket_path%:*}"
    
    echo "🔌 Using socket: $socket_path"
    
    # Send prompt via socket (INSTANT communication)
    local start_time=$(date +%s%3N)
    local response
    
    # Use netcat for instant socket communication
    response=$(echo "{\"prompt\":\"$prompt\",\"max_tokens\":$max_tokens,\"user\":\"$user\"}" | nc -U "$socket_path" -w 30 2>/dev/null)
    
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [[ -n "$response" ]]; then
        echo "⚡ Response received in ${response_time}ms"
        
        # Update last used time
        ZBOX_MODEL_LAST_USED[$instance_key]=$(date +%s)
        
        # Parse response (assuming JSON)
        local ai_response=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)
        if [[ -z "$ai_response" ]]; then
            ai_response="$response"  # Fallback to raw response
        fi
        
        echo "$ai_response"
        return 0
    else
        echo "❌ No response from model"
        return 1
    fi
}

# ============================================================================
# MODEL WARMUP POOL SYSTEM
# ============================================================================

function zbox_model_warmup_spawn() {
    local model_type="${1:-primary}"
    
    if [[ "$ZBOX_MODEL_WARMUP_ENABLED" != "true" ]]; then
        return 0
    fi
    
    echo "🔥 Pre-warming model: $model_type"
    
    # Check if already have warmup instance
    if [[ -n "${ZBOX_MODEL_WARMUP_POOL[$model_type]}" ]]; then
        local existing_pid="${ZBOX_MODEL_WARMUP_POOL[$model_type]%%:*}"
        if kill -0 "$existing_pid" 2>/dev/null; then
            return 0  # Already have warm instance
        fi
    fi
    
    # Spawn warmup instance
    local warmup_socket="$ZBOX_MODEL_SOCKETS_DIR/warmup_${model_type}.sock"
    
    {
        "$ZBOX_MODEL_BINARY" \
            --mode "daemon" \
            --socket "$warmup_socket" \
            --model-type "$model_type" \
            --warmup-mode \
            --memory-map-model \
            --preload-embeddings \
            --idle-timeout $ZBOX_MODEL_IDLE_TIMEOUT &
        
        local warmup_pid=$!
        
        # Wait for warmup to complete
        sleep 2
        
        if kill -0 "$warmup_pid" 2>/dev/null && [[ -S "$warmup_socket" ]]; then
            ZBOX_MODEL_WARMUP_POOL[$model_type]="$warmup_pid:$warmup_socket:$(date +%s)"
            echo "🔥 Warmup complete for $model_type: PID $warmup_pid"
        else
            echo "❌ Warmup failed for $model_type"
        fi
    } &
}

# Initialize warmup pool
function zbox_warmup_pool_init() {
    echo "🔥 Initializing model warmup pool..."
    
    for model_type in primary secondary code web_search; do
        zbox_model_warmup_spawn "$model_type" &
    done
    
    wait  # Wait for all warmups to complete
    echo "✅ Warmup pool initialized"
}

# ============================================================================
# INSTANT MODEL CLEANUP
# ============================================================================

function zbox_model_auto_cleanup() {
    local instance_key="$1"
    
    # Background cleanup process
    {
        while true; do
            sleep 10  # Check every 10 seconds
            
            local instance_data="${ZBOX_MODEL_INSTANCES[$instance_key]}"
            if [[ -z "$instance_data" ]]; then
                break  # Instance removed
            fi
            
            local last_used="${ZBOX_MODEL_LAST_USED[$instance_key]}"
            local current_time=$(date +%s)
            local idle_time=$((current_time - last_used))
            
            if [[ $idle_time -gt $ZBOX_MODEL_IDLE_TIMEOUT ]]; then
                echo "💀 Auto-killing idle model: $instance_key (idle for ${idle_time}s)"
                zbox_model_kill_instant "$instance_key"
                break
            fi
        done
    } &
}

function zbox_model_kill_instant() {
    local instance_key="$1"
    
    local instance_data="${ZBOX_MODEL_INSTANCES[$instance_key]}"
    if [[ -z "$instance_data" ]]; then
        echo "❌ Instance not found: $instance_key"
        return 1
    fi
    
    local pid="${instance_data%%:*}"
    local socket_path="${instance_data#*:}"
    socket_path="${socket_path%:*}"
    
    echo "💀 Killing model instance: $instance_key (PID: $pid)"
    
    # Graceful shutdown first
    kill -TERM "$pid" 2>/dev/null
    sleep 1
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null
        echo "🔨 Force killed: $pid"
    fi
    
    # Cleanup socket and files
    rm -f "$socket_path"
    rm -f "$ZBOX_MODEL_SOCKETS_DIR/${instance_key}.pid"
    
    # Remove from tracking
    unset "ZBOX_MODEL_INSTANCES[$instance_key]"
    unset "ZBOX_MODEL_LAST_USED[$instance_key]"
    
    echo "✅ Model instance cleaned up: $instance_key"
}

function zbox_model_kill_all() {
    echo "💀 Killing all model instances..."
    
    # Kill active instances
    for instance_key in ${(k)ZBOX_MODEL_INSTANCES}; do
        zbox_model_kill_instant "$instance_key"
    done
    
    # Kill warmup pool
    for model_type in ${(k)ZBOX_MODEL_WARMUP_POOL}; do
        local warmup_data="${ZBOX_MODEL_WARMUP_POOL[$model_type]}"
        local pid="${warmup_data%%:*}"
        kill -TERM "$pid" 2>/dev/null
        unset "ZBOX_MODEL_WARMUP_POOL[$model_type]"
    done
    
    # Cleanup socket directory
    rm -f "$ZBOX_MODEL_SOCKETS_DIR"/*.sock
    rm -f "$ZBOX_MODEL_SOCKETS_DIR"/*.pid
    
    echo "✅ All model instances killed"
}

# ============================================================================
# INSTANT CHAT INTEGRATION
# ============================================================================

function zbox_chat_instant() {
    local prompt="$*"
    local user="${ZBOX_CURRENT_USER:-$USER}"
    local model_type="${ZBOX_MODEL:-primary}"
    
    if [[ -z "$prompt" ]]; then
        echo "💬 Usage: zbox_chat_instant <your message>"
        return 1
    fi
    
    echo "⚡ INSTANT CHAT for $user"
    echo "🚀 Prompt: ${prompt:0:50}..."
    
    # Call model instantly
    local response
    local start_time=$(date +%s%3N)
    
    response=$(zbox_model_call_instant "$user" "$prompt" "$model_type")
    
    local end_time=$(date +%s%3N)
    local total_time=$((end_time - start_time))
    
    if [[ -n "$response" ]]; then
        echo ""
        echo "╭─────────────────────────────────────────────╮"
        echo "│  ⚡ INSTANT ZBOX RESPONSE                  │"
        echo "├─────────────────────────────────────────────┤"
        
        echo "$response" | fold -s -w 45 | sed 's/^/│  /'
        
        echo "├─────────────────────────────────────────────┤"
        echo "│  ⚡ Total time: ${total_time}ms              │"
        echo "│  👤 User: $user | Model: $model_type       │"
        echo "│  🚀 Mode: INSTANT SPAWN                     │"
        echo "╰─────────────────────────────────────────────╯"
        echo ""
        
        return 0
    else
        echo "❌ Instant chat failed"
        return 1
    fi
}

# ============================================================================
# MODEL POOL MANAGEMENT
# ============================================================================

function zbox_model_pool_status() {
    echo "🏊 ZBOX Model Pool Status"
    echo ""
    
    # Active instances
    echo "🔥 Active Model Instances:"
    if [[ ${#ZBOX_MODEL_INSTANCES} -eq 0 ]]; then
        echo "  📭 No active instances"
    else
        for instance_key in ${(k)ZBOX_MODEL_INSTANCES}; do
            local instance_data="${ZBOX_MODEL_INSTANCES[$instance_key]}"
            local pid="${instance_data%%:*}"
            local socket_path="${instance_data#*:}"
            socket_path="${socket_path%:*}"
            local created="${instance_data##*:}"
            local age=$(($(date +%s) - created))
            local last_used="${ZBOX_MODEL_LAST_USED[$instance_key]}"
            local idle=$(($(date +%s) - last_used))
            
            echo "  🤖 $instance_key"
            echo "     PID: $pid | Age: ${age}s | Idle: ${idle}s"
            echo "     Socket: ${socket_path##*/}"
        done
    fi
    echo ""
    
    # Warmup pool
    echo "🔥 Warmup Pool:"
    if [[ ${#ZBOX_MODEL_WARMUP_POOL} -eq 0 ]]; then
        echo "  🧊 No warmed models"
    else
        for model_type in ${(k)ZBOX_MODEL_WARMUP_POOL}; do
            local warmup_data="${ZBOX_MODEL_WARMUP_POOL[$model_type]}"
            local pid="${warmup_data%%:*}"
            local created="${warmup_data##*:}"
            local age=$(($(date +%s) - created))
            
            echo "  🔥 $model_type: PID $pid (age: ${age}s)"
        done
    fi
    echo ""
    
    # Resource usage
    echo "📊 Resource Usage:"
    local total_memory=0
    for instance_key in ${(k)ZBOX_MODEL_INSTANCES}; do
        local pid="${ZBOX_MODEL_INSTANCES[$instance_key]%%:*}"
        local mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo 0)
        total_memory=$((total_memory + mem_kb))
    done
    
    echo "  💾 Total Memory: $((total_memory / 1024))MB"
    echo "  🏊 Pool Size: ${#ZBOX_MODEL_INSTANCES}/$ZBOX_MODEL_POOL_SIZE"
    echo "  🔥 Warmup: ${#ZBOX_MODEL_WARMUP_POOL} models"
}

function zbox_model_pool_optimize() {
    echo "🔧 Optimizing model pool..."
    
    # Kill oldest idle instances if pool is full
    if [[ ${#ZBOX_MODEL_INSTANCES} -ge $ZBOX_MODEL_POOL_SIZE ]]; then
        echo "🏊 Pool full, killing oldest instances..."
        
        # Sort by last used time and kill oldest
        local oldest_instances=()
        for instance_key in ${(k)ZBOX_MODEL_INSTANCES}; do
            local last_used="${ZBOX_MODEL_LAST_USED[$instance_key]}"
            oldest_instances+=("$last_used:$instance_key")
        done
        
        # Sort and kill oldest
        local sorted_instances=(${(o)oldest_instances})
        local kill_count=$((${#ZBOX_MODEL_INSTANCES} - ZBOX_MODEL_POOL_SIZE + 1))
        
        for i in {1..$kill_count}; do
            local instance_to_kill="${sorted_instances[i]#*:}"
            zbox_model_kill_instant "$instance_to_kill"
        done
    fi
    
    # Ensure warmup pool is maintained
    for model_type in primary secondary code; do
        if [[ -z "${ZBOX_MODEL_WARMUP_POOL[$model_type]}" ]]; then
            zbox_model_warmup_spawn "$model_type" &
        fi
    done
    
    echo "✅ Pool optimization complete"
}

# ============================================================================
# CONTAINER INTEGRATION
# ============================================================================

function zbox_model_container_init() {
    local user="$1"
    
    echo "📦 Initializing model system for container user: $user"
    
    # Create user-specific socket directory
    local user_socket_dir="$ZBOX_MODEL_SOCKETS_DIR/$user"
    mkdir -p "$user_socket_dir"
    chmod 700 "$user_socket_dir"
    
    # User-specific model binary wrapper
    cat > "$user_socket_dir/model_wrapper.sh" << EOF
#!/bin/bash
# User-specific model wrapper for $user

export ZBOX_USER="$user"
export ZBOX_MODEL_SOCKETS_DIR="$user_socket_dir"

# Run with user isolation
exec "$ZBOX_MODEL_BINARY" \\
    --user "$user" \\
    --socket-dir "$user_socket_dir" \\
    --sandbox-mode \\
    --resource-limit-memory 2G \\
    --resource-limit-cpu 2 \\
    "\$@"
EOF
    
    chmod +x "$user_socket_dir/model_wrapper.sh"
    
    echo "✅ Container model system ready for $user"
    echo "   📁 Socket dir: $user_socket_dir"
    echo "   🔧 Wrapper: $user_socket_dir/model_wrapper.sh"
}

# ============================================================================
# ALIASES AND SHORTCUTS
# ============================================================================

alias instant_chat='zbox_chat_instant'
alias ic='zbox_chat_instant'
alias model_status='zbox_model_pool_status'
alias model_kill_all='zbox_model_kill_all'
alias model_optimize='zbox_model_pool_optimize'
alias warmup_models='zbox_warmup_pool_init'

# ============================================================================
# INITIALIZATION
# ============================================================================

function zbox_instant_system_init() {
    echo "⚡ Initializing ZBOX Instant Model System..."
    
    # Create socket directory
    mkdir -p "$ZBOX_MODEL_SOCKETS_DIR"
    chmod 755 "$ZBOX_MODEL_SOCKETS_DIR"
    
    # Initialize warmup pool if enabled
    if [[ "$ZBOX_MODEL_WARMUP_ENABLED" == "true" ]]; then
        zbox_warmup_pool_init &
    fi
    
    # Set up cleanup on exit
    trap 'zbox_model_kill_all' EXIT INT TERM
    
    echo "✅ Instant model system ready!"
    echo "   ⚡ Spawn timeout: ${ZBOX_MODEL_SPAWN_TIMEOUT}s"
    echo "   💀 Idle timeout: ${ZBOX_MODEL_IDLE_TIMEOUT}s"
    echo "   🏊 Pool size: $ZBOX_MODEL_POOL_SIZE"
    echo "   🔥 Warmup: $([[ "$ZBOX_MODEL_WARMUP_ENABLED" == "true" ]] && echo "enabled" || echo "disabled")"
}

# Auto-initialize
zbox_instant_system_init

echo "⚡ ZBOX Instant Model Spawning System Loaded!"
echo "   💬 Try: instant_chat 'your message'"
echo "   📊 Try: model_status"