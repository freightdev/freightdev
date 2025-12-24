#!  ╔══════════════════════════════════════════╗
#?    Route Helpers - Environment Source (Zsh)  
#!  ╚══════════════════════════════════════════╝

#!         Continue Helper (zsh)
# ========================================
continue() {
    local next="$1"

    if [[ -z "$next" ]]; then
        "[ERROR] No path provided to continue"
        return 1
    fi

    if [[ -f "$next" ]]; then
        echo "[CONTINUE] Running: $next"
        "$next"
        return $?
    else
        echo "[ERROR] Path does not exist: $next"
        return 1
    fi
}
