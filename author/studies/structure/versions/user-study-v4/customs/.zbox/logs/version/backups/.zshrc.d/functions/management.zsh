# ========================================
# Management Functions (Zsh)
# ========================================

#! --- Set Paths --- !#
ENV_LOGS=$ENV_DIR/logs            #? <== environment logs path

#! --- Track Paths --- !#
ENV_LAST=$ENV_LOGS/.env_choice    #? <== track selected environment choices
ENV_STATE=$ENV_LOGS/.env_state    #? <== track loaded environment state
ENV_VARS=$ENV_LOGS/.env_vars      #? <== track exported environment variables

save_env_state() {
    local env_key_files=("$@")
    local state_info=""
    for file in "${env_key_files[@]}"; do
        if [[ -f "$file" ]]; then
            local mtime=$(date -r "$file" "+%s" 2>/dev/null || echo "0")
            state_info+="$(basename "$file"):$mtime "
        fi
    done
    echo "$state_info" > "$ENV_STATE"
}

check_env_changes() {
    [[ ! -f "$ENV_STATE" ]] && return 0
    
    local current_state=""
    local env_key_files=("$@")
    for file in "${env_key_files[@]}"; do
        if [[ -f "$file" ]]; then
            local mtime=$(date -r "$file" "+%s" 2>/dev/null || echo "0")
            current_state+="$(basename "$file"):$mtime "
        fi
    done
    
    local saved_state=$(cat "$ENV_STATE" 2>/dev/null)
    [[ "$current_state" != "$saved_state" ]]
}

save_env_vars() {
    # Save current environment variables with timestamps
    env | while IFS= read -r line; do
        echo "$(date +%s):$line"
    done >> "$ENV_VARS"
}

envclean() {
    if [[ ! -f "$ENV_VARS" ]]; then
        log_warn "No environment variable history found"
        return 1
    fi
    
    log_info "Recent environment variables (newest first):"
    local vars=($(tac "$ENV_VARS" | head -20 | cut -d: -f2- | cut -d= -f1))
    local count=1
    
    for var in "${vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then  # Check if variable is set
            log_info "$count: $var=${(P)var}"
            ((count++))
        fi
    done
    
    prompt "Select variables to unset (comma-separated numbers, or 'all')" selection
    
    if [[ "$selection" == "all" ]]; then
        for var in "${vars[@]}"; do
            unset "$var" 2>/dev/null
            log_ok "Unset: $var"
        done
    else
        local nums=(${(s:,:)selection})
        for num in "${nums[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num < count )); then
                local var_to_unset="${vars[num]}"
                unset "$var_to_unset" 2>/dev/null
                log_ok "Unset: $var_to_unset"
            fi
        done
    fi
}