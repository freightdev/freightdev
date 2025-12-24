#!/bin/zsh
# ZBOX Security & Multi-User System
# Enterprise-grade security with user isolation

# ============================================================================
# ZBOX SECURITY CORE
# ============================================================================

export ZBOX_SECURITY_ENABLED=true
export ZBOX_SECURITY_LEVEL="${ZBOX_SECURITY_LEVEL:-strict}"
export ZBOX_USER_SANDBOXES_PATH="$ZBOX_HOME/sandboxes"
export ZBOX_SECURITY_LOGS="$ZBOX_HOME/logs/security.log"
export ZBOX_AUDIT_LOGS="$ZBOX_HOME/logs/audit.log"

# User permission levels
typeset -gA ZBOX_USER_PERMISSIONS
typeset -gA ZBOX_USER_ROLES
typeset -gA ZBOX_ACTIVE_SESSIONS
typeset -gA ZBOX_API_KEYS
typeset -gA ZBOX_USER_QUOTAS
typeset -gA ZBOX_RATE_LIMITS

# Security event tracking
typeset -ga ZBOX_SECURITY_EVENTS
typeset -ga ZBOX_LOGIN_ATTEMPTS
typeset -ga ZBOX_SUSPICIOUS_ACTIVITY

# ============================================================================
# USER MANAGEMENT & ROLES
# ============================================================================

function zbox_user_create_secure() {
    local username="$1"
    local role="${2:-user}"  # admin, user, guest
    local email="$3"
    
    if [[ -z "$username" || -z "$email" ]]; then
        echo "❌ Usage: zbox_user_create_secure <username> <role> <email>"
        return 1
    fi
    
    # Validate username (alphanumeric + underscore only)
    if ! [[ "$username" =~ ^[a-zA-Z0-9_]{3,20}$ ]]; then
        echo "❌ Invalid username. Use 3-20 alphanumeric characters."
        return 1
    fi
    
    # Check if user exists
    if [[ -n "${ZBOX_USER_ROLES[$username]}" ]]; then
        echo "❌ User already exists: $username"
        return 1
    fi
    
    echo "🔐 Creating secure user: $username"
    
    # Create user sandbox
    local user_sandbox="$ZBOX_USER_SANDBOXES_PATH/$username"
    mkdir -p "$user_sandbox"/{memory,context,logs,temp,keys,models}
    
    # Set strict permissions
    chmod 700 "$user_sandbox"
    
    # Generate secure API keys
    local api_key="zbox_$(openssl rand -hex 16)"
    local master_key="zbox_master_$(openssl rand -hex 24)"
    
    # Store user data
    ZBOX_USER_ROLES[$username]="$role"
    ZBOX_API_KEYS[$username]="$api_key"
    ZBOX_USER_PERMISSIONS[$username]=$(zbox_get_role_permissions "$role")
    
    # Set quotas based on role
    case "$role" in
        "admin")
            ZBOX_USER_QUOTAS[$username]="conversations:unlimited,memory:unlimited,models:unlimited"
            ;;
        "user")
            ZBOX_USER_QUOTAS[$username]="conversations:1000,memory:500,models:5"
            ;;
        "guest")
            ZBOX_USER_QUOTAS[$username]="conversations:100,memory:50,models:1"
            ;;
    esac
    
    # Create user config file
    cat > "$user_sandbox/user_config.json" << EOF
{
    "username": "$username",
    "role": "$role",
    "email": "$email",
    "created": "$(date -Iseconds)",
    "api_key": "$api_key",
    "master_key": "$master_key",
    "sandbox_path": "$user_sandbox",
    "quotas": "$(echo ${ZBOX_USER_QUOTAS[$username]})",
    "permissions": "$(echo ${ZBOX_USER_PERMISSIONS[$username]})",
    "security_level": "$ZBOX_SECURITY_LEVEL"
}
EOF
    
    # Secure the config file
    chmod 600 "$user_sandbox/user_config.json"
    
    # Log security event
    zbox_security_log "USER_CREATED" "$username" "role:$role,email:$email"
    
    echo "✅ User created successfully!"
    echo "   👤 Username: $username"
    echo "   🎭 Role: $role"
    echo "   🔑 API Key: ${api_key:0:12}..."
    echo "   📁 Sandbox: $user_sandbox"
    
    return 0
}

