#!/bin/zsh

###################
# FIXA - Fast Fix Anything CLI
# A comprehensive fixing suite for files, permissions, content, and system issues
###################

# Configuration directory
FIXA_CONFIG_DIR="${HOME}/.config/fixa"
FIXA_CONFIG_FILE="${FIXA_CONFIG_DIR}/config"
FIXA_LOG_FILE="${FIXA_CONFIG_DIR}/fix.log"

# Initialize config
_fixa_init_config() {
  if [[ ! -d "$FIXA_CONFIG_DIR" ]]; then
    mkdir -p "$FIXA_CONFIG_DIR"
  fi
  
  if [[ ! -f "$FIXA_CONFIG_FILE" ]]; then
    cat > "$FIXA_CONFIG_FILE" << 'EOF'
# FIXA Configuration
FIXA_AUTO_BACKUP=true
FIXA_BACKUP_DIR="${HOME}/.fixa-backups"
FIXA_CONFIRM_DESTRUCTIVE=true
FIXA_SHOW_DIFF=true
FIXA_LOG_FIXES=true
FIXA_MAX_FILE_SIZE=10M
FIXA_EXCLUDE_DIRS=".git,node_modules,.venv,__pycache__"
FIXA_DRY_RUN=false
EOF
  fi
  source "$FIXA_CONFIG_FILE"
  
  # Initialize log file
  [[ ! -f "$FIXA_LOG_FILE" ]] && touch "$FIXA_LOG_FILE"
  
  # Create backup directory
  [[ ! -d "$FIXA_BACKUP_DIR" ]] && mkdir -p "$FIXA_BACKUP_DIR"
}

_fixa_init_config

