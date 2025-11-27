#!  ╔════════════════════════════════╗
#?    Custom Output - Settings (Zsh)  
#!  ╚════════════════════════════════╝

SECONDS=0
LOADED_COUNT=0
VARS_BEFORE=$(env | wc -l)
TS=$(date +%Y%m%d_%H%M%S)

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