function zbox_get_role_permissions() {
    local role="$1"
    
    case "$role" in
        "admin")
            echo "read,write,delete,admin,create_users,manage_system,access_all_data"
            ;;
        "user")
            echo "read,write,delete_own,create_sessions,access_own_data"
            ;;
        "guest")
            echo "read,limited_write,access_own_data"
            ;;
        *)
            echo "read"
            ;;
    esac
}

# ============================================================================
# SESSION MANAGEMENT & AUTHENTICATION
# ============================================================================

function zbox_user_login() {
    local username="$1"
    local provided_key="$2"
    local ip_address="${3:-127.0.0.1}"
    
    if [[ -z "$username" || -z "$provided_key" ]]; then
        echo "❌ Usage: zbox_user_login <username> <api_key> [ip_address]"
        return 1
    fi
    
    # Rate limiting check
    if ! zbox_rate_limit_check "$username" "login"; then
        zbox_security_log "RATE_LIMIT_EXCEEDED" "$username" "ip:$ip_address,action:login"
        echo "❌ Rate limit exceeded. Try again later."
        return 1
    fi
    
    # Validate user exists
    if [[ -z "${ZBOX_USER_ROLES[$username]}" ]]; then
        zbox_security_log "LOGIN_FAILED" "$username" "reason:user_not_found,ip:$ip_address"
        echo "❌ Invalid username or API key"
        return 1
    fi
    
    # Validate API key
    local stored_key="${ZBOX_API_KEYS[$username]}"
    if [[ "$provided_key" != "$stored_key" ]]; then
        zbox_security_log "LOGIN_FAILED" "$username" "reason:invalid_key,ip:$ip_address"
        ZBOX_LOGIN_ATTEMPTS+=("$(date -Iseconds):$username:$ip_address:FAILED")
        echo "❌ Invalid username or API key"
        return 1
    fi
    
    # Create secure session
    local session_id="session_$(date +%s)_$(openssl rand -hex 8)"
    local session_token="tok_$(openssl rand -hex 16)"
    local expires=$(($(date +%s) + 86400))  # 24 hours
    
    # Store active session
    ZBOX_ACTIVE_SESSIONS[$session_id]="user:$username,token:$session_token,ip:$ip_address,expires:$expires,created:$(date +%s)"
    
    # Set environment for user
    export ZBOX_CURRENT_USER="$username"
    export ZBOX_SESSION_ID="$session_id"
    export ZBOX_SESSION_TOKEN="$session_token"
    export ZBOX_USER_ROLE="${ZBOX_USER_ROLES[$username]}"
    export ZBOX_USER_SANDBOX="$ZBOX_USER_SANDBOXES_PATH/$username"
    
    # Update user's last login
    touch "$ZBOX_USER_SANDBOX/.last_login"
    
    # Log successful login
    zbox_security_log "LOGIN_SUCCESS" "$username" "session:$session_id,ip:$ip_address"
    ZBOX_LOGIN_ATTEMPTS+=("$(date -Iseconds):$username:$ip_address:SUCCESS")
    
    echo "✅ Login successful!"
    echo "   👤 User: $username"
    echo "   🎭 Role: ${ZBOX_USER_ROLES[$username]}"
    echo "   🔐 Session: ${session_id:0:16}..."
    echo "   ⏰ Expires: $(date -d @$expires)"
    
    # Load user's personalized environment
    zbox_load_user_environment "$username"
    
    return 0
}