# Color codes
_fixa_colors() {
  if [[ -t 1 ]]; then
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
_fixa_colors

# Utility functions
_fixa_error() {
  echo "${RED}❌ Error:${NC} $1" >&2
  _fixa_log "ERROR: $1"
}

_fixa_warning() {
  echo "${YELLOW}⚠️  Warning:${NC} $1"
  _fixa_log "WARNING: $1"
}

_fixa_success() {
  echo "${GREEN}✅${NC} $1"
  _fixa_log "SUCCESS: $1"
}

_fixa_info() {
  echo "${BLUE}ℹ️${NC}  $1"
}

_fixa_log() {
  if [[ "$FIXA_LOG_FIXES" == "true" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$FIXA_LOG_FILE"
  fi
}

_fixa_confirm() {
  local prompt="$1"
  local response
  echo -n "${YELLOW}${prompt}${NC} (y/n): "
  read response
  [[ "$response" =~ ^[Yy]$ ]]
}

_fixa_backup() {
  local file="$1"
  if [[ "$FIXA_AUTO_BACKUP" == "true" && -f "$file" ]]; then
    local backup_path="${FIXA_BACKUP_DIR}/$(date '+%Y%m%d_%H%M%S')_${file##*/}"
    cp "$file" "$backup_path" 2>/dev/null
    echo "$backup_path"
  fi
}

_fixa_backup_dir() {
  local dir="$1"
  if [[ "$FIXA_AUTO_BACKUP" == "true" && -d "$dir" ]]; then
    local backup_name="$(basename "$dir")-backup-$(date +%Y%m%d_%H%M%S)"
    local backup_path="${FIXA_BACKUP_DIR}/${backup_name}"
    cp -r "$dir" "$backup_path" 2>/dev/null
    echo "$backup_path"
  fi
}

_fixa_detect_sed() {
  if sed --version >/dev/null 2>&1; then
    echo "sed -i"
  else
    echo "sed -i ''"
  fi
}

_fixa_build_exclude_args() {
  local exclude_args=""
  IFS=',' read -rA exclude_dirs <<< "$FIXA_EXCLUDE_DIRS"
  for dir in "${exclude_dirs[@]}"; do
    exclude_args+=" -not -path '*/${dir}/*'"
  done
  echo "$exclude_args"
}

# Main function
fixa() {
  local cmd=$1
  shift
  
  case "$cmd" in
    
    ###################
    # CONTENT FIXING
    ###################
    
    content|replace)
      local target_dir="${1:-.}"
      
      if [[ ! -d "$target_dir" ]]; then
        _fixa_error "Directory not found: $target_dir"
        return 1
      fi
      
      _fixa_info "Interactive content replacement in ${CYAN}${target_dir}${NC}"
      echo ""
      
      # Get search pattern
      echo -n "Find (text or regex): "
      read find_pattern
      [[ -z "$find_pattern" ]] && { _fixa_error "Find pattern cannot be empty"; return 1; }
      
      # Get replacement
      echo -n "Replace with: "
      read replace_text
      
      # Escape replacement for sed
      local esc_replace="${replace_text//&/\\&}"
      local esc_replace="${esc_replace//\//\\/}"
      
      _fixa_log "CONTENT: find='$find_pattern' replace='$replace_text' dir='$target_dir'"
      
      echo ""
      echo "${BOLD}📂 Target:${NC} $target_dir"
      echo "${BOLD}🔍 Find:${NC} '$find_pattern'"
      echo "${BOLD}✏️  Replace:${NC} '$replace_text'"
      echo ""
      
      # Find matching files
      local exclude_args=$(_fixa_build_exclude_args)
      local files=()
      while IFS= read -r file; do
        files+=("$file")
      done < <(eval "find '$target_dir' -type f -size -${FIXA_MAX_FILE_SIZE} $exclude_args -exec grep -l '$find_pattern' {} \; 2>/dev/null")
      
      if [[ ${#files[@]} -eq 0 ]]; then
        _fixa_info "No files found containing '$find_pattern'"
        return 0
      fi
      
      _fixa_success "Found ${#files[@]} file(s) with matches"
      echo ""
      
      # Backup directory
      local backup_path=$(_fixa_backup_dir "$target_dir")
      [[ -n "$backup_path" ]] && _fixa_info "Backup created: $backup_path"
      echo ""
      
      # Preview mode
      if _fixa_confirm "Preview all changes first?"; then
        for file in "${files[@]}"; do
          local rel_path="${file#$target_dir/}"
          echo "${BOLD}${CYAN}━━━ $rel_path ━━━${NC}"
          if command -v diff &> /dev/null && [[ "$FIXA_SHOW_DIFF" == "true" ]]; then
            diff --unified --color=always "$file" <(sed "s|$find_pattern|$esc_replace|g" "$file") 2>/dev/null || true
          else
            echo "${DIM}Before:${NC}"
            grep --color=always "$find_pattern" "$file" | head -3
            echo "${DIM}After:${NC}"
            sed "s|$find_pattern|$esc_replace|g" "$file" | grep --color=always "$replace_text" | head -3
          fi
          echo ""
        done
        
        if ! _fixa_confirm "Apply changes to ALL files?"; then
          _fixa_info "No changes made"
          return 0
        fi
      fi
      
      # Apply changes
      local sed_cmd=$(_fixa_detect_sed)
      local updated=0
      
      for file in "${files[@]}"; do
        local rel_path="${file#$target_dir/}"
        
        if [[ "$FIXA_DRY_RUN" == "true" ]]; then
          echo "${YELLOW}[DRY RUN]${NC} Would update: $rel_path"
          ((updated++))
        else
          if eval "$sed_cmd 's|$find_pattern|$esc_replace|g' '$file'"; then
            echo "${GREEN}✅${NC} Updated: $rel_path"
            ((updated++))
          else
            echo "${RED}❌${NC} Failed: $rel_path"
          fi
        fi
      done
      
      echo ""
      _fixa_success "Updated $updated file(s)"
      [[ -n "$backup_path" ]] && echo "${BLUE}💾 Backup:${NC} $backup_path"
      ;;
      
    regex|rx)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa regex <pattern> <replacement> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local replacement="$2"
      local target_dir="${3:-.}"
      
      _fixa_info "Applying regex replacement in ${CYAN}${target_dir}${NC}"
      _fixa_log "REGEX: pattern='$pattern' replacement='$replacement' dir='$target_dir'"
      
      local exclude_args=$(_fixa_build_exclude_args)
      local sed_cmd=$(_fixa_detect_sed)
      local updated=0
      
      eval "find '$target_dir' -type f -size -${FIXA_MAX_FILE_SIZE} $exclude_args 2>/dev/null" | \
      while IFS= read -r file; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
          _fixa_backup "$file"
          if eval "$sed_cmd 's|$pattern|$replacement|g' '$file'"; then
            echo "${GREEN}✅${NC} ${file#$target_dir/}"
            ((updated++))
          fi
        fi
      done
      
      _fixa_success "Updated $updated file(s)"
      ;;
    
    ###################
    # LINE OPERATIONS
    ###################
    
    line-remove|rmline)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa line-remove <pattern> <file>"
        return 1
      fi
      
      local pattern="$1"
      local file="$2"
      
      if [[ ! -f "$file" ]]; then
        _fixa_error "File not found: $file"
        return 1
      fi
      
      _fixa_log "LINE-REMOVE: pattern='$pattern' file='$file'"
      
      local backup_path=$(_fixa_backup "$file")
      local count=$(grep -c "$pattern" "$file" 2>/dev/null || echo 0)
      
      if [[ $count -eq 0 ]]; then
        _fixa_info "No lines match pattern: $pattern"
        return 0
      fi
      
      _fixa_info "Found $count line(s) matching: $pattern"
      
      if [[ "$FIXA_SHOW_DIFF" == "true" ]]; then
        echo "${BOLD}Lines to remove:${NC}"
        grep --color=always -n "$pattern" "$file"
        echo ""
      fi
      
      if _fixa_confirm "Remove these lines?"; then
        local sed_cmd=$(_fixa_detect_sed)
        eval "$sed_cmd '/$pattern/d' '$file'"
        _fixa_success "Removed $count line(s)"
        [[ -n "$backup_path" ]] && echo "${BLUE}💾 Backup:${NC} $backup_path"
      fi
      ;;
      
    line-add|addline)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa line-add <line> <file> [position]"
        echo "Positions: start, end, before:<pattern>, after:<pattern>"
        return 1
      fi
      
      local line="$1"
      local file="$2"
      local position="${3:-end}"
      
      if [[ ! -f "$file" ]]; then
        _fixa_error "File not found: $file"
        return 1
      fi
      
      _fixa_log "LINE-ADD: line='$line' file='$file' position='$position'"
      _fixa_backup "$file"
      
      case "$position" in
        start)
          sed -i.bak "1i\\
$line" "$file"
          _fixa_success "Added line at start"
          ;;
        end)
          echo "$line" >> "$file"
          _fixa_success "Added line at end"
          ;;
        before:*)
          local pattern="${position#before:}"
          sed -i.bak "/$pattern/i\\
