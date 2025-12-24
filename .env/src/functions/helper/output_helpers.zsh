# ============================================================================
# OUTPUT HELPERS (helpers/output_helpers.zsh) 
# ============================================================================

#!/bin/zsh
# Output formatting, colors, and display helpers

# Color definitions
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_CYAN='\033[0;36m'
export COLOR_WHITE='\033[0;37m'
export COLOR_BOLD='\033[1m'
export COLOR_RESET='\033[0m'

function output_success() {
    local message="$1"
    echo -e "${COLOR_GREEN}✅ $message${COLOR_RESET}"
}

function output_error() {
    local message="$1"
    echo -e "${COLOR_RED}❌ $message${COLOR_RESET}" >&2
}

function output_warning() {
    local message="$1"
    echo -e "${COLOR_YELLOW}⚠️  $message${COLOR_RESET}"
}

function output_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}ℹ️  $message${COLOR_RESET}"
}

function output_debug() {
    local message="$1"
    if [[ "$ZBOX_DEBUG" == "true" ]]; then
        echo -e "${COLOR_PURPLE}🐛 DEBUG: $message${COLOR_RESET}" >&2
    fi
}

function output_banner() {
    local title="$1"
    local width="${2:-60}"
    
    local padding=$(( (width - ${#title} - 4) / 2 ))
    local left_pad=$(printf "%*s" $padding "")
    local right_pad=$(printf "%*s" $((width - ${#title} - 4 - padding)) "")
    
    echo -e "${COLOR_CYAN}"
    printf "╭%*s╮\n" $((width-2)) "" | tr ' ' '─'
    printf "│%s %s %s│\n" "$left_pad" "$title" "$right_pad"
    printf "╰%*s╯\n" $((width-2)) "" | tr ' ' '─'
    echo -e "${COLOR_RESET}"
}

function output_progress_bar() {
    local current="$1"
    local total="$2"
    local label="$3"
    local width="${4:-40}"
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLOR_CYAN}%s [" "$label"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %3d%% (%d/%d)${COLOR_RESET}" $percentage $current $total
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

function output_spinner() {
    local message="$1"
    local duration="${2:-5}"
    
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while [[ $i -lt $duration ]]; do
        local char=${spinner_chars:$((i % ${#spinner_chars})):1}
        printf "\r${COLOR_BLUE}$char $message${COLOR_RESET}"
        sleep 0.1
        ((i++))
    done
    
    printf "\r${COLOR_GREEN}✅ $message - Complete${COLOR_RESET}\n"
}

function output_table() {
    local -A table_data
    local headers="$1"
    shift
    
    # Parse input data
    local max_width=20
    local IFS='|'
    
    echo -e "${COLOR_BOLD}$headers${COLOR_RESET}"
    echo "$headers" | sed 's/[^|]/-/g'
    
    for row in "$@"; do
        echo "$row"
    done
}

function output_json_pretty() {
    local json="$1"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq '.'
    else
        # Basic JSON formatting without jq
        echo "$json" | sed 's/,/,\n  /g' | sed 's/{/{\n  /' | sed 's/}/\n}/'
    fi
}

function output_box() {
    local message="$1"
    local style="${2:-single}"  # single, double, rounded
    
    local top_left="┌" top_right="┐" bottom_left="└" bottom_right="┘"
    local horizontal="─" vertical="│"
    
    case "$style" in
        "double")
            top_left="╔" top_right="╗" bottom_left="╚" bottom_right="╝"
            horizontal="═" vertical="║"
            ;;
        "rounded")
            top_left="╭" top_right="╮" bottom_left="╰" bottom_right="╯"
            ;;
    esac
    
    local width=$((${#message} + 4))
    
    echo -e "${COLOR_CYAN}"
    printf "$top_left%*s$top_right\n" $((width-2)) "" | tr ' ' "$horizontal"
    printf "$vertical  %s  $vertical\n" "$message"
    printf "$bottom_left%*s$bottom_right\n" $((width-2)) "" | tr ' ' "$horizontal"
    echo -e "${COLOR_RESET}"
}