function zbox_user_logout() {
    local session_id="${1:-$ZBOX_SESSION_ID}"
    
    if [[ -z "$session_id" ]]; then
        echo "❌ No active session to logout"
        return 1
    fi
    
    local session_data="${ZBOX_ACTIVE_SESSIONS[$session_id]}"
    if [[ -n "$session_data" ]]; then
        local username=$(echo "$session_data" | grep -o 'user:[^,]*' | cut -d':' -f2)
        
        # Log logout
        zbox_security_log "LOGOUT" "$username" "session:$session_id"
        
        # Remove session
        unset "ZBOX_ACTIVE_SESSIONS[$session_id]"
        
        # Clear environment
        unset ZBOX_CURRENT_USER ZBOX_SESSION_ID ZBOX_SESSION_TOKEN ZBOX_USER_ROLE ZBOX_USER_SANDBOX
        
        echo "👋 Logged out successfully"
    else
        echo "❌ Invalid session"
        return 1
    fi
}

# ============================================================================
# USER SANDBOX & ISOLATION
# ============================================================================

function zbox_user_sandbox_init() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        username="$ZBOX_CURRENT_USER"
    fi
    
    if [[ -z "$username" ]]; then
        echo "❌ No user specified and no active session"
        return 1
    fi
    
    local sandbox_path="$ZBOX_USER_SANDBOXES_PATH/$username"
    
    if [[ ! -d "$sandbox_path" ]]; then
        echo "❌ User sandbox not found: $sandbox_path"
        return 1
    fi
    
    echo "🏗️ Initializing sandbox for $username..."
    
    # Create sandbox directory structure
    mkdir -p "$sandbox_path"/{memory,context,logs,temp,keys,models,scripts,data}
    
    # Set up sandbox-specific memory paths
    export ZBOX_USER_MEMORY_PATH="$sandbox_path/memory"
    export ZBOX_USER_CONTEXT_PATH="$sandbox_path/context"  
    export ZBOX_USER_LOGS_PATH="$sandbox_path/logs"
    export ZBOX_USER_TEMP_PATH="$sandbox_path/temp"
    
    # Initialize user-specific memory files
    local user_memory_db="$ZBOX_USER_MEMORY_PATH/user_memory.json"
    local user_context_db="$ZBOX_USER_CONTEXT_PATH/context.json"
    local user_prefs_db="$ZBOX_USER_MEMORY_PATH/preferences.json"
    
    [[ ! -f "$user_memory_db" ]] && echo '{"user":"'$username'","created":"'$(date -Iseconds)'","memories":[]}' > "$user_memory_db"
    [[ ! -f "$user_context_db" ]] && echo '{"active_context":[],"context_window":4096,"max_context":8192}' > "$user_context_db"  
    [[ ! -f "$user_prefs_db" ]] && echo '{"model":"primary","temperature":0.7,"max_tokens":512,"memory_enabled":true}' > "$user_prefs_db"
    
    # Set proper permissions
    chmod -R 700 "$sandbox_path"
    chmod 600 "$user_memory_db" "$user_context_db" "$user_prefs_db"
    
    # Load user environment variables
    export ZBOX_MEMORY_DB="$user_memory_db"
    export ZBOX_CONTEXT_DB="$user_context_db"  
    export ZBOX_PREFERENCES_DB="$user_prefs_db"
    
    echo "✅ Sandbox initialized for $username"
    echo "   📁 Path: $sandbox_path"
    echo "   🧠 Memory: $user_memory_db"
    echo "   💭 Context: $user_context_db"
    
    return 0
}

function zbox_sandbox_isolation_check() {
    local username="$1"
    local requested_path="$2"
    
    local user_sandbox="$ZBOX_USER_SANDBOXES_PATH/$username"
    
    # Ensure path is within user's sandbox
    local resolved_path=$(realpath "$requested_path" 2>/dev/null)
    local sandbox_real=$(realpath "$user_sandbox")
    
    if [[ "$resolved_path" != "$sandbox_real"* ]]; then
        zbox_security_log "SANDBOX_VIOLATION" "$username" "requested_path:$requested_path,resolved:$resolved_path"
        return 1
    fi
    
    return 0
}