$line" "$file"
          _fixa_success "Added line before: $pattern"
          ;;
        after:*)
          local pattern="${position#after:}"
          sed -i.bak "/$pattern/a\\
$line" "$file"
          _fixa_success "Added line after: $pattern"
          ;;
        *)
          _fixa_error "Invalid position: $position"
          return 1
          ;;
      esac
      ;;
      
    dedupe|dedup)
      if [[ -z "$1" ]]; then
        _fixa_error "Usage: fixa dedupe <file>"
        return 1
      fi
      
      local file="$1"
      
      if [[ ! -f "$file" ]]; then
        _fixa_error "File not found: $file"
        return 1
      fi
      
      _fixa_log "DEDUPE: file='$file'"
      
      local original_lines=$(wc -l < "$file" | tr -d ' ')
      _fixa_backup "$file"
      
      awk '!seen[$0]++' "$file" > "${file}.tmp"
      mv "${file}.tmp" "$file"
      
      local new_lines=$(wc -l < "$file" | tr -d ' ')
      local removed=$((original_lines - new_lines))
      
      _fixa_success "Removed $removed duplicate line(s)"
      ;;
    
    ###################
    # FILE OPERATIONS
    ###################
    
    rename|mv)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa rename <pattern> <replacement> [directory]"
        return 1
      fi
      
      local pattern="$1"
      local replacement="$2"
      local target_dir="${3:-.}"
      
      _fixa_info "Renaming files in ${CYAN}${target_dir}${NC}"
      _fixa_log "RENAME: pattern='$pattern' replacement='$replacement' dir='$target_dir'"
      
      local exclude_args=$(_fixa_build_exclude_args)
      local renamed=0
      
      eval "find '$target_dir' -depth $exclude_args 2>/dev/null" | \
      while IFS= read -r file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        
        if [[ "$basename" == *"$pattern"* ]]; then
          local new_name="${basename//$pattern/$replacement}"
          local new_path="$dirname/$new_name"
          
          echo "${CYAN}$basename${NC} → ${GREEN}$new_name${NC}"
          
          if [[ "$FIXA_DRY_RUN" != "true" ]]; then
            mv "$file" "$new_path" && ((renamed++))
          else
            ((renamed++))
          fi
        fi
      done
      
      _fixa_success "Renamed $renamed file(s)/dir(s)"
      ;;
      
    extension|ext)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa extension <old-ext> <new-ext> [directory]"
        return 1
      fi
      
      local old_ext="${1#.}"
      local new_ext="${2#.}"
      local target_dir="${3:-.}"
      
      _fixa_info "Changing extensions: ${CYAN}.${old_ext}${NC} → ${GREEN}.${new_ext}${NC}"
      _fixa_log "EXTENSION: old='$old_ext' new='$new_ext' dir='$target_dir'"
      
      local exclude_args=$(_fixa_build_exclude_args)
      local renamed=0
      
      eval "find '$target_dir' -type f -name '*.${old_ext}' $exclude_args 2>/dev/null" | \
      while IFS= read -r file; do
        local new_file="${file%.${old_ext}}.${new_ext}"
        echo "$(basename "$file") → $(basename "$new_file")"
        
        if [[ "$FIXA_DRY_RUN" != "true" ]]; then
          mv "$file" "$new_file" && ((renamed++))
        else
          ((renamed++))
        fi
      done
      
      _fixa_success "Renamed $renamed file(s)"
      ;;
      
    lowercase|lower)
      local target_dir="${1:-.}"
      
      _fixa_info "Converting filenames to lowercase in ${CYAN}${target_dir}${NC}"
      _fixa_log "LOWERCASE: dir='$target_dir'"
      
      local exclude_args=$(_fixa_build_exclude_args)
      local renamed=0
      
      eval "find '$target_dir' -depth $exclude_args 2>/dev/null" | \
      while IFS= read -r file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        local lowercase=$(echo "$basename" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$basename" != "$lowercase" ]]; then
          echo "${CYAN}$basename${NC} → ${GREEN}$lowercase${NC}"
          
          if [[ "$FIXA_DRY_RUN" != "true" ]]; then
            mv "$file" "$dirname/$lowercase" && ((renamed++))
          else
            ((renamed++))
          fi
        fi
      done
      
      _fixa_success "Renamed $renamed file(s)"
      ;;
      
    spaces|fix-spaces)
      local target_dir="${1:-.}"
      local replacement="${2:-_}"
      
      _fixa_info "Replacing spaces with '${replacement}' in ${CYAN}${target_dir}${NC}"
      _fixa_log "SPACES: dir='$target_dir' replacement='$replacement'"
      
      local exclude_args=$(_fixa_build_exclude_args)
      local renamed=0
      
      eval "find '$target_dir' -depth -name '* *' $exclude_args 2>/dev/null" | \
      while IFS= read -r file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        local fixed="${basename// /$replacement}"
        
        echo "${CYAN}$basename${NC} → ${GREEN}$fixed${NC}"
        
        if [[ "$FIXA_DRY_RUN" != "true" ]]; then
          mv "$file" "$dirname/$fixed" && ((renamed++))
        else
          ((renamed++))
        fi
      done
      
      _fixa_success "Renamed $renamed file(s)"
      ;;
    
    ###################
    # PERMISSION FIXES
    ###################
    
    perms|permissions)
      if [[ -z "$1" ]]; then
        _fixa_error "Usage: fixa perms <mode> [target]"
        echo "Common modes: 644 (files), 755 (dirs/executables), 600 (private)"
        return 1
      fi
      
      local mode="$1"
      local target="${2:-.}"
      
      _fixa_info "Setting permissions to ${CYAN}${mode}${NC} on ${CYAN}${target}${NC}"
      _fixa_log "PERMS: mode='$mode' target='$target'"
      
      if [[ "$FIXA_CONFIRM_DESTRUCTIVE" == "true" ]]; then
        if ! _fixa_confirm "Change permissions recursively?"; then
          _fixa_info "Cancelled"
          return 0
        fi
      fi
      
      if [[ -d "$target" ]]; then
        chmod -R "$mode" "$target"
        _fixa_success "Permissions updated recursively"
      elif [[ -f "$target" ]]; then
        chmod "$mode" "$target"
        _fixa_success "Permissions updated"
      else
        _fixa_error "Target not found: $target"
        return 1
      fi
      ;;
      
    fix-perms)
      local target_dir="${1:-.}"
      
      _fixa_info "Fixing standard permissions in ${CYAN}${target_dir}${NC}"
      _fixa_log "FIX-PERMS: dir='$target_dir'"
      
      if [[ "$FIXA_CONFIRM_DESTRUCTIVE" == "true" ]]; then
        _fixa_info "This will set: directories=755, files=644"
        if ! _fixa_confirm "Proceed?"; then
          _fixa_info "Cancelled"
          return 0
        fi
      fi
      
      find "$target_dir" -type d -exec chmod 755 {} \; 2>/dev/null
      find "$target_dir" -type f -exec chmod 644 {} \; 2>/dev/null
      
      _fixa_success "Fixed permissions (dirs=755, files=644)"
      ;;
      
    executable|exec)
      if [[ -z "$1" ]]; then
        _fixa_error "Usage: fixa executable <file>"
        return 1
      fi
      
      local file="$1"
      
      if [[ ! -f "$file" ]]; then
        _fixa_error "File not found: $file"
        return 1
      fi
      
      _fixa_log "EXECUTABLE: file='$file'"
      chmod +x "$file"
      _fixa_success "Made executable: $file"
      ;;
    
    ###################
    # ENCODING & FORMAT
    ###################
    
    encoding|enc)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa encoding <from> <to> <file>"
        echo "Common encodings: utf-8, iso-8859-1, ascii"
        return 1
      fi
      
      local from="$1"
      local to="$2"
      local file="$3"
      
      if [[ ! -f "$file" ]]; then
        _fixa_error "File not found: $file"
        return 1
      fi
      
      _fixa_log "ENCODING: from='$from' to='$to' file='$file'"
      _fixa_backup "$file"
      
      if command -v iconv &> /dev/null; then
        iconv -f "$from" -t "$to" "$file" > "${file}.tmp"
        mv "${file}.tmp" "$file"
        _fixa_success "Converted encoding: $from → $to"
      else
        _fixa_error "iconv not found. Install iconv to use this feature."
        return 1
      fi
      ;;
      
    lineendings|eol)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa lineendings <unix|dos|mac> <file|directory>"
        return 1
      fi
      
      local format="$1"
      local target="$2"
      
      _fixa_log "LINEENDINGS: format='$format' target='$target'"
      
      case "$format" in
        unix|lf)
          if [[ -f "$target" ]]; then
            _fixa_backup "$target"
            sed -i.bak 's/\r$//' "$target"
            _fixa_success "Converted to Unix line endings (LF)"
          elif [[ -d "$target" ]]; then
            find "$target" -type f -exec sed -i.bak 's/\r$//' {} \;
            _fixa_success "Converted all files to Unix line endings (LF)"
          fi
          ;;
        dos|crlf)
          if [[ -f "$target" ]]; then
            _fixa_backup "$target"
            sed -i.bak 's/$/\r/' "$target"
            _fixa_success "Converted to DOS line endings (CRLF)"
          elif [[ -d "$target" ]]; then
            find "$target" -type f -exec sed -i.bak 's/$/\r/' {} \;
            _fixa_success "Converted all files to DOS line endings (CRLF)"
          fi
          ;;
        mac|cr)
          _fixa_warning "Classic Mac (CR) line endings are rarely used"
          if [[ -f "$target" ]]; then
            _fixa_backup "$target"
            sed -i.bak 's/$/\r/' "$target"
            sed -i.bak 's/\n//g' "$target"
            _fixa_success "Converted to Mac line endings (CR)"
          fi
          ;;
        *)
          _fixa_error "Invalid format: $format"
          return 1
          ;;
      esac
      ;;
      
    whitespace|ws)
      if [[ -z "$1" ]]; then
        _fixa_error "Usage: fixa whitespace <file|directory>"
        return 1
      fi
      
      local target="$1"
      
      _fixa_info "Fixing whitespace issues in ${CYAN}${target}${NC}"
      _fixa_log "WHITESPACE: target='$target'"
      
      local process_file() {
        local file="$1"
        _fixa_backup "$file"
        
        # Remove trailing whitespace
        sed -i.bak 's/[[:space:]]*$//' "$file"
        
        # Ensure file ends with newline
        if [[ -n "$(tail -c 1 "$file")" ]]; then
          echo "" >> "$file"
        fi
        
        echo "${GREEN}✅${NC} $(basename "$file")"
      }
      
      if [[ -f "$target" ]]; then
        process_file "$target"
        _fixa_success "Fixed whitespace"
      elif [[ -d "$target" ]]; then
        local exclude_args=$(_fixa_build_exclude_args)
        eval "find '$target' -type f -size -${FIXA_MAX_FILE_SIZE} $exclude_args 2>/dev/null" | \
        while IFS= read -r file; do
          process_file "$file"
        done
        _fixa_success "Fixed whitespace in all files"
      else
        _fixa_error "Target not found: $target"
        return 1
      fi
      ;;
    
    ###################
    # SYSTEM FIXES
    ###################
    
    ownership|own)
      if [[ -z "$1" || -z "$2" ]]; then
        _fixa_error "Usage: fixa ownership <user[:group]> <target>"
        return 1
      fi
      
      local owner="$1"
      local target="$2"
      
      _fixa_info "Changing ownership to ${CYAN}${owner}${NC} on ${CYAN}${target}${NC}"
      _fixa_log "OWNERSHIP: owner='$owner' target='$target'"
      
      if [[ "$FIXA_CONFIRM_DESTRUCTIVE" == "true" ]]; then
        if ! _fixa_confirm "Change ownership recursively?"; then
          _fixa_info "Cancelled"
          return 0
        fi
      fi
      
      if sudo chown -R "$owner" "$target"; then
        _fixa_success "Ownership changed"
      else
        _fixa_error "Failed to change ownership"
        return 1
      fi
      ;;
      
    symlinks|links)
      local target_dir="${1:-.}"
      
      _fixa_info "Fixing broken symlinks in ${CYAN}${target_dir}${NC}"
      _fixa_log "SYMLINKS: dir='$target_dir'"
      
      local broken=()
      while IFS= read -r link; do
        if [[ ! -e "$link" ]]; then
          broken+=("$link")
        fi
      done < <(find "$target_dir" -type l 2>/dev/null)
      
      if [[ ${#broken[@]} -eq 0 ]]; then
        _fixa_success "No broken symlinks found"
        return 0
      fi
      
      echo "${BOLD}Found ${#broken[@]} broken symlink(s):${NC}"
      for link in "${broken[@]}"; do
        local target=$(readlink "$link")
        echo "  ${RED}$link${NC} → ${DIM}$target${NC}"
      done
      echo ""
      
      if _fixa_confirm "Remove broken symlinks?"; then
        for link in "${broken[@]}"; do
          rm "$link"
          echo "${GREEN}✅${NC} Removed: $link"
        done
        _fixa_success "Removed ${#broken[@]} broken symlink(s)"
      fi
      ;;
      
    duplicates|dupes)
      local target_dir="${1:-.}"
      local action="${2:-list}"
      
      _fixa_info "Finding duplicate files in ${CYAN}${target_dir}${NC}"
      _fixa_log "DUPLICATES: dir='$target_dir' action='$action'"
      
      if command -v fdupes &> /dev/null; then
        case "$action" in
          list)
            fdupes -r "$target_dir"
            ;;
          delete)
            if _fixa_confirm "Delete duplicate files interactively?"; then
              fdupes -r -d "$target_dir"
              _fixa_success "Duplicate cleanup completed"
            fi
            ;;
          *)
            _fixa_error "Invalid action: $action (use 'list' or 'delete')"
            return 1
            ;;
        esac
      else
        _fixa_warning "fdupes not installed. Using fallback method..."
        find "$target_dir" -type f -exec md5sum {} + 2>/dev/null | \
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
    
    ###################
    # UTILITIES
    ###################
    
    backup)
      if [[ -z "$1" ]]; then
        _fixa_error "Usage: fixa backup <file|directory>"
        return 1
      fi
      
      local target="$1"
      
      if [[ -f "$target" ]]; then
        local backup_path=$(_fixa_backup "$target")
        _fixa_success "Backup created: $backup_path"
      elif [[ -d "$target" ]]; then
        local backup_path=$(_fixa_backup_dir "$target")
        _fixa_success "Backup created: $backup_path"
      else
        _fixa_error "Target not found: $target"
        return 1
      fi
      ;;
      
    restore)
      _fixa_info "Available backups in ${CYAN}${FIXA_BACKUP_DIR}${NC}:"
      ls -lht "$FIXA_BACKUP_DIR" 2>/dev/null | tail -n +2 | head -20
      ;;
      
    dry-run)
      if [[ "$FIXA_DRY_RUN" == "true" ]]; then
        FIXA_DRY_RUN=false
        _fixa_info "Dry-run mode ${RED}disabled${NC}"
      else
        FIXA_DRY_RUN=true
        _fixa_info "Dry-run mode ${GREEN}enabled${NC} - no changes will be made"
      fi
      ;;
      
    log)
      local lines="${1:-50}"
      
      if [[ ! -f "$FIXA_LOG_FILE" ]]; then
        _fixa_info "No log file found"
        return 0
      fi
      
      echo "${BOLD}📜 Recent fixes (last $lines):${NC}"
      tail -n "$lines" "$FIXA_LOG_FILE" | nl -w2 -s'. '
      ;;
      
    clear-log)
      if [[ -f "$FIXA_LOG_FILE" ]]; then
        rm "$FIXA_LOG_FILE"
        touch "$FIXA_LOG_FILE"
        _fixa_success "Log cleared"
      fi
      ;;
    
    ###################
    # CONFIG
    ###################
    
    config)
      if [[ -z "$1" ]]; then
        echo "${BOLD}Current FIXA Configuration:${NC}"
        cat "$FIXA_CONFIG_FILE"
      else
        local subcommand="$1"
        shift
        case "$subcommand" in
          edit)
            ${EDITOR:-vim} "$FIXA_CONFIG_FILE"
            _fixa_init_config
            _fixa_success "Config reloaded"
            ;;
          reset)
            rm "$FIXA_CONFIG_FILE"
            _fixa_init_config
            _fixa_success "Config reset to defaults"
            ;;
          set)
            if [[ -z "$1" || -z "$2" ]]; then
              _fixa_error "Usage: fixa config set <key> <value>"
              return 1
            fi
            local key="$1"
            local value="$2"
            sed -i.bak "s/^${key}=.*/${key}=${value}/" "$FIXA_CONFIG_FILE"
            _fixa_init_config
            _fixa_success "Set ${key}=${value}"
            ;;
          *)
            _fixa_error "Unknown config command: $subcommand"
            ;;
        esac
      fi
      ;;
    
    ###################
    # HELP
    ###################
    
    help|--help|-h)
      cat << EOF
