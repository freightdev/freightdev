#!/usr/bin/env zsh
#!  List & Loading Evironment Paths (Zsh)
# ========================================
env_keys=()

#* Locate all environment (including .*.* patterns) *#
log_scan "Searching for environments in: $(dirname "$ENV_DIR/envs")"
if [[ -d "$ENV_DIR/envs" ]] && command -v find >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
        [[ -f "$file" && -r "$file" ]] && env_keys+=("$file")
        log_info "Found file: $file"
    done < <(find "$ENV_DIR/envs" -maxdepth 2 -type f -print0 2>/dev/null)
fi
log_set "Total environments added to array: ${#env_keys[@]}"

if (( ${#env_keys[@]} == 0 )); then
    log_warn "No environments found in $(dirname "$ENV_DIR/envs")"
else 
    if (( ${#env_keys[@]} == 1 )); then
        selected="${env_keys[1]}"
        log_info "Only one environment found: $(basename "$selected")"
        log_loading "$(basename "$selected") automatically being loaded..."
    else
        log_info "Found ${#env_keys[@]} environments:"
        for (( idx=1; idx<=${#env_keys[@]}; idx++ )); do
            file="${env_keys[idx]}"
            basefile=$(basename "$file")
            log_set "$idx: $basefile"
        done

        prompt "Which environment would you like to load? (number)" choice
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#env_keys[@]} )); then
            log_error "Invalid choice."
            exit 1
        fi
        
        selected="${env_keys[choice]}"

    fi
    
    #* Load with timing *#
    env_start=$SECONDS
    log_loading "Loading $(basename "$selected")..."
    
    set -a      #? <== automatically export all variables
    set +a      #? <== turn off auto-export
    source "$selected"
    
    env_time=$((env_end - env_start))
    log_ok "Loaded $(basename "$selected") successfully in ${env_time}s!"
fi