# ============================================================================
# PERMISSION SYSTEM
# ============================================================================

function zbox_permission_check() {
    local username="$1"
    local required_permission="$2"
    local resource="${3:-general}"
    
    if [[ -z "$username" || -z "$required_permission" ]]; then
        echo "❌ Usage: zbox_permission_check <username> <permission> [resource]"
        return 1
    fi
    
    # Get user permissions
    local user_permissions="${ZBOX_USER_PERMISSIONS[$username]}"
    local user_role="${ZBOX_USER_ROLES[$username]}"
    
    if [[ -z "$user_permissions" ]]; then
        zbox_security_log "PERMISSION_DENIED" "$username" "reason:no_permissions,permission:$required_permission,resource:$resource"
        return 1
    fi
    
    # Check if user has required permission
    if [[ "$user_permissions" == *"$required_permission"* ]] || [[ "$user_permissions" == *"admin"* ]]; then
        # Additional checks for sensitive operations
        case "$required_permission" in
            "admin"|"manage_system"|"create_users")
                if [[ "$user_role" != "admin" ]]; then
                    zbox_security_log "PRIVILEGE_ESCALATION_ATTEMPT" "$username" "permission:$required_permission,role:$user_role"
                    return 1
                fi
                ;;
        esac
        
        return 0
    else
        zbox_security_log "PERMISSION_DENIED" "$username" "permission:$required_permission,resource:$resource,role:$user_role"
        return 1
    fi
}

function zbox_secure_command() {
    local required_permission="$1"
    local resource="$2"
    shift 2
    local command="$*"
    
    local username="${ZBOX_CURRENT_USER:-guest}"
    
    if ! zbox_permission_check "$username" "$required_permission" "$resource"; then
        echo "❌ Permission denied: $required_permission required for $resource"
        return 1
    fi
    
    # Log command execution
    zbox_audit_log "COMMAND_EXECUTED" "$username" "permission:$required_permission,resource:$resource,command:${command:0:100}"
    
    # Execute command in secure context
    eval "$command"
    local exit_code=$?
    
    # Log result
    zbox_audit_log "COMMAND_COMPLETED" "$username" "exit_code:$exit_code,command:${command:0:100}"
    
    return $exit_code
}

# ============================================================================
# RATE LIMITING & QUOTA MANAGEMENT
# ============================================================================

function zbox_rate_limit_check() {
    local username="$1"
    local action="${2:-general}"
    local current_time=$(date +%s)
    local window=60  # 1 minute window
    
    # Rate limits per action type
    local max_requests
    case "$action" in
        "login") max_requests=5 ;;
        "chat") max_requests=60 ;;
        "memory_store") max_requests=100 ;;
        "api_call") max_requests=1000 ;;
        *) max_requests=30 ;;
    esac
    
    # Get current rate limit data
    local rate_key="${username}_${action}"
    local rate_data="${ZBOX_RATE_LIMITS[$rate_key]}"
    
    if [[ -z "$rate_data" ]]; then
        # First request in window
        ZBOX_RATE_LIMITS[$rate_key]="count:1,window_start:$current_time"
        return 0
    fi
    
    # Parse existing data
    local count=$(echo "$rate_data" | grep -o 'count:[0-9]*' | cut -d':' -f2)
    local window_start=$(echo "$rate_data" | grep -o 'window_start:[0-9]*' | cut -d':' -f2)
    
    # Check if we're in a new window
    if [[ $((current_time - window_start)) -gt $window ]]; then
        # New window, reset counter
        ZBOX_RATE_LIMITS[$rate_key]="count:1,window_start:$current_time"
        return 0
    fi
    
    # Check if limit exceeded
    if [[ $count -ge $max_requests ]]; then
        zbox_security_log "RATE_LIMIT_EXCEEDED" "$username" "action:$action,count:$count,limit:$max_requests"
        return 1
    fi
    
    # Increment counter
    ZBOX_RATE_LIMITS[$rate_key]="count:$((count + 1)),window_start:$window_start"
    return 0
}

