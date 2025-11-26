#!/usr/bin/env zsh
# =======================
# Environment Setup (zsh)
# =======================
set -euo pipefail

#! --- Helpers --- !#
prompt() {
    local msg="$1" var_name="$2"
    print -nP "%F{cyan}[PROMPT]%f $msg "
    read -r "$var_name"
}
log_info() { print -P "%F{blue}[INFO]%f $*"; }
log_warn() { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok() { print -P "%F{green}[OK]%f $*"; }

#! --- Default Paths --- !#
ENV_SET=$HOME/.zshenv

#! --- Validate directories w/ backup prompt--- !#
if [[ -f "$ENV_SET" ]]; then
    log_warn "Previous ${ENV_SET##*/} detected!"
    prompt "Would you like to backup your previous ${ENV_SET##*/}? (y/N) " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        log_warn "Aborting..."
        exit 1
    fi
    TS="$(date +%Y%m%d_%H%M%S)"
    log_info "Creating timestamped backup for current ${ENV_SET##*/}!"
    cp "$ENV_SET" "$ENV_SET-$TS"
fi

log_info "Generating you a new ${ENV_SET##*/} from scratch!"

#! --- Create environment loader --- !#
cat > "$ENV_SET" <<'EOF'
# ========================================
# Environment Source Loader (zsh)
# ========================================

#! --- Default Paths --- !#
: "${ENV_DIR:=$HOME/.zshenv.d}"         #? <== environment directory path

#! --- Set Paths --- !#
ENV_DIR=$HOME/$ENV_DIR        #? <== environment directory path
ENV_SRC=$HOME/$ENV_DIR/src     #? <== environment source path
ENV_KEYS=$HOME/$ENV_DIR/keys   #? <== environment keys path

#! --- Pretty Helpers --- !#
SECONDS=0
LOADED_COUNT=0
ENV_VARS_BEFORE=$(env | wc -l)
prompt() {
    local msg="$1" var_name="$2"
    print -nP "%F{cyan}[PROMPT]%f $msg "
    read -r "$var_name"
}
log_info() { print -P "%F{blue}[INFO]%f $*"; }
log_warn() { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok() { print -P "%F{green}[OK]%f $*"; }
log_progress() { print -P "%F{magenta}[LOADING]%f $*"; }
log_timing() { print -P "%F{cyan}[TIMING]%f $*"; }
show_summary() {
    local duration=$1 files_loaded=$2 env_vars_added=$3
    print -P "%F{green}╭─ SESSION SUMMARY ─╮%f"
    print -P "%F{green}│%f Duration: ${duration}s"
    print -P "%F{green}│%f Files loaded: $files_loaded"  
    print -P "%F{green}│%f Env vars added: $env_vars_added"
    print -P "%F{green}╰──────────────────╯%f"
}

#! --- Validate directories w/ backup prompt --- !#
if [[ -d "$ENV_DIR" ]]; then
    prompt "${ENV_DIR##*/} detected!
Would you like to backup $ENV_DIR? (y/N) " CONFIRM
    if [[ "$CONFIRM" == [yY] ]]; then
        TS="$(date +%Y%m%d_%H%M%S)"
        log_info "Creating timestamped backup for current $${ENV_DIR##*/}!"
        cp -r "$ENV_DIR" "$ENV_DIR-$TS"
    else
        log_warn "Skipped backup generator..."
    fi
fi

#! --- List all environment key files --- !#
env_key_files=()

#* Locate all environment keys (including .env.* pattern) *#
if command -v find >/dev/null 2>&1; then
    log_info "Searching for .env files in: ${ENV_KEYS##*/}"
    while IFS= read -r file; do
        log_info "Found file: $file"
        [[ -f "$file" && -r "$file" ]] && env_key_files+=("$file")
    done < <(find "$ENV_KEYS" -maxdepth 1 \( -name "*.env" -o -name ".env*" \) -type f 2>/dev/null)
    log_info "Total files added to array: ${#env_key_files[@]}"
fi

if (( ${#env_key_files[@]} == 0 )); then
    log_warn "No .env files found in ${ENV_KEYS##*/}"
else
    if (( ${#env_key_files[@]} == 1 )); then
        selected="${env_key_files[1]}"
        log_info "Only one .env file found: $(basename "$selected")"
        log_warn "Loading $(basename "$selected") automatically..."
    else
        #* Check for last choice *#
        last_choice=""
        if [[ -f "$ENV_LAST" ]]; then
            last_choice=$(cat "$ENV_LAST" 2>/dev/null)
        fi
        
        log_info "Found ${#env_key_files[@]} .env file(s):"
        for (( idx=1; idx<=${#env_key_files[@]}; idx++ )); do
            file="${env_key_files[idx]}"
            basefile=$(basename "$file")

            #* Show file size and modification time *#
            if [[ -f "$file" ]]; then
                size=$(du -h "$file" 2>/dev/null | cut -f1)
                mtime=$(date -r "$file" "+%m/%d %H:%M" 2>/dev/null)
                # Mark the last choice with an arrow
                if [[ "$basefile" == "$last_choice" ]]; then
                    log_info "$idx: $basefile (${size:-?}, modified: ${mtime:-unknown}) ← last used"
                else
                    log_info "$idx: $basefile (${size:-?}, modified: ${mtime:-unknown})"
                fi
            else
                log_info "$idx: $basefile"
            fi
        done
        
        if [[ -n "$last_choice" ]]; then
            prompt "Which .env file would you like to load? (number or ENTER for '$last_choice')" choice

            #* Pressing enter, finds the index of the last choice *#
            if [[ -z "$choice" ]]; then
                for (( idx=1; idx<=${#env_key_files[@]}; idx++ )); do
                    if [[ "$(basename "${env_key_files[idx]}")" == "$last_choice" ]]; then
                        choice=$idx
                        break
                    fi
                done
                if [[ -z "$choice" ]]; then
                    log_warn "Last choice '$last_choice' not found, please select manually"
                    prompt "Which .env file would you like to load? (number)" choice
                fi
            fi
        else
            prompt "Which .env file would you like to load? (number)" choice
        fi
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#env_key_files[@]} )); then
            log_error "Invalid choice."
            exit 1
        fi
        
        selected="${env_key_files[choice]}"
        basename "$selected" >> "$ENV_LAST"
    fi
    
    #* Load with timing *#
    env_start=$(date +%s)
    log_info "Loading $(basename "$selected")..."
    
    set -a      #? <== automatically export all variables
    source "$selected"
    set +a      #? <== turn off auto-export
    
    env_end=$(date +%s)
    env_time=$((env_end - env_start))
    
    log_ok "Loaded $(basename "$selected") successfully in ${env_time}s!"
fi

#! --- Source all .zsh files in $ENV_SRC recursively --- !#
log_info "Loading environment from ${ENV_SRC##*/}..."

#* Count files first for progress tracking *#
total_files=0
if command -v find >/dev/null 2>&1; then
    total_files=$(find "$ENV_SRC" -name "*.zsh" -type f 2>/dev/null | wc -l)
fi

if (( total_files > 0 )); then
    log_info "Found $total_files .zsh files to load"
    
    file_count=0
    src_start=$SECONDS
    
    if command -v find >/dev/null 2>&1; then
        while IFS= read -r file; do
            if [[ -r "$file" ]]; then
                ((file_count++))
                
                log_progress "[$file_count/$total_files] $(basename "$file")..."
                source "$file"
                LOADED_COUNT=$((LOADED_COUNT + 1))
            fi
        done < <(find "$ENV_SRC" -name "*.zsh" -type f 2>/dev/null)
    else
        #* Fallback: basic non-recursive search *#
        for file in "$ENV_SRC"/*.zsh; do
            if [[ -f "$file" && -r "$file" ]]; then
                ((file_count++))
                log_progress "[$file_count/?] $(basename "$file")..."
                source "$file"
                LOADED_COUNT=$((LOADED_COUNT + 1))
            fi
        done
    fi
    
    src_time=$((SECONDS - src_start))
    log_ok "Loaded $file_count files in ${src_time}s"
else
    log_warn "No .zsh files found in ${ENV_SRC##*/}"
fi

#! --- Session Summary --- !#
SESSION_DURATION=$SECONDS
ENV_VARS_AFTER=$(env | wc -l)
ENV_VARS_ADDED=$((ENV_VARS_AFTER - ENV_VARS_BEFORE))

show_summary "$SESSION_DURATION" "$LOADED_COUNT" "$ENV_VARS_ADDED"

log_ok "Environment loading complete."
EOF

log_ok "New environment successfully created and ready."