${BOLD}🔧 FIXA - Fast Fix Anything CLI${NC}

${BOLD}📝 CONTENT FIXING:${NC}
  fixa content [dir]                Interactive find & replace in directory
  fixa regex <pat> <rep> [dir]      Apply regex replacement
  fixa line-remove <pat> <file>     Remove lines matching pattern
  fixa line-add <line> <file> [pos] Add line (pos: start|end|before:X|after:X)
  fixa dedupe <file>                Remove duplicate lines

${BOLD}📁 FILE OPERATIONS:${NC}
  fixa rename <pat> <rep> [dir]     Rename files (pattern replacement)
  fixa extension <old> <new> [dir]  Change file extensions
  fixa lowercase [dir]              Convert filenames to lowercase
  fixa spaces [dir] [char]          Replace spaces in filenames (default: _)

${BOLD}🔐 PERMISSIONS:${NC}
  fixa perms <mode> [target]        Set permissions (e.g., 755, 644)
  fixa fix-perms [dir]              Fix standard perms (dirs=755, files=644)
  fixa executable <file>            Make file executable
  fixa ownership <user> <target>    Change ownership (requires sudo)

${BOLD}📄 ENCODING & FORMAT:${NC}
  fixa encoding <from> <to> <file>  Convert file encoding
  fixa lineendings <type> <target>  Fix line endings (unix|dos|mac)
  fixa whitespace <target>          Remove trailing whitespace, fix newlines