function zbox_quota_check() {
    local username="$1"
    local quota_type="$2"  # conversations, memory, models
    
    local user_quotas="${ZBOX_USER_QUOTAS[$username]}"
    if [[ -z "$user_quotas" ]]; then
        return 0  # No quotas set
    fi
    
    # Parse quota for specific type
    local quota_value=$(echo "$user_quotas" | grep -o "${quota_type}:[^,]*" | cut -d':' -f2)
    
    if [[ "$quota_value" == "unlimited" ]]; then
        return 0
    fi
    
    # Check current usage (simplified - would need actual counting)
    local current_usage=0
    case "$quota_type" in
        "conversations")
            current_usage=$(find "$ZBOX_USER_SANDBOXES_PATH/$username/logs" -name "*.log" -type f | wc -l 2>/dev/null || echo 0)
            ;;
        "memory")
            current_usage=$(wc -l < "$ZBOX_USER_SANDBOXES_PATH/$username/memory/user_memory.json" 2>/dev/null || echo 0)
            ;;
    esac
    
    if [[ $current_usage -ge $quota_value ]]; then
        zbox_security_log "QUOTA_EXCEEDED" "$username" "type:$quota_type,current:$current_usage,limit:$quota_value"
        return 1
    fi
    
    return 0
}

# ============================================================================
# SECURITY LOGGING & MONITORING
# ============================================================================

function zbox_security_log() {
    local event_type="$1"
    local username="$2" 
    local details="$3"
    local timestamp=$(date -Iseconds)
    local log_entry="[$timestamp] $event_type | User: $username | $details"
    
    echo "$log_entry" >> "$ZBOX_SECURITY_LOGS"
    ZBOX_SECURITY_EVENTS+=("$log_entry")
    
    # Alert on critical events
    case "$event_type" in
        "LOGIN_FAILED"|"PERMISSION_DENIED"|"SANDBOX_VIOLATION"|"PRIVILEGE_ESCALATION_ATTEMPT")
            echo "🚨 SECURITY ALERT: $event_type for $username" >&2
            ;;
    esac
}

function zbox_audit_log() {
    local action="$1"
    local username="$2"
    local details="$3"
    local timestamp=$(date -Iseconds)
    local session_id="${ZBOX_SESSION_ID:-none}"
    
    local audit_entry="[$timestamp] $action | User: $username | Session: $session_id | $details"
    echo "$audit_entry" >> "$ZBOX_AUDIT_LOGS"
}

