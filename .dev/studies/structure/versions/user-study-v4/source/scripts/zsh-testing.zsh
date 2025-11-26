# ========================================
# Environment Source Loader (zsh)
# ========================================

#! --- Default Paths --- !#
SRC_DIR=$HOME/.zshrc.d               #? <== environment source path
ENV_DIR=$HOME/.zshenv.d            #? <== environment directory path
ENV_KEYS=$ENV_DIR/keys             #? <== environment key path

#! --- Pretty Helpers --- !#
SECONDS=0
LOADED_COUNT=0
ENV_VARS_BEFORE=$(env | wc -l)
TS=$(date +%Y%m%d_%H%M%S)
log_scan() { print -P "%F{yellow}[SCAN]%f $*"; }          #* scan=    YELLOW
log_info() { print -P "%F{cyan}[INFO]%f $*"; }            #* info=    CYAN
log_warn() { print -P "%F{208}[WARN]%f $*"; }             #* warn=    ORANGE
log_error() { print -P "%F{red}[ERROR]%f $*"; }           #* error=   RED
log_ok() { print -P "%F{green}[OK]%f $*"; }               #* ok=      GREEN
log_set() { print -P "%F{blue}[SET]%f $*"; }              #* set=     BLUE
log_loading() { print -P "%F{magenta}[LOADING]%f $*"; }   #* loading= MAGENTA
log_timing() { print -P "%F{121}[TIMING]%f $*"; }         #* time=    MINT
prompt() {                                                #* prompt=  PURPLE
    local msg="$1" var_name="$2"
    print -nP "%F{135}[PROMPT]%f $msg "
    read -r "$var_name"
}
show_summary() {
    local duration=$1 files_loaded=$2 env_vars_added=$3
    print -P "%F{green}╭─ SESSION SUMMARY ─╮%f"
    print -P "%F{green}│%f Duration: ${duration}s"
    print -P "%F{green}│%f Files loaded: $files_loaded"  
    print -P "%F{green}│%f Env vars added: $env_vars_added"
    print -P "%F{green}╰──────────────────╯%f"
}

#! --- Validate directories w/ backup prompt --- !#
[[ -d "$ENV_DIR" ]] || { log_warn "$(basename "$ENV_DIR") not detected!"; exit; }

log_scan "Found $(basename "$ENV_DIR")!"
prompt "Would you like to backup $(basename "$ENV_DIR")? (y/N) " CONFIRM
if [[ "$CONFIRM" == [yY] ]]; then
    mkdir -p "$(dirname "${ENV_DIR}-${TS}")"
    cp -r "$ENV_DIR" "${ENV_DIR}-${TS}"
    log_set "Backup created at $(dirname "$ENV_DIR")"
else
    log_warn "Skipped backup generator..."
fi

#! --- List all environment keys --- !#
env_keys=()

#* Locate all environment keys (including .*.* patterns) *#
log_scan "Searching for environment keys in: $(basename "$ENV_KEYS")"
if command -v find >/dev/null 2>&1; then
    while IFS= read -r file; do
        [[ -f "$file" && -r "$file" ]] && env_keys+=("$file")
        log_info "Found file: $file"
    done < <(find "$ENV_KEYS" -maxdepth 2 \( -name "*.*" -o -name ".**" \) -type f -print0 2>/dev/null)
fi
log_set "Total environment keys added to array: ${#env_keys[@]}"

if (( ${#env_keys[@]} == 0 )); then
    log_warn "No environment keys found in $(basename "$ENV_KEYS")"
else
    if (( ${#env_keys[@]} == 1 )); then
        selected="${env_keys[1]}"
        log_info "Only one environment keys found: $(basename "$selected")"
        log_loading "$(basename "$selected") automatically being loaded..."
    else
        log_info "Found ${#env_keys[@]} environment keys:"
        for (( idx=1; idx<=${#env_keys[@]}; idx++ )); do
            file="${env_keys[idx]}"
            basefile=$(basename "$file")
            log_set "$idx: $basefile"
        done

        prompt "Which environment key would you like to load? (number)" choice
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#env_keys[@]} )); then
            log_error "Invalid choice."
            exit 1
        fi
        
        selected="${env_keys[choice]}"

    fi
    
    #* Load with timing *#
    env_start=$TS
    log_loading "Loading $(basename "$selected")..."
    
    set -a      #? <== automatically export all variables
    source "$selected"
    set +a      #? <== turn off auto-export
    
    env_end=$TS
    env_time=$((env_end - env_start))
    
    log_ok "Loaded $(basename "$selected") successfully in ${env_time}s!"
fi

#! --- Source all .zsh files in $SRC_DIR recursively --- !#
log_info "Loading environment from $(basename "$SRC_DIR")..."

#* Count files first for progress tracking *#
total_files=0
if command -v find >/dev/null 2>&1; then
    total_files=$(find "$SRC_DIR" -name "*.zsh" -type f 2>/dev/null | wc -l)
fi

if (( total_files > 0 )); then
    log_info "Found $total_files .zsh files to load"
    
    file_count=0
    src_start=$SECONDS
    
    if command -v find >/dev/null 2>&1; then
        while IFS= read -r file; do
            if [[ -r "$file" ]]; then
                ((file_count++))
                
                log_loading "[$file_count/$total_files] $(basename "$file")..."
                source "$file"
                LOADED_COUNT=$((LOADED_COUNT + 1))
            fi
        done < <(find "$SRC_DIR" -name "*.zsh" -type f 2>/dev/null)
    else
        #* Fallback: basic non-recursive search *#
        for file in "$SRC_DIR"/*.zsh; do
            if [[ -f "$file" && -r "$file" ]]; then
                ((file_count++))
                log_loading "[$file_count/?] $(basename "$file")..."
                source "$file"
                LOADED_COUNT=$((LOADED_COUNT + 1))
            fi
        done
    fi
    
    src_time=$((SECONDS - src_start))
    log_set "Loaded $file_count files in ${src_time}s"
else
    log_warn "No source files found in $(basename "$SRC_DIR")"
fi

#! --- Session Summary --- !#
SESSION_DURATION=$SECONDS
ENV_VARS_AFTER=$(env | wc -l)
ENV_VARS_ADDED=$((ENV_VARS_AFTER - ENV_VARS_BEFORE))

show_summary "$SESSION_DURATION" "$LOADED_COUNT" "$ENV_VARS_ADDED"

log_ok "Environment loading complete."