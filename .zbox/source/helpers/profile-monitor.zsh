#!/bin/zsh
#############################
# ZBOX Profile Monitor
# Track and manage running profile sessions
#############################

# Profile session tracking
export ZBOX_PROFILE_SESSIONS="${ZBOX_AI}/logs/sessions"
export ZBOX_PROFILE_PIDS="${ZBOX_AI}/logs/sessions"

# Initialize profile monitoring
zbox_init_profile_monitor() {
    mkdir -p "$ZBOX_PROFILE_SESSIONS" "$ZBOX_PROFILE_PIDS"

    # Register current profile session
    if [[ -n "$ZBOX_CURRENT_PROFILE" ]]; then
        local session_id="$(date +%s)_$$"
        local session_file="$ZBOX_PROFILE_SESSIONS/${ZBOX_CURRENT_PROFILE}_${session_id}.session"

        cat > "$session_file" <<EOF
profile: $ZBOX_CURRENT_PROFILE
pid: $$
ppid: $PPID
started: $(date '+%Y-%m-%d %H:%M:%S')
user: $USER
tty: $(tty 2>/dev/null || echo "no-tty")
manifest: $ZBOX_CURRENT_MANIFEST
session_id: $session_id
EOF

        # Track PID
        echo "$$" > "$ZBOX_PROFILE_PIDS/${ZBOX_CURRENT_PROFILE}.pid"

        export ZBOX_SESSION_ID="$session_id"
        export ZBOX_SESSION_FILE="$session_file"

        [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Profile session registered: $session_id"
    fi
}

# List all active profile sessions
zbox_monitor_profiles() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Active zBox Profile Sessions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local active_count=0

    for session_file in "$ZBOX_PROFILE_SESSIONS"/*.session(N); do
        if [[ -f "$session_file" ]]; then
            local profile=$(grep '^profile:' "$session_file" | cut -d' ' -f2)
            local pid=$(grep '^pid:' "$session_file" | cut -d' ' -f2)
            local started=$(grep '^started:' "$session_file" | cut -d' ' -f2-)
            local tty=$(grep '^tty:' "$session_file" | cut -d' ' -f2)

            # Check if PID still exists
            if kill -0 "$pid" 2>/dev/null; then
                echo "📦 Profile: $profile"
                echo "   PID:     $pid"
                echo "   Started: $started"
                echo "   TTY:     $tty"
                echo "   Status:  ✅ Running"
                echo ""
                ((active_count++))
            else
                # Cleanup dead session
                rm -f "$session_file"
                echo "📦 Profile: $profile (cleaned up dead session)"
                echo ""
            fi
        fi
    done

    if [[ $active_count -eq 0 ]]; then
        echo "No active profile sessions"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total active sessions: $active_count"
    fi
}

# Kill a specific profile session
zbox_kill_profile() {
    local profile_name="$1"
    local force="${2:-false}"

    if [[ -z "$profile_name" ]]; then
        echo "Usage: zbox_kill_profile <profile_name> [force]"
        return 1
    fi

    echo "Searching for profile sessions: $profile_name"

    local killed_count=0

    for session_file in "$ZBOX_PROFILE_SESSIONS/${profile_name}_"*.session; do
        if [[ -f "$session_file" ]]; then
            local pid=$(grep '^pid:' "$session_file" | cut -d' ' -f2)

            if kill -0 "$pid" 2>/dev/null; then
                echo "Found session PID: $pid"

                if [[ "$force" == "true" ]] || [[ "$force" == "1" ]]; then
                    echo "Force killing PID $pid..."
                    kill -9 "$pid" 2>/dev/null
                else
                    echo "Terminating PID $pid gracefully..."
                    kill -TERM "$pid" 2>/dev/null
                fi

                # Cleanup session file
                rm -f "$session_file"
                ((killed_count++))
            else
                # Already dead, just cleanup
                rm -f "$session_file"
            fi
        fi
    done

    # Cleanup PID file
    rm -f "$ZBOX_PROFILE_PIDS/${profile_name}.pid"

    if [[ $killed_count -gt 0 ]]; then
        echo "✓ Killed $killed_count session(s) for profile: $profile_name"
    else
        echo "No active sessions found for profile: $profile_name"
    fi
}

# Kill all profile sessions
zbox_kill_all_profiles() {
    echo "⚠️  WARNING: This will kill ALL profile sessions!"
    echo "Continue? (yes/no)"
    read -r response

    if [[ "$response" == "yes" ]]; then
        for session_file in "$ZBOX_PROFILE_SESSIONS"/*.session(N); do
            if [[ -f "$session_file" ]]; then
                local pid=$(grep '^pid:' "$session_file" | cut -d' ' -f2)
                local profile=$(grep '^profile:' "$session_file" | cut -d' ' -f2)

                if kill -0 "$pid" 2>/dev/null; then
                    echo "Killing profile: $profile (PID: $pid)"
                    kill -TERM "$pid" 2>/dev/null
                fi

                rm -f "$session_file"
            fi
        done

        rm -f "$ZBOX_PROFILE_PIDS"/*.pid
        echo "✓ All profile sessions terminated"
    else
        echo "Cancelled"
    fi
}

# Get PID of a specific profile
zbox_profile_pid() {
    local profile_name="$1"

    if [[ -z "$profile_name" ]]; then
        echo "Usage: zbox_profile_pid <profile_name>"
        return 1
    fi

    if [[ -f "$ZBOX_PROFILE_PIDS/${profile_name}.pid" ]]; then
        cat "$ZBOX_PROFILE_PIDS/${profile_name}.pid"
    else
        echo "No PID found for profile: $profile_name" >&2
        return 1
    fi
}

# Send signal to profile
zbox_profile_signal() {
    local profile_name="$1"
    local signal="${2:-TERM}"

    if [[ -z "$profile_name" ]]; then
        echo "Usage: zbox_profile_signal <profile_name> [signal]"
        return 1
    fi

    local pid=$(zbox_profile_pid "$profile_name")

    if [[ -n "$pid" ]]; then
        if kill -0 "$pid" 2>/dev/null; then
            echo "Sending $signal to profile: $profile_name (PID: $pid)"
            kill -$signal "$pid"
        else
            echo "Profile PID $pid is not running"
            rm -f "$ZBOX_PROFILE_PIDS/${profile_name}.pid"
            return 1
        fi
    fi
}

# Cleanup dead sessions
zbox_cleanup_profile_monitor() {
    for session_file in "$ZBOX_PROFILE_SESSIONS"/*.session(N); do
        if [[ -f "$session_file" ]]; then
            local pid=$(grep '^pid:' "$session_file" | cut -d' ' -f2)

            if ! kill -0 "$pid" 2>/dev/null; then
                rm -f "$session_file"
            fi
        fi
    done

    [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Profile monitor cleanup complete"
}

# Watch profiles in real-time
zbox_watch_profiles() {
    while true; do
        clear
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "zBox Profile Monitor - Live View"
        echo "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        zbox_monitor_profiles
        echo ""
        echo "Press Ctrl+C to exit"
        sleep 2
    done
}

# Aliases
alias pmon='zbox_monitor_profiles'
alias pkill='zbox_kill_profile'
alias pwatch='zbox_watch_profiles'
alias ppid='zbox_profile_pid'