function zbox_security_dashboard() {
    echo "🛡️ ZBOX Security Dashboard"
    echo ""
    
    # Active sessions
    echo "🔐 Active Sessions:"
    local active_count=0
    for session_id in ${(k)ZBOX_ACTIVE_SESSIONS}; do
        local session_data="${ZBOX_ACTIVE_SESSIONS[$session_id]}"
        local username=$(echo "$session_data" | grep -o 'user:[^,]*' | cut -d':' -f2)
        local ip=$(echo "$session_data" | grep -o 'ip:[^,]*' | cut -d':' -f2)
        local created=$(echo "$session_data" | grep -o 'created:[0-9]*' | cut -d':' -f2)
        local created_time=$(date -d @$created "+%H:%M:%S")
        
        echo "  👤 $username @ $ip (${session_id:0:12}...) - since $created_time"
        ((active_count++))
    done
    echo "  📊 Total: $active_count active sessions"
    echo ""
    
    # Recent security events
    echo "🚨 Recent Security Events:"
    echo "${ZBOX_SECURITY_EVENTS[-5,-1]}" | while read event; do
        echo "  $event"
    done
    echo ""
    
    # User statistics
    echo "👥 User Statistics:"
    local total_users=${#ZBOX_USER_ROLES}
    local admin_count=0
    local user_count=0  
    local guest_count=0
    
    for username in ${(k)ZBOX_USER_ROLES}; do
        case "${ZBOX_USER_ROLES[$username]}" in
            "admin") ((admin_count++)) ;;
            "user") ((user_count++)) ;;
            "guest") ((guest_count++)) ;;
        esac
    done
    
    echo "  📈 Total users: $total_users"
    echo "  👑 Admins: $admin_count"
    echo "  👤 Users: $user_count"
    echo "  👻 Guests: $guest_count"
    echo ""
    
    # Rate limiting status
    echo "⏱️ Rate Limiting Status:"
    local blocked_users=0
    for rate_key in ${(k)ZBOX_RATE_LIMITS}; do
        local username="${rate_key%_*}"
        local action="${rate_key#*_}"
        local rate_data="${ZBOX_RATE_LIMITS[$rate_key]}"
        local count=$(echo "$rate_data" | grep -o 'count:[0-9]*' | cut -d':' -f2)
        
        if [[ $count -ge 50 ]]; then  # High activity threshold
            echo "  ⚠️  $username: $count requests for $action"
            ((blocked_users++))
        fi
    done
    
    [[ $blocked_users -eq 0 ]] && echo "  ✅ All users within normal limits"
}

# ============================================================================
# API KEY MANAGEMENT
# ============================================================================

function zbox_api_key_rotate() {
    local username="$1"
    local force="${2:-false}"
    
    if ! zbox_permission_check "$username" "admin" "api_keys" && [[ "$username" != "$ZBOX_CURRENT_USER" ]]; then
        echo "❌ Permission denied: Can only rotate own keys or admin required"
        return 1
    fi
    
    local old_key="${ZBOX_API_KEYS[$username]}"
    local new_key="zbox_$(openssl rand -hex 16)"
    
    # Update API key
    ZBOX_API_KEYS[$username]="$new_key"
    
    # Update user config file
    local sandbox_path="$ZBOX_USER_SANDBOXES_PATH/$username"
    if [[ -f "$sandbox_path/user_config.json" ]]; then
        # Update JSON file (simple sed replacement)
        sed -i "s/\"api_key\": \"$old_key\"/\"api_key\": \"$new_key\"/" "$sandbox_path/user_config.json"
    fi
    
    # Log key rotation
    zbox_security_log "API_KEY_ROTATED" "$username" "old_key:${old_key:0:8}...,new_key:${new_key:0:8}..."
    
    echo "🔄 API key rotated for $username"
    echo "   🔑 New key: ${new_key:0:12}..."
    echo "   ⚠️  Update your applications with the new key"
    
    return 0
}

