#!/bin/zsh

###################
# FINDA - Fast File & Content Search CLI
# A comprehensive search suite for files, directories, and content
###################

# Configuration directory
FINDA_CONFIG_DIR="${HOME}/.config/finda"
FINDA_CONFIG_FILE="${FINDA_CONFIG_DIR}/config"
FINDA_HISTORY_FILE="${FINDA_CONFIG_DIR}/history"

# Initialize config
_finda_init_config() {
  if [[ ! -d "$FINDA_CONFIG_DIR" ]]; then
    mkdir -p "$FINDA_CONFIG_DIR"
  fi
  
  if [[ ! -f "$FINDA_CONFIG_FILE" ]]; then
    cat > "$FINDA_CONFIG_FILE" << 'EOF'
# FINDA Configuration
FINDA_MAX_DEPTH=10
FINDA_CASE_SENSITIVE=false
FINDA_FOLLOW_SYMLINKS=false
FINDA_SHOW_HIDDEN=false
FINDA_USE_COLORS=true
FINDA_MAX_RESULTS=100
FINDA_EXCLUDE_DIRS=".git,node_modules,.venv,__pycache__,.cache,dist,build,.next,target"
FINDA_EXCLUDE_FILES=".DS_Store,*.pyc,*.swp,*.swo,*~"
FINDA_CODE_EXTENSIONS="js,jsx,ts,tsx,py,go,rs,java,c,cpp,h,hpp,rb,php,sh,zsh,bash"
FINDA_SAVE_HISTORY=true
EOF
  fi
  source "$FINDA_CONFIG_FILE"
  
  # Initialize history file
  [[ ! -f "$FINDA_HISTORY_FILE" ]] && touch "$FINDA_HISTORY_FILE"
}

_finda_init_config

