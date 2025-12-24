#!  ╔═══════════════════════════════════════════╗
#!    Jesse Conley's Environment Loader- v1.0.0 
#!  ╚═══════════════════════════════════════════╝


#! --- Configs --- !#
: "${ENV_DIR:=$HOME/.zshrc.d}"

# ========================================
#  Helpers (Zsh)
# ========================================
log_scan() { print -P "%F{220}[SCAN]%f $*"; }             #* scan=    GOLD
log_info() { print -P "%F{cyan}[INFO]%f $*"; }            #* info=    CYAN
log_warn() { print -P "%F{208}[WARN]%f $*"; }             #* warn=    ORANGE
log_error() { print -P "%F{red}[ERROR]%f $*"; }           #* error=   RED
log_ok() { print -P "%F{121}[OK]%f $*"; }                 #* ok=      MINT
log_set() { print -P "%F{148}[SET]%f $*"; }               #* set=     KHAKI
log_loading() { print -P "%F{160}[LOADING]%f $*"; }       #* loading= CRIMSON
log_timing() { print -P "%F{blue}[TIMING]%f $*"; }        #* time=    BLUE
prompt() {                                                #* prompt=  VIOLET
    local msg="$1" var_name="$2"
    print -nP "%F{99}[PROMPT]%f $msg "
    read -r "$var_name"
}
zboxxy() {
    local text="$1"
    local width="${2:-60}"
    local left="│ "
    local right=" │"
    local content_width=$((width - ${#left} - ${#right}))

    while [[ -n "$text" ]]; do
        local line="${text:0:content_width}"
        printf "%s%-*s%s\n" "$left" "$content_width" "$line" "$right"
        text="${text:content_width}"
    done
}
section() {
    local title="$1"
    echo
    print -P "%F{green}╭─ SESSION LOADED ─╮%f"
    print -P "%F{green}│%f Category: $title"
    print -P "%F{green}╰──────────────────╯%f"
}
summary() {
    local duration=$1 files_loaded=$2 vars_added=$3
    echo
    print -P "%F{green}╭─ SESSION SUMMARY ─╮%f"
    print -P "%F{green}│%f Duration: ${duration}s"
    print -P "%F{green}│%f Files loaded: $files_loaded"
    print -P "%F{green}│%f Vars added: $vars_added"
    print -P "%F{green}╰──────────────────╯%f"
}

SECONDS=0
LOADED_COUNT=0
VARS_BEFORE=$(env | wc -l)
TS=$(date +%Y%m%d_%H%M%S)

#! --- Symlink dotfiles (ignores . and ..) --- !#
log_info "Setting Up a system link for all defined dotfiles"
for f in $ENV_DIR/dotfiles/.[^.]*; do
    ln -sfnv "$f" ~/
done
log_set "All dotfiles linked to $HOME/"


#! --- Validate Targets (.zshenv.d) --- !#
[[ -d "$ENV_DIR" ]] || { log_warn "$(basename "$ENV_DIR") not detected!"; exit; }

log_scan "Found $(basename "$ENV_DIR")!"
prompt "Would you like to backup $(basename "$ENV_DIR")? (y/N) " CONFIRM
if [[ "$CONFIRM" == [yY] ]]; then
    mkdir -p "$(dirname "${ENV_DIR}-${TS}")"
    cp -r "$ENV_DIR" "${ENV_DIR}-${TS}"
    log_set "Backup created at $(dirname "$ENV_DIR-$TS")"
else
    log_warn "Skipped backup generator..."
fi

#! --- List all environment --- !#
env_keys=()

#* Locate all environment (including .*.* patterns) *#
log_scan "Searching for environments in: $(dirname "$ENV_DIR/keys")"
if [[ -d "$ENV_DIR/keys" ]] && command -v find >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
        [[ -f "$file" && -r "$file" ]] && env_keys+=("$file")
        log_info "Found file: $file"
    done < <(find "$ENV_DIR/keys" -maxdepth 2 -type f -print0 2>/dev/null)
fi
log_set "Total environments added to array: ${#env_keys[@]}"

if (( ${#env_keys[@]} == 0 )); then
    log_warn "No environments found in $(dirname "$ENV_DIR/keys")"
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

#! --- Session Summary --- !#
SESSION_DURATION=$SECONDS
VARS_AFTER=$(env | wc -l)
VARS_ADDED=$((VARS_AFTER - VARS_BEFORE))

summary "$SESSION_DURATION" "$LOADED_COUNT" "$VARS_ADDED"

log_ok "Environment loading complete."