${BOLD}🔗 SYSTEM FIXES:${NC}
  fixa symlinks [dir]               Find and remove broken symlinks
  fixa duplicates [dir] [action]    Find/delete duplicate files (list|delete)

${BOLD}💾 UTILITIES:${NC}
  fixa backup <target>              Create backup manually
  fixa restore                      List available backups
  fixa dry-run                      Toggle dry-run mode
  fixa log [n]                      Show last N fixes (default: 50)
  fixa clear-log                    Clear fix log

${BOLD}⚙️  CONFIG:${NC}
  fixa config                       Show configuration
  fixa config edit                  Edit config file
  fixa config set <key> <value>     Set config value
  fixa config reset                 Reset to defaults

${BOLD}❓ HELP:${NC}
  fixa help                         Show this help

${BOLD}Configuration Options:${NC}
  FIXA_AUTO_BACKUP         Auto-backup before changes (default: true)
  FIXA_BACKUP_DIR          Backup directory location
  FIXA_CONFIRM_DESTRUCTIVE Ask before destructive operations (default: true)
  FIXA_SHOW_DIFF           Show diffs in content fixes (default: true)
  FIXA_LOG_FIXES           Log all fixes (default: true)
  FIXA_MAX_FILE_SIZE       Max file size to process (default: 10M)
  FIXA_DRY_RUN             Dry-run mode (default: false)