# Color codes
_finda_colors() {
  if [[ "$FINDA_USE_COLORS" == "true" && -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
  else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' NC=''
  fi
}
_finda_colors

# Utility functions
_finda_error() {
  echo "${RED}❌ Error:${NC} $1" >&2
}

_finda_warning() {
  echo "${YELLOW}⚠️  Warning:${NC} $1"
}

_finda_success() {
  echo "${GREEN}✅${NC} $1"
}

_finda_info() {
  echo "${BLUE}ℹ️${NC}  $1"
}

_finda_save_history() {
  if [[ "$FINDA_SAVE_HISTORY" == "true" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$FINDA_HISTORY_FILE"
  fi
}

_finda_build_exclude_args() {
  local exclude_args=""
  
  # Exclude directories
  IFS=',' read -rA exclude_dirs <<< "$FINDA_EXCLUDE_DIRS"
  for dir in "${exclude_dirs[@]}"; do
    exclude_args+=" -not -path '*/${dir}/*'"
  done
  
  # Exclude hidden files unless enabled
  if [[ "$FINDA_SHOW_HIDDEN" != "true" ]]; then
    exclude_args+=" -not -path '*/.*'"
  fi
  
  echo "$exclude_args"
}

_finda_highlight() {
  local pattern="$1"
  local text="$2"
  echo "$text" | sed "s/${pattern}/${YELLOW}${BOLD}&${NC}/g"
}

_finda_format_size() {
  local size=$1
  if command -v numfmt &> /dev/null; then
    numfmt --to=iec-i --suffix=B "$size"
  else
    echo "${size}B"
  fi
}

_finda_count_results() {
  local count=0
  while IFS= read -r line; do
    ((count++))
    if [[ $count -le $FINDA_MAX_RESULTS ]]; then
      echo "$line"
    fi
  done
  
  if [[ $count -gt $FINDA_MAX_RESULTS ]]; then
    _finda_warning "Showing first $FINDA_MAX_RESULTS of $count results"
    _finda_info "Refine your search or increase FINDA_MAX_RESULTS"
  fi
}

# Main function
finda() {
  local cmd=$1
  shift
  
  case "$cmd" in
    
    ###################
    # FILE SEARCH
    ###################
    
    file|f)
      if [[ -z "$1" ]]; then
        _finda_error "Search pattern required"
        echo "Usage: finda file <pattern> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local search_dir="${2:-.}"
      local case_flag=""
      
      [[ "$FINDA_CASE_SENSITIVE" != "true" ]] && case_flag="-iname"
      [[ "$FINDA_CASE_SENSITIVE" == "true" ]] && case_flag="-name"
      
      _finda_save_history "file" "$@"
      _finda_info "Searching for files matching: ${CYAN}$pattern${NC} in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type f $case_flag '*${pattern}*' $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "?")
        local size_fmt=$(_finda_format_size "$size")
        local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
        echo "${GREEN}${file}${NC}"
        echo "  ${DIM}Size: ${size_fmt} | Modified: ${modified}${NC}"
      done | _finda_count_results
      ;;
      
    dir|d)
      if [[ -z "$1" ]]; then
        _finda_error "Search pattern required"
        echo "Usage: finda dir <pattern> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local search_dir="${2:-.}"
      local case_flag=""
      
      [[ "$FINDA_CASE_SENSITIVE" != "true" ]] && case_flag="-iname"
      [[ "$FINDA_CASE_SENSITIVE" == "true" ]] && case_flag="-name"
      
      _finda_save_history "dir" "$@"
      _finda_info "Searching for directories matching: ${CYAN}$pattern${NC} in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type d $case_flag '*${pattern}*' $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r dir; do
        local item_count=$(find "$dir" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
        ((item_count--)) # Subtract 1 for the directory itself
        echo "${BLUE}${dir}${NC}"
        echo "  ${DIM}Items: ${item_count}${NC}"
      done | _finda_count_results
      ;;
      
    ext|extension)
      if [[ -z "$1" ]]; then
        _finda_error "File extension required"
        echo "Usage: finda ext <extension> [directory]"
        return 1
      fi
      
      local extension="${1#.}" # Remove leading dot if present
      local search_dir="${2:-.}"
      
      _finda_save_history "ext" "$@"
      _finda_info "Searching for ${CYAN}.${extension}${NC} files in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type f -name '*.${extension}' $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "?")
        local size_fmt=$(_finda_format_size "$size")
        echo "${GREEN}${file}${NC} ${DIM}(${size_fmt})${NC}"
      done | _finda_count_results
      ;;
      
    big|large)
      local size="${1:-100M}"
      local search_dir="${2:-.}"
      
      _finda_save_history "big" "$@"
      _finda_info "Searching for files larger than ${CYAN}${size}${NC} in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type f -size +${size} $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "?")
        local size_fmt=$(_finda_format_size "$size")
        echo "${size_fmt} ${GREEN}${file}${NC}"
      done | sort -hr | _finda_count_results
      ;;
      
    empty)
      local search_dir="${1:-.}"
      
      _finda_save_history "empty" "$@"
      _finda_info "Searching for empty files and directories in ${CYAN}$search_dir${NC}"
      
      echo "${BOLD}Empty files:${NC}"
      find "$search_dir" -maxdepth "$FINDA_MAX_DEPTH" -type f -empty 2>/dev/null | while IFS= read -r file; do
        echo "  ${YELLOW}${file}${NC}"
      done | _finda_count_results
      
      echo ""
      echo "${BOLD}Empty directories:${NC}"
      find "$search_dir" -maxdepth "$FINDA_MAX_DEPTH" -type d -empty 2>/dev/null | while IFS= read -r dir; do
        echo "  ${BLUE}${dir}${NC}"
      done | _finda_count_results
      ;;
      
    recent)
      local days="${1:-7}"
      local search_dir="${2:-.}"
      
      _finda_save_history "recent" "$@"
      _finda_info "Searching for files modified in last ${CYAN}${days}${NC} days in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type f -mtime -${days} $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r file; do
        local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
        echo "${modified} ${GREEN}${file}${NC}"
      done | sort -r | _finda_count_results
      ;;
      
    old)
      local days="${1:-365}"
      local search_dir="${2:-.}"
      
      _finda_save_history "old" "$@"
      _finda_info "Searching for files older than ${CYAN}${days}${NC} days in ${CYAN}$search_dir${NC}"
      
      local exclude_args=$(_finda_build_exclude_args)
      local find_cmd="find '$search_dir' -maxdepth $FINDA_MAX_DEPTH -type f -mtime +${days} $exclude_args 2>/dev/null"
      
      eval "$find_cmd" | while IFS= read -r file; do
        local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
        echo "${modified} ${GREEN}${file}${NC}"
      done | sort | _finda_count_results
      ;;
    
    ###################
    # CONTENT SEARCH
    ###################
    
    code|grep|g)
      if [[ -z "$1" ]]; then
        _finda_error "Search pattern required"
        echo "Usage: finda code <pattern> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local search_dir="${2:-.}"
      local case_flag=""
      
      [[ "$FINDA_CASE_SENSITIVE" != "true" ]] && case_flag="-i"
      
      _finda_save_history "code" "$@"
      _finda_info "Searching for ${CYAN}${pattern}${NC} in code files in ${CYAN}$search_dir${NC}"
      
      # Build exclude patterns for grep
      local grep_exclude=""
      IFS=',' read -rA exclude_dirs <<< "$FINDA_EXCLUDE_DIRS"
      for dir in "${exclude_dirs[@]}"; do
        grep_exclude+=" --exclude-dir=${dir}"
      done
      
      # Use ripgrep if available (much faster)
      if command -v rg &> /dev/null; then
        local rg_case_flag=""
        [[ "$FINDA_CASE_SENSITIVE" != "true" ]] && rg_case_flag="-i"
        
        rg $rg_case_flag -n --color=always --heading "$pattern" "$search_dir" 2>/dev/null | head -n $((FINDA_MAX_RESULTS * 3))
      else
        # Fallback to grep
        grep -rn $case_flag --color=always $grep_exclude "$pattern" "$search_dir" 2>/dev/null | \
        while IFS=: read -r file line content; do
          echo "${GREEN}${file}${NC}:${YELLOW}${line}${NC}"
          echo "  $content"
          echo ""
        done | head -n $((FINDA_MAX_RESULTS * 3))
      fi
      ;;
      
    text|txt)
      if [[ -z "$1" ]]; then
        _finda_error "Search pattern required"
        echo "Usage: finda text <pattern> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local search_dir="${2:-.}"
      local case_flag=""
      
      [[ "$FINDA_CASE_SENSITIVE" != "true" ]] && case_flag="-i"
      
      _finda_save_history "text" "$@"
      _finda_info "Searching for ${CYAN}${pattern}${NC} in text files in ${CYAN}$search_dir${NC}"
      
      find "$search_dir" -type f \( -name "*.txt" -o -name "*.md" -o -name "*.log" \) -maxdepth "$FINDA_MAX_DEPTH" 2>/dev/null | \
      while IFS= read -r file; do
        if grep -q $case_flag "$pattern" "$file" 2>/dev/null; then
          echo "${GREEN}${file}${NC}"
          grep -n $case_flag --color=always "$pattern" "$file" 2>/dev/null | head -5
          echo ""
        fi
      done | _finda_count_results
      ;;
      
    todo|fixme)
      local search_dir="${1:-.}"
      local patterns=("TODO" "FIXME" "HACK" "XXX" "BUG" "NOTE")
      
      _finda_save_history "todo" "$@"
      _finda_info "Searching for code comments (TODO, FIXME, etc.) in ${CYAN}$search_dir${NC}"
      
      for pattern in "${patterns[@]}"; do
        echo "${BOLD}${MAGENTA}=== ${pattern} ===${NC}"
        if command -v rg &> /dev/null; then
          rg -n --color=always "$pattern" "$search_dir" 2>/dev/null | head -20
        else
          grep -rn --color=always "$pattern" "$search_dir" 2>/dev/null | head -20
        fi
        echo ""
      done
      ;;
      
    word|w)
      if [[ -z "$1" ]]; then
        _finda_error "Search word required"
        echo "Usage: finda word <word> [directory]"
        return 1
      fi
      
      local word="$1"
      local search_dir="${2:-.}"
      
      _finda_save_history "word" "$@"
      _finda_info "Searching for whole word ${CYAN}${word}${NC} in ${CYAN}$search_dir${NC}"
      
      if command -v rg &> /dev/null; then
        rg -w -n --color=always "$word" "$search_dir" 2>/dev/null | head -n $((FINDA_MAX_RESULTS * 3))
      else
        grep -rnw --color=always "$word" "$search_dir" 2>/dev/null | head -n $((FINDA_MAX_RESULTS * 3))
      fi
      ;;
    
    ###################
    # SPECIALIZED SEARCH
    ###################
    
    duplicate|dup)
      local search_dir="${1:-.}"
      
      _finda_save_history "duplicate" "$@"
      _finda_info "Searching for duplicate files in ${CYAN}$search_dir${NC}"
      
      if command -v fdupes &> /dev/null; then
        fdupes -r "$search_dir"
      else
        _finda_warning "fdupes not installed. Using fallback method..."
        find "$search_dir" -type f -exec md5sum {} + 2>/dev/null | \
        sort | \
        awk '{
          if ($1 == prev) {
            if (!printed) {
              print prevfile
              printed = 1
            }
            print $2
          } else {
            prev = $1
            prevfile = $2
            printed = 0
          }
        }'
      fi
      ;;
      
    broken|symlink)
      local search_dir="${1:-.}"
      
      _finda_save_history "broken" "$@"
      _finda_info "Searching for broken symlinks in ${CYAN}$search_dir${NC}"
      
      find "$search_dir" -type l -maxdepth "$FINDA_MAX_DEPTH" 2>/dev/null | while IFS= read -r link; do
        if [[ ! -e "$link" ]]; then
          local target=$(readlink "$link")
          echo "${RED}${link}${NC} -> ${DIM}${target}${NC} ${RED}(broken)${NC}"
        fi
      done | _finda_count_results
      ;;
      
    exec|executable)
      local search_dir="${1:-.}"
      
      _finda_save_history "exec" "$@"
      _finda_info "Searching for executable files in ${CYAN}$search_dir${NC}"
      
      find "$search_dir" -type f -perm +111 -maxdepth "$FINDA_MAX_DEPTH" 2>/dev/null | \
      while IFS= read -r file; do
        echo "${GREEN}${file}${NC}"
      done | _finda_count_results
      ;;
      
    type)
      local search_dir="${1:-.}"
      
      _finda_save_history "type" "$@"
      _finda_info "Analyzing file types in ${CYAN}$search_dir${NC}"
      
      find "$search_dir" -type f -maxdepth "$FINDA_MAX_DEPTH" 2>/dev/null | \
      awk -F. '{if (NF>1) print $NF}' | \
      sort | uniq -c | sort -rn | head -20 | \
      while read -r count ext; do
        printf "${CYAN}%-10s${NC} %s files\n" ".$ext" "$count"
      done
      ;;
    
    ###################
    # UTILITIES
    ###################
    
    tree)
      local search_dir="${1:-.}"
      local depth="${2:-3}"
      
      _finda_save_history "tree" "$@"
      
      if command -v tree &> /dev/null; then
        tree -L "$depth" -C "$search_dir"
      else
        find "$search_dir" -maxdepth "$depth" 2>/dev/null | \
        sed "s|^${search_dir}/||" | \
        awk '{
          depth = gsub(/\//, "/")
          for (i=0; i<depth; i++) printf "  "
          print $0
        }'
      fi
      ;;
      
    count)
      local search_dir="${1:-.}"
      
      _finda_save_history "count" "$@"
      echo "${BOLD}📊 File Statistics for ${CYAN}${search_dir}${NC}${BOLD}:${NC}"
      echo ""
      
      local total_files=$(find "$search_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
      local total_dirs=$(find "$search_dir" -type d 2>/dev/null | wc -l | tr -d ' ')
      local total_size=$(du -sh "$search_dir" 2>/dev/null | cut -f1)
      
      echo "Files:       ${CYAN}${total_files}${NC}"
      echo "Directories: ${CYAN}${total_dirs}${NC}"
      echo "Total size:  ${CYAN}${total_size}${NC}"
      ;;
      
    history|hist)
      if [[ ! -f "$FINDA_HISTORY_FILE" ]]; then
        _finda_info "No search history found"
        return 0
      fi
      
      local lines="${1:-20}"
      echo "${BOLD}📜 Recent searches:${NC}"
      tail -n "$lines" "$FINDA_HISTORY_FILE" | nl -w2 -s'. '
      ;;
      
    clear-history)
      if [[ -f "$FINDA_HISTORY_FILE" ]]; then
        rm "$FINDA_HISTORY_FILE"
        touch "$FINDA_HISTORY_FILE"
        _finda_success "Search history cleared"
      fi
      ;;
    
    ###################
    # CONFIG
    ###################
    
    config)
      if [[ -z "$1" ]]; then
        echo "${BOLD}Current FINDA Configuration:${NC}"
        cat "$FINDA_CONFIG_FILE"
      else
        local subcommand="$1"
        shift
        case "$subcommand" in
          edit)
            ${EDITOR:-vim} "$FINDA_CONFIG_FILE"
            _finda_init_config
            _finda_success "Config reloaded"
            ;;
          reset)
            rm "$FINDA_CONFIG_FILE"
            _finda_init_config
            _finda_success "Config reset to defaults"
            ;;
          set)
            if [[ -z "$1" || -z "$2" ]]; then
              _finda_error "Usage: finda config set <key> <value>"
              return 1
            fi
            local key="$1"
            local value="$2"
            sed -i.bak "s/^${key}=.*/${key}=${value}/" "$FINDA_CONFIG_FILE"
            _finda_init_config
            _finda_success "Set ${key}=${value}"
            ;;
          *)
            _finda_error "Unknown config command: $subcommand"
            ;;
        esac
      fi
      ;;
    
    ###################
    # HELP
    ###################
    
    help|--help|-h)
      cat << EOF