function zbox_api_key_validate() {
    local provided_key="$1"
    local username="$2"
    
    local stored_key="${ZBOX_API_KEYS[$username]}"
    
    if [[ "$provided_key" == "$stored_key" ]]; then
        return 0
    else
        zbox_security_log "API_KEY_VALIDATION_FAILED" "$username" "provided:${provided_key:0:8}..."
        return 1
    fi
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

function zbox_session_cleanup() {
    local current_time=$(date +%s)
    local cleaned_count=0
    
    echo "🧹 Cleaning up expired sessions..."
    
    for session_id in ${(k)ZBOX_ACTIVE_SESSIONS}; do
        local session_data="${ZBOX_ACTIVE_SESSIONS[$session_id]}"
        local expires=$(echo "$session_data" | grep -o 'expires:[0-9]*' | cut -d':' -f2)
        
        if [[ $current_time -gt $expires ]]; then
            local username=$(echo "$session_data" | grep -o 'user:[^,]*' | cut -d':' -f2)
            
            zbox_security_log "SESSION_EXPIRED" "$username" "session:$session_id"
            unset "ZBOX_ACTIVE_SESSIONS[$session_id]"
            ((cleaned_count++))
        fi
    done
    
    echo "✅ Cleaned up $cleaned_count expired sessions"
    return $cleaned_count
}

function zbox_session_hijack_protect() {
    local session_id="${1:-$ZBOX_SESSION_ID}"
    local current_ip="${2:-127.0.0.1}"
    
    if [[ -z "$session_id" ]]; then
        return 1
    fi
    
    local session_data="${ZBOX_ACTIVE_SESSIONS[$session_id]}"
    if [[ -z "$session_data" ]]; then
        return 1
    fi
    
    # Check if IP matches session IP
    local session_ip=$(echo "$session_data" | grep -o 'ip:[^,]*' | cut -d':' -f2)
    local username=$(echo "$session_data" | grep -o 'user:[^,]*' | cut -d':' -f2)
    
    if [[ "$current_ip" != "$session_ip" ]]; then
        zbox_security_log "SESSION_HIJACK_ATTEMPT" "$username" "session:$session_id,original_ip:$session_ip,current_ip:$current_ip"
        
        # Invalidate session
        unset "ZBOX_ACTIVE_SESSIONS[$session_id]"
        unset ZBOX_CURRENT_USER ZBOX_SESSION_ID ZBOX_SESSION_TOKEN
        
        echo "🚨 Security alert: Session invalidated due to IP mismatch"
        return 1
    fi
    
    return 0
}

# ============================================================================
# SECURE ALIASES & COMMANDS
# ============================================================================

# Secure command wrappers
alias secure_chat='zbox_secure_command "write" "chat" zbox_chat_with_smart_memory'
alias secure_memory_store='zbox_secure_command "write" "memory" zbox_memory_store_fast'
alias secure_user_create='zbox_secure_command "admin" "users" zbox_user_create_secure'
alias secure_system_admin='zbox_secure_command "admin" "system"'

# User management aliases
alias login='zbox_user_login'
alias logout='zbox_user_logout'
alias whoami='echo "👤 User: $ZBOX_CURRENT_USER | Role: $ZBOX_USER_ROLE | Session: ${ZBOX_SESSION_ID:0:12}..."'
alias security_dashboard='zbox_security_dashboard'
alias rotate_key='zbox_api_key_rotate'

# Auto session cleanup (run every 30 minutes)
function zbox_security_auto_tasks() {
    while true; do
        sleep 1800  # 30 minutes
        zbox_session_cleanup > /dev/null 2>&1 &
    done
}

# Initialize security system
function zbox_security_init() {
    echo "🛡️ Initializing ZBOX Security System..."
    
    # Create directories
    mkdir -p "$ZBOX_USER_SANDBOXES_PATH"
    mkdir -p "$(dirname "$ZBOX_SECURITY_LOGS")"
    
    # Set up log files
    touch "$ZBOX_SECURITY_LOGS" "$ZBOX_AUDIT_LOGS"
    chmod 640 "$ZBOX_SECURITY_LOGS" "$ZBOX_AUDIT_LOGS"
    
    # Start background security tasks
    zbox_security_auto_tasks &
    local bg_pid=$!
    echo $bg_pid > "$ZBOX_HOME/.security_daemon.pid"
    
    # Log initialization
    zbox_security_log "SYSTEM_INITIALIZED" "system" "security_level:$ZBOX_SECURITY_LEVEL"
    
    echo "✅ Security system initialized"
    echo "   🔒 Security level: $ZBOX_SECURITY_LEVEL"
    echo "   📁 Sandboxes: $ZBOX_USER_SANDBOXES_PATH"
    echo "   📝 Logs: $ZBOX_SECURITY_LOGS"
}

# Initialize security on load
if [[ "$ZBOX_SECURITY_ENABLED" == "true" ]]; then
    zbox_security_init
fi