${BOLD}Examples:${NC}
  fixa content src/                 # Interactive find & replace
  fixa rename "old" "new" .         # Rename files
  fixa extension txt md docs/       # Change .txt to .md
  fixa fix-perms .                  # Fix all permissions
  fixa lineendings unix *.sh        # Convert to Unix line endings
  fixa spaces ~/Downloads           # Remove spaces from filenames
  fixa duplicates ~/Pictures list   # Find duplicate images
  fixa symlinks /opt                # Remove broken symlinks

${YELLOW}⚠️  Always use with caution! Backups are created automatically.${NC}
${BLUE}ℹ️  Config: ${FIXA_CONFIG_FILE}${NC}
${BLUE}ℹ️  Backups: ${FIXA_BACKUP_DIR}${NC}
${BLUE}ℹ️  Logs: ${FIXA_LOG_FILE}${NC}
EOF
      ;;
      
    version|--version|-v)
      echo "${BOLD}FIXA${NC} version 1.0.0"
      echo "Dependencies:"
      command -v fdupes &> /dev/null && echo "  ✅ fdupes (duplicate detection)" || echo "  ❌ fdupes (optional)"
      command -v iconv &> /dev/null && echo "  ✅ iconv (encoding conversion)" || echo "  ❌ iconv (optional)"
      ;;
      
    *)
      if [[ -z "$cmd" ]]; then
        fixa help
      else
        _fixa_error "Unknown command: $cmd"
        echo "Run ${CYAN}fixa help${NC} for usage"
        return 1
      fi
      ;;
  esac
}

# Zsh completion
if [[ -n "$ZSH_VERSION" ]]; then
  _fixa_completion() {
    local -a commands
    commands=(
      'content:Interactive find and replace'
      'regex:Apply regex replacement'
      'line-remove:Remove lines matching pattern'
      'line-add:Add line to file'
      'dedupe:Remove duplicate lines'
      'rename:Rename files'
      'extension:Change file extensions'
      'lowercase:Convert filenames to lowercase'
      'spaces:Replace spaces in filenames'
      'perms:Set permissions'
      'fix-perms:Fix standard permissions'
      'executable:Make file executable'
      'ownership:Change ownership'
      'encoding:Convert file encoding'
      'lineendings:Fix line endings'
      'whitespace:Fix whitespace issues'
      'symlinks:Fix broken symlinks'
      'duplicates:Find/delete duplicates'
      'backup:Create backup'
      'restore:List backups'
      'dry-run:Toggle dry-run mode'
      'log:Show fix log'
      'clear-log:Clear log'
      'config:Configuration'
      'help:Show help'
      'version:Show version'
    )
    _describe 'fixa commands' commands
  }
  
  compdef _fixa_completion fixa
fi