${BOLD}🔍 FINDA - Fast File & Content Search CLI${NC}

${BOLD}📁 FILE SEARCH:${NC}
  finda file <pattern> [dir]       Search for files by name
  finda dir <pattern> [dir]        Search for directories by name
  finda ext <extension> [dir]      Find files by extension
  finda big [size] [dir]           Find large files (default: >100M)
  finda empty [dir]                Find empty files and directories
  finda recent [days] [dir]        Files modified in last N days (default: 7)
  finda old [days] [dir]           Files older than N days (default: 365)

${BOLD}🔎 CONTENT SEARCH:${NC}
  finda code <pattern> [dir]       Search in code files (uses ripgrep if available)
  finda text <pattern> [dir]       Search in text files (.txt, .md, .log)
  finda word <word> [dir]          Search for whole word
  finda todo [dir]                 Find TODO, FIXME, HACK comments

${BOLD}🔧 SPECIALIZED:${NC}
  finda duplicate [dir]            Find duplicate files
  finda broken [dir]               Find broken symlinks
  finda exec [dir]                 Find executable files
  finda type [dir]                 Analyze file types distribution

${BOLD}📊 UTILITIES:${NC}
  finda tree [dir] [depth]         Show directory tree (default depth: 3)
  finda count [dir]                Count files, dirs, and size
  finda history [n]                Show last N searches (default: 20)
  finda clear-history              Clear search history

${BOLD}⚙️  CONFIG:${NC}
  finda config                     Show configuration
  finda config edit                Edit config file
  finda config set <key> <value>   Set config value
  finda config reset               Reset to defaults

${BOLD}❓ HELP:${NC}
  finda help                       Show this help

${BOLD}Configuration Options:${NC}
  FINDA_MAX_DEPTH          Max directory depth (default: 10)
  FINDA_CASE_SENSITIVE     Case sensitive search (default: false)
  FINDA_SHOW_HIDDEN        Show hidden files (default: false)
  FINDA_MAX_RESULTS        Max results to show (default: 100)
  FINDA_EXCLUDE_DIRS       Comma-separated dirs to exclude
  FINDA_EXCLUDE_FILES      Comma-separated file patterns to exclude

${BOLD}Examples:${NC}
  finda file config.json            # Find config.json files
  finda ext py src/                 # Find all .py files in src/
  finda code "function.*user"       # Search for function definitions
  finda big 50M ~/Downloads         # Find files larger than 50MB
  finda recent 3                    # Files modified in last 3 days

${BLUE}ℹ️  Config file: ${FINDA_CONFIG_FILE}${NC}
${BLUE}ℹ️  History file: ${FINDA_HISTORY_FILE}${NC}

${YELLOW}💡 Tip: Install 'ripgrep' (rg) for faster code searches!${NC}
${YELLOW}💡 Tip: Install 'fdupes' for better duplicate detection!${NC}
EOF
      ;;
      
    version|--version|-v)
      echo "${BOLD}FINDA${NC} version 1.0.0"
      echo "Dependencies:"
      command -v rg &> /dev/null && echo "  ✅ ripgrep (fast search)" || echo "  ❌ ripgrep (optional, recommended)"
      command -v fdupes &> /dev/null && echo "  ✅ fdupes (duplicate detection)" || echo "  ❌ fdupes (optional)"
      command -v tree &> /dev/null && echo "  ✅ tree (directory visualization)" || echo "  ❌ tree (optional)"
      ;;
      
    *)
      if [[ -z "$cmd" ]]; then
        finda help
      else
        _finda_error "Unknown command: $cmd"
        echo "Run ${CYAN}finda help${NC} for usage"
        return 1
      fi
      ;;
  esac
}

# Zsh completion
if [[ -n "$ZSH_VERSION" ]]; then
  _finda_completion() {
    local -a commands
    commands=(
      'file:Search for files by name'
      'dir:Search for directories'
      'ext:Find files by extension'
      'big:Find large files'
      'empty:Find empty files/dirs'
      'recent:Recently modified files'
      'old:Old files'
      'code:Search in code files'
      'text:Search in text files'
      'word:Search for whole word'
      'todo:Find TODO comments'
      'duplicate:Find duplicate files'
      'broken:Find broken symlinks'
      'exec:Find executable files'
      'type:Analyze file types'
      'tree:Show directory tree'
      'count:Count files and dirs'
      'history:Show search history'
      'clear-history:Clear history'
      'config:Configuration'
      'help:Show help'
      'version:Show version'
    )
    _describe 'finda commands' commands
  }
  
  compdef _finda_completion finda
fi

# Shorter aliases (optional - uncomment if desired)
# alias ff='finda file'
# alias fd='finda dir'
# alias fg='finda code'
# alias fb='finda big'
