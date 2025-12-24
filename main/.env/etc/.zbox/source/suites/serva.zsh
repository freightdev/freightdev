#!/bin/zsh
###################
# SERVA - Server Management CLI
# A comprehensive suite for managing multiple servers
###################

# Configuration directory
SERVA_CONFIG_DIR="${HOME}/.config/serva"
SERVA_CONFIG_FILE="${SERVA_CONFIG_DIR}/config"
SERVA_SERVERS_FILE="${SERVA_CONFIG_DIR}/servers.conf"
SERVA_GROUPS_FILE="${SERVA_CONFIG_DIR}/groups.conf"
SERVA_LOG_FILE="${SERVA_CONFIG_DIR}/serva.log"

# Initialize config
_serva_init_config() {
  if [[ ! -d "$SERVA_CONFIG_DIR" ]]; then
    mkdir -p "$SERVA_CONFIG_DIR"
  fi
  
  if [[ ! -f "$SERVA_CONFIG_FILE" ]]; then
    cat > "$SERVA_CONFIG_FILE" << 'EOF'
# SERVA Configuration
SERVA_DEFAULT_USER=${USER}
SERVA_DEFAULT_PORT=22
SERVA_SSH_KEY="${HOME}/.ssh/id_rsa"
SERVA_RSYNC_OPTIONS="-avz --progress"
SERVA_PARALLEL_JOBS=5
SERVA_TIMEOUT=30
SERVA_LOG_COMMANDS=true
SERVA_CONFIRM_MULTI=true
SERVA_EXCLUDE_PATTERNS=".git,node_modules,.DS_Store,*.log"
SERVA_COMPRESS=true
EOF
  fi
  source "$SERVA_CONFIG_FILE"
  
  # Initialize servers file
  if [[ ! -f "$SERVA_SERVERS_FILE" ]]; then
    cat > "$SERVA_SERVERS_FILE" << 'EOF'
# Server definitions
# Format: alias|user@host|port|description
# Example: prod|deploy@prod.example.com|22|Production server
# Example: staging|deploy@staging.example.com|22|Staging server
EOF
  fi
  
  # Initialize groups file
  if [[ ! -f "$SERVA_GROUPS_FILE" ]]; then
    cat > "$SERVA_GROUPS_FILE" << 'EOF'
# Server groups
# Format: group_name=server1,server2,server3
# Example: production=prod1,prod2,prod3
# Example: development=dev1,dev2
EOF
  fi
  
  # Initialize log file
  [[ ! -f "$SERVA_LOG_FILE" ]] && touch "$SERVA_LOG_FILE"
}

_serva_init_config

# Color codes
_serva_colors() {
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

_serva_colors

# Utility functions
_serva_error() {
  echo "${RED}❌ Error:${NC} $1" >&2
  _serva_log "ERROR: $1"
}

_serva_warning() {
  echo "${YELLOW}⚠️  Warning:${NC} $1"
  _serva_log "WARNING: $1"
}

_serva_success() {
  echo "${GREEN}✅${NC} $1"
  _serva_log "SUCCESS: $1"
}

_serva_info() {
  echo "${BLUE}ℹ️${NC}  $1"
}

_serva_log() {
  if [[ "$SERVA_LOG_COMMANDS" == "true" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$SERVA_LOG_FILE"
  fi
}

_serva_confirm() {
  local prompt="$1"
  local response
  echo -n "${YELLOW}${prompt}${NC} (y/n): "
  read response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Server management functions
_serva_get_server_info() {
  local alias="$1"
  
  while IFS='|' read -r srv_alias srv_connection srv_port srv_desc; do
    # Skip comments and empty lines
    [[ "$srv_alias" =~ ^#.*$ || -z "$srv_alias" ]] && continue
    
    if [[ "$srv_alias" == "$alias" ]]; then
      echo "$srv_connection|$srv_port|$srv_desc"
      return 0
    fi
  done < "$SERVA_SERVERS_FILE"
  
  return 1
}

_serva_list_servers() {
  local show_details="${1:-false}"
  
  echo "${BOLD}📋 Configured Servers:${NC}"
  echo ""
  
  while IFS='|' read -r srv_alias srv_connection srv_port srv_desc; do
    [[ "$srv_alias" =~ ^#.*$ || -z "$srv_alias" ]] && continue
    
    if [[ "$show_details" == "true" ]]; then
      echo "${CYAN}${srv_alias}${NC}"
      echo "  Connection: ${srv_connection}"
      echo "  Port: ${srv_port}"
      echo "  Description: ${srv_desc}"
      echo ""
    else
      printf "  ${CYAN}%-15s${NC} ${DIM}%-30s${NC} %s\n" "$srv_alias" "$srv_connection" "$srv_desc"
    fi
  done < "$SERVA_SERVERS_FILE"
}

_serva_list_groups() {
  echo "${BOLD}👥 Server Groups:${NC}"
  echo ""
  
  while IFS='=' read -r group_name servers; do
    [[ "$group_name" =~ ^#.*$ || -z "$group_name" ]] && continue
    
    echo "${MAGENTA}${group_name}${NC}: ${servers}"
  done < "$SERVA_GROUPS_FILE"
}

_serva_resolve_targets() {
  local target="$1"
  local servers=()
  
  # Check if it's a group
  local group_servers=$(grep "^${target}=" "$SERVA_GROUPS_FILE" 2>/dev/null | cut -d'=' -f2)
  
  if [[ -n "$group_servers" ]]; then
    IFS=',' read -rA servers <<< "$group_servers"
  else
    # It's a single server
    servers=("$target")
  fi
  
  echo "${servers[@]}"
}

_serva_build_rsync_excludes() {
  local exclude_args=""
  IFS=',' read -rA patterns <<< "$SERVA_EXCLUDE_PATTERNS"
  for pattern in "${patterns[@]}"; do
    exclude_args+=" --exclude='${pattern}'"
  done
  echo "$exclude_args"
}

# Main function
serva() {
  local cmd=$1
  shift
  
  case "$cmd" in
    
    ###################
    # FILE TRANSFER
    ###################
    
    push)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva push <target> <source> <destination>"
        echo "Target can be server alias or group name"
        return 1
      fi
      
      local target="$1"
      local source="$2"
      local dest="$3"
      
      if [[ ! -e "$source" ]]; then
        _serva_error "Source not found: $source"
        return 1
      fi
      
      local servers=($(_serva_resolve_targets "$target"))
      local exclude_args=$(_serva_build_rsync_excludes)
      
      _serva_info "Pushing ${CYAN}${source}${NC} to ${CYAN}${#servers[@]}${NC} server(s)"
      _serva_log "PUSH: target='$target' source='$source' dest='$dest'"
      
      if [[ ${#servers[@]} -gt 1 && "$SERVA_CONFIRM_MULTI" == "true" ]]; then
        echo "${BOLD}Servers:${NC} ${servers[*]}"
        if ! _serva_confirm "Push to all these servers?"; then
          _serva_info "Cancelled"
          return 0
        fi
      fi
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ Pushing to ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}...${NC}"
        
        local rsync_cmd="rsync $SERVA_RSYNC_OPTIONS -e 'ssh -p $port -i $SERVA_SSH_KEY -o ConnectTimeout=$SERVA_TIMEOUT' $exclude_args '$source' '$connection:$dest'"
        
        if eval "$rsync_cmd"; then
          _serva_success "Pushed to $server"
          ((success++))
        else
          _serva_error "Failed to push to $server"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
      
    pull)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva pull <server> <source> <destination>"
        echo "Note: Pull only works with a single server"
        return 1
      fi
      
      local server="$1"
      local source="$2"
      local dest="$3"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      _serva_info "Pulling from ${CYAN}${server}${NC} ${DIM}(${connection})${NC}"
      _serva_log "PULL: server='$server' source='$source' dest='$dest'"
      
      local exclude_args=$(_serva_build_rsync_excludes)
      local rsync_cmd="rsync $SERVA_RSYNC_OPTIONS -e 'ssh -p $port -i $SERVA_SSH_KEY -o ConnectTimeout=$SERVA_TIMEOUT' $exclude_args '$connection:$source' '$dest'"
      
      if eval "$rsync_cmd"; then
        _serva_success "Pulled from $server"
      else
        _serva_error "Failed to pull from $server"
        return 1
      fi
      ;;
      
    sync)
      if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        _serva_error "Usage: serva sync <target> <source> <destination>"
        echo "Syncs directory, deleting files on remote that don't exist locally"
        return 1
      fi
      
      local target="$1"
      local source="$2"
      local dest="$3"
      
      if [[ ! -d "$source" ]]; then
        _serva_error "Source directory not found: $source"
        return 1
      fi
      
      _serva_warning "This will DELETE files on remote that don't exist locally!"
      if ! _serva_confirm "Continue with sync?"; then
        _serva_info "Cancelled"
        return 0
      fi
      
      local servers=($(_serva_resolve_targets "$target"))
      local exclude_args=$(_serva_build_rsync_excludes)
      
      _serva_log "SYNC: target='$target' source='$source' dest='$dest'"
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ Syncing to ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}...${NC}"
        
        local rsync_cmd="rsync $SERVA_RSYNC_OPTIONS --delete -e 'ssh -p $port -i $SERVA_SSH_KEY -o ConnectTimeout=$SERVA_TIMEOUT' $exclude_args '$source/' '$connection:$dest/'"
        
        if eval "$rsync_cmd"; then
          _serva_success "Synced to $server"
          ((success++))
        else
          _serva_error "Failed to sync to $server"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
    
    ###################
    # COMMAND EXECUTION
    ###################
    
    exec|run)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva exec <target> <command>"
        return 1
      fi
      
      local target="$1"
      shift
      local command="$*"
      
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_info "Executing on ${CYAN}${#servers[@]}${NC} server(s): ${YELLOW}${command}${NC}"
      _serva_log "EXEC: target='$target' command='$command'"
      
      if [[ ${#servers[@]} -gt 1 && "$SERVA_CONFIRM_MULTI" == "true" ]]; then
        echo "${BOLD}Servers:${NC} ${servers[*]}"
        if ! _serva_confirm "Execute on all these servers?"; then
          _serva_info "Cancelled"
          return 0
        fi
      fi
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}:${NC}"
        echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout="$SERVA_TIMEOUT" "$connection" "$command"; then
          echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          _serva_success "$server completed"
          ((success++))
        else
          echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          _serva_error "$server failed"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
      
    script)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva script <target> <script-file>"
        return 1
      fi
      
      local target="$1"
      local script_file="$2"
      
      if [[ ! -f "$script_file" ]]; then
        _serva_error "Script file not found: $script_file"
        return 1
      fi
      
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_info "Running script ${CYAN}${script_file}${NC} on ${CYAN}${#servers[@]}${NC} server(s)"
      _serva_log "SCRIPT: target='$target' script='$script_file'"
      
      if [[ ${#servers[@]} -gt 1 && "$SERVA_CONFIRM_MULTI" == "true" ]]; then
        if ! _serva_confirm "Run script on all servers?"; then
          _serva_info "Cancelled"
          return 0
        fi
      fi
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ Running on ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}...${NC}"
        
        if ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout="$SERVA_TIMEOUT" "$connection" 'bash -s' < "$script_file"; then
          _serva_success "$server completed"
          ((success++))
        else
          _serva_error "$server failed"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
    
    ###################
    # SSH CONNECTION
    ###################
    
    ssh|connect)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva ssh <server>"
        return 1
      fi
      
      local server="$1"
      shift
      local extra_args="$*"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      _serva_info "Connecting to ${CYAN}${server}${NC} ${DIM}(${connection})${NC}"
      _serva_log "SSH: server='$server'"
      
      ssh -p "$port" -i "$SERVA_SSH_KEY" $extra_args "$connection"
      ;;
      
    tunnel)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva tunnel <server> <local-port:remote-host:remote-port>"
        echo "Example: serva tunnel prod 8080:localhost:80"
        return 1
      fi
      
      local server="$1"
      local tunnel_spec="$2"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      _serva_info "Creating tunnel via ${CYAN}${server}${NC}: ${YELLOW}${tunnel_spec}${NC}"
      _serva_log "TUNNEL: server='$server' spec='$tunnel_spec'"
      
      ssh -p "$port" -i "$SERVA_SSH_KEY" -L "$tunnel_spec" -N "$connection"
      ;;
      
    socks)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva socks <server> [local-port]"
        echo "Creates a SOCKS5 proxy"
        return 1
      fi
      
      local server="$1"
      local local_port="${2:-1080}"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      _serva_info "Creating SOCKS5 proxy via ${CYAN}${server}${NC} on port ${YELLOW}${local_port}${NC}"
      _serva_log "SOCKS: server='$server' port='$local_port'"
      
      ssh -p "$port" -i "$SERVA_SSH_KEY" -D "$local_port" -N "$connection"
      ;;
    
    ###################
    # SERVER INFO
    ###################
    
    status|stat)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva status <target>"
        return 1
      fi
      
      local target="$1"
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_info "Checking status of ${CYAN}${#servers[@]}${NC} server(s)"
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          echo "${RED}✗${NC} ${server}: Not configured"
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        if ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes "$connection" "exit" 2>/dev/null; then
          echo "${GREEN}✓${NC} ${CYAN}${server}${NC} ${DIM}(${connection})${NC}: ${GREEN}Online${NC}"
          
          # Get system info
          local uptime=$(ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=5 "$connection" "uptime -p" 2>/dev/null | sed 's/up //')
          local load=$(ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=5 "$connection" "uptime" 2>/dev/null | awk -F'load average:' '{print $2}' | xargs)
          
          [[ -n "$uptime" ]] && echo "    Uptime: $uptime"
          [[ -n "$load" ]] && echo "    Load: $load"
        else
          echo "${RED}✗${NC} ${CYAN}${server}${NC} ${DIM}(${connection})${NC}: ${RED}Offline${NC}"
        fi
      done
      ;;
      
    info)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva info <target>"
        return 1
      fi
      
      local target="$1"
      local servers=($(_serva_resolve_targets "$target"))
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}${CYAN}${server}${NC}"
        echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "Description: $desc"
        echo "Connection:  $connection"
        echo "Port:        $port"
        
        if ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=5 -o BatchMode=yes "$connection" "exit" 2>/dev/null; then
          echo ""
          echo "${BOLD}System Information:${NC}"
          ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=10 "$connection" "
            echo 'OS:        ' \$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'\"' -f2 || uname -s)
            echo 'Kernel:    ' \$(uname -r)
            echo 'CPU:       ' \$(nproc) cores
            echo 'Memory:    ' \$(free -h | awk '/^Mem:/ {print \$2}')
            echo 'Disk:      ' \$(df -h / | awk 'NR==2 {print \$2 \" total, \" \$4 \" free\"}')
            echo 'Uptime:    ' \$(uptime -p | sed 's/up //')
          " 2>/dev/null
        else
          echo ""
          echo "${RED}Cannot connect to server${NC}"
        fi
        
        echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      done
      ;;
    
    ###################
    # SERVER MANAGEMENT
    ###################
    
    list|ls)
      local show_details="${1:-false}"
      [[ "$1" == "-l" || "$1" == "--long" ]] && show_details="true"
      
      _serva_list_servers "$show_details"
      echo ""
      _serva_list_groups
      ;;
      
    add)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva add <alias> <user@host> [port] [description]"
        return 1
      fi
      
      local alias="$1"
      local connection="$2"
      local port="${3:-22}"
      local description="${4:-No description}"
      
      # Check if alias already exists
      if _serva_get_server_info "$alias" >/dev/null 2>&1; then
        _serva_error "Server alias already exists: $alias"
        return 1
      fi
      
      echo "$alias|$connection|$port|$description" >> "$SERVA_SERVERS_FILE"
      _serva_success "Added server: $alias"
      _serva_log "ADD: alias='$alias' connection='$connection'"
      ;;
      
    remove|rm)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva remove <alias>"
        return 1
      fi
      
      local alias="$1"
      
      if ! _serva_get_server_info "$alias" >/dev/null 2>&1; then
        _serva_error "Server not found: $alias"
        return 1
      fi
      
      if _serva_confirm "Remove server '$alias'?"; then
        sed -i.bak "/^${alias}|/d" "$SERVA_SERVERS_FILE"
        _serva_success "Removed server: $alias"
        _serva_log "REMOVE: alias='$alias'"
      fi
      ;;
      
    group)
      if [[ -z "$1" ]]; then
        _serva_list_groups
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        add)
          if [[ -z "$1" || -z "$2" ]]; then
            _serva_error "Usage: serva group add <group-name> <server1,server2,...>"
            return 1
          fi
          
          local group_name="$1"
          local servers="$2"
          
          echo "$group_name=$servers" >> "$SERVA_GROUPS_FILE"
          _serva_success "Added group: $group_name"
          ;;
        remove)
          if [[ -z "$1" ]]; then
            _serva_error "Usage: serva group remove <group-name>"
            return 1
          fi
          
          local group_name="$1"
          
          if _serva_confirm "Remove group '$group_name'?"; then
            sed -i.bak "/^${group_name}=/d" "$SERVA_GROUPS_FILE"
            _serva_success "Removed group: $group_name"
          fi
          ;;
        *)
          _serva_error "Unknown group command: $subcommand"
          echo "Usage: serva group {add|remove} ..."
          return 1
          ;;
      esac
      ;;
    
    ###################
    # DEPLOYMENT
    ###################
    
    deploy)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva deploy <target> <source> [destination]"
        echo "Deploys code with automatic git pull on remote"
        return 1
      fi
      
      local target="$1"
      local source="$2"
      local dest="${3:-/var/www/app}"
      
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_info "Deploying ${CYAN}${source}${NC} to ${CYAN}${#servers[@]}${NC} server(s)"
      _serva_log "DEPLOY: target='$target' source='$source' dest='$dest'"
      
      if [[ ${#servers[@]} -gt 1 && "$SERVA_CONFIRM_MULTI" == "true" ]]; then
        if ! _serva_confirm "Deploy to all servers?"; then
          _serva_info "Cancelled"
          return 0
        fi
      fi
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ Deploying to ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}...${NC}"
        
        # Create backup on remote
        ssh -p "$port" -i "$SERVA_SSH_KEY" "$connection" "
          if [ -d '$dest' ]; then
            echo '📦 Creating backup...'
            cp -r '$dest' '${dest}.backup-\$(date +%Y%m%d_%H%M%S)'
          fi
        " 2>/dev/null
        
        # Sync files
        local exclude_args=$(_serva_build_rsync_excludes)
        if eval "rsync $SERVA_RSYNC_OPTIONS --delete -e 'ssh -p $port -i $SERVA_SSH_KEY' $exclude_args '$source/' '$connection:$dest/'"; then
          
          # Run post-deployment commands
          ssh -p "$port" -i "$SERVA_SSH_KEY" "$connection" "
            cd '$dest'
            echo '🔄 Running post-deployment tasks...'
            
            # Git pull if it's a git repo
            if [ -d '.git' ]; then
              echo '📥 Pulling latest changes...'
              git pull 2>/dev/null || echo 'Not a git repository or pull failed'
            fi
            
            # Install dependencies if package files exist
            if [ -f 'package.json' ]; then
              echo '📦 Installing npm dependencies...'
              npm install --production 2>/dev/null || echo 'npm install failed or not available'
            fi
            
            if [ -f 'composer.json' ]; then
              echo '📦 Installing composer dependencies...'
              composer install --no-dev --optimize-autoloader 2>/dev/null || echo 'composer install failed or not available'
            fi
            
            if [ -f 'requirements.txt' ]; then
              echo '📦 Installing pip dependencies...'
              pip install -r requirements.txt 2>/dev/null || echo 'pip install failed or not available'
            fi
            
            # Set permissions
            echo '🔐 Setting permissions...'
            find . -type f -exec chmod 644 {} \; 2>/dev/null
            find . -type d -exec chmod 755 {} \; 2>/dev/null
            
            echo '✅ Post-deployment tasks complete'
          " 2>/dev/null
          
          _serva_success "Deployed to $server"
          ((success++))
        else
          _serva_error "Failed to deploy to $server"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
      
    rollback)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva rollback <target> [destination]"
        echo "Rolls back to the most recent backup"
        return 1
      fi
      
      local target="$1"
      local dest="${2:-/var/www/app}"
      
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_warning "This will restore the most recent backup"
      if ! _serva_confirm "Rollback on ${#servers[@]} server(s)?"; then
        _serva_info "Cancelled"
        return 0
      fi
      
      _serva_log "ROLLBACK: target='$target' dest='$dest'"
      
      local success=0
      local failed=0
      
      for server in "${servers[@]}"; do
        local info=$(_serva_get_server_info "$server")
        if [[ -z "$info" ]]; then
          _serva_error "Server not found: $server"
          ((failed++))
          continue
        fi
        
        IFS='|' read -r connection port desc <<< "$info"
        
        echo ""
        echo "${BOLD}➤ Rolling back ${CYAN}${server}${NC} ${DIM}(${connection})${NC}${BOLD}...${NC}"
        
        if ssh -p "$port" -i "$SERVA_SSH_KEY" "$connection" "
          # Find most recent backup
          BACKUP=\$(ls -t ${dest}.backup-* 2>/dev/null | head -1)
          
          if [ -z \"\$BACKUP\" ]; then
            echo 'No backup found'
            exit 1
          fi
          
          echo \"Found backup: \$BACKUP\"
          
          # Remove current deployment
          rm -rf '$dest'
          
          # Restore backup
          mv \"\$BACKUP\" '$dest'
          
          echo 'Rollback complete'
        "; then
          _serva_success "Rolled back $server"
          ((success++))
        else
          _serva_error "Failed to rollback $server"
          ((failed++))
        fi
      done
      
      echo ""
      echo "${BOLD}Summary:${NC} ${GREEN}${success} succeeded${NC}, ${RED}${failed} failed${NC}"
      ;;
    
    ###################
    # MONITORING
    ###################
    
    monitor)
      if [[ -z "$1" ]]; then
        _serva_error "Usage: serva monitor <target> [interval]"
        echo "Continuously monitors server status"
        return 1
      fi
      
      local target="$1"
      local interval="${2:-5}"
      
      local servers=($(_serva_resolve_targets "$target"))
      
      _serva_info "Monitoring ${CYAN}${#servers[@]}${NC} server(s) every ${YELLOW}${interval}${NC} seconds"
      echo "Press Ctrl+C to stop"
      echo ""
      
      while true; do
        clear
        echo "${BOLD}SERVA Monitor - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        for server in "${servers[@]}"; do
          local info=$(_serva_get_server_info "$server")
          if [[ -z "$info" ]]; then
            echo "${RED}✗${NC} ${server}: Not configured"
            continue
          fi
          
          IFS='|' read -r connection port desc <<< "$info"
          
          if ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=3 -o BatchMode=yes "$connection" "exit" 2>/dev/null; then
            local stats=$(ssh -p "$port" -i "$SERVA_SSH_KEY" -o ConnectTimeout=3 "$connection" "
              uptime | awk -F'load average:' '{print \$2}' | xargs
            " 2>/dev/null)
            
            echo "${GREEN}●${NC} ${CYAN}${server}${NC} ${DIM}(${connection})${NC}"
            echo "   Load: ${stats}"
          else
            echo "${RED}●${NC} ${CYAN}${server}${NC} ${DIM}(${connection})${NC} - ${RED}OFFLINE${NC}"
          fi
          echo ""
        done
        
        echo "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        sleep "$interval"
      done
      ;;
      
    logs)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva logs <server> <log-file> [lines]"
        echo "Tails logs from a remote server"
        return 1
      fi
      
      local server="$1"
      local log_file="$2"
      local lines="${3:-50}"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      _serva_info "Tailing ${CYAN}${log_file}${NC} on ${CYAN}${server}${NC}"
      _serva_log "LOGS: server='$server' file='$log_file'"
      
      ssh -p "$port" -i "$SERVA_SSH_KEY" "$connection" "tail -n $lines -f '$log_file'"
      ;;
    
    ###################
    # BACKUP
    ###################
    
    backup)
      if [[ -z "$1" || -z "$2" ]]; then
        _serva_error "Usage: serva backup <server> <remote-path> [local-destination]"
        echo "Creates a compressed backup of remote directory"
        return 1
      fi
      
      local server="$1"
      local remote_path="$2"
      local local_dest="${3:-./backups}"
      
      local info=$(_serva_get_server_info "$server")
      if [[ -z "$info" ]]; then
        _serva_error "Server not found: $server"
        return 1
      fi
      
      IFS='|' read -r connection port desc <<< "$info"
      
      mkdir -p "$local_dest"
      
      local backup_name="${server}-$(basename $remote_path)-$(date +%Y%m%d_%H%M%S).tar.gz"
      local backup_path="${local_dest}/${backup_name}"
      
      _serva_info "Creating backup of ${CYAN}${remote_path}${NC} from ${CYAN}${server}${NC}"
      _serva_log "BACKUP: server='$server' path='$remote_path' dest='$backup_path'"
      
      if ssh -p "$port" -i "$SERVA_SSH_KEY" "$connection" "tar czf - -C '$(dirname $remote_path)' '$(basename $remote_path)'" > "$backup_path"; then
        local size=$(du -h "$backup_path" | cut -f1)
        _serva_success "Backup created: ${backup_path} (${size})"
      else
        _serva_error "Backup failed"
        rm -f "$backup_path"
        return 1
      fi
      ;;
    
    ###################
    # CONFIGURATION
    ###################
    
    config)
      if [[ -z "$1" ]]; then
        echo "${BOLD}SERVA Configuration:${NC}"
        echo ""
        cat "$SERVA_CONFIG_FILE" | grep -v '^#' | grep '='
        echo ""
        echo "Edit config: serva config edit"
        return 0
      fi
      
      case "$1" in
        edit)
          ${EDITOR:-nano} "$SERVA_CONFIG_FILE"
          source "$SERVA_CONFIG_FILE"
          _serva_success "Configuration reloaded"
          ;;
        show)
          cat "$SERVA_CONFIG_FILE"
          ;;
        reset)
          if _serva_confirm "Reset configuration to defaults?"; then
            rm -f "$SERVA_CONFIG_FILE"
            _serva_init_config
            _serva_success "Configuration reset"
          fi
          ;;
        *)
          _serva_error "Unknown config command: $1"
          echo "Usage: serva config {edit|show|reset}"
          return 1
          ;;
      esac
      ;;
      
    log)
      if [[ "$1" == "clear" ]]; then
        if _serva_confirm "Clear log file?"; then
          > "$SERVA_LOG_FILE"
          _serva_success "Log cleared"
        fi
      else
        local lines="${1:-50}"
        tail -n "$lines" "$SERVA_LOG_FILE"
      fi
      ;;
    
    ###################
    # HELP
    ###################
    
    help|--help|-h)
      cat << 'EOF'
SERVA - Server Management CLI

FILE TRANSFER:
  serva push <target> <source> <dest>      Push files to server(s)
  serva pull <server> <source> <dest>      Pull files from server
  serva sync <target> <source> <dest>      Sync directory (with delete)

COMMAND EXECUTION:
  serva exec <target> <command>            Execute command on server(s)
  serva script <target> <file>             Run script on server(s)

SSH & TUNNELING:
  serva ssh <server>                       Connect to server
  serva tunnel <server> <port-spec>        Create SSH tunnel
  serva socks <server> [port]              Create SOCKS5 proxy

SERVER INFO:
  serva status <target>                    Check server(s) status
  serva info <target>                      Show detailed server info
  serva list [-l]                          List servers and groups
  serva monitor <target> [interval]        Monitor server(s) continuously
  serva logs <server> <file> [lines]       Tail remote log file

SERVER MANAGEMENT:
  serva add <alias> <user@host> [port]     Add new server
  serva remove <alias>                     Remove server
  serva group add <name> <servers>         Create server group
  serva group remove <name>                Remove server group

DEPLOYMENT:
  serva deploy <target> <source> [dest]    Deploy application
  serva rollback <target> [dest]           Rollback to last backup
  serva backup <server> <path> [dest]      Create backup

CONFIGURATION:
  serva config [edit|show|reset]           Manage configuration
  serva log [clear|lines]                  View/clear logs
  serva help                               Show this help

EXAMPLES:
  serva add prod deploy@prod.example.com 22 "Production server"
  serva push prod ./dist /var/www/app
  serva exec prod "systemctl restart nginx"
  serva deploy prod ./app /var/www/app
  serva status prod
  serva tunnel prod 8080:localhost:80

TARGETS:
  Targets can be either server aliases or group names

CONFIG:
  Config directory: ~/.config/serva/
  
For more information, visit: https://github.com/yourrepo/serva
EOF
      ;;
      
    version|--version|-v)
      echo "SERVA v1.0.0"
      ;;
    
    *)
      _serva_error "Unknown command: $cmd"
      echo "Run 'serva help' for usage information"
      return 1
      ;;
  esac
}

# Completion function for zsh
_serva_completion() {
  local -a commands servers groups
  
  commands=(
    'push:Push files to server(s)'
    'pull:Pull files from server'
    'sync:Sync directory with delete'
    'exec:Execute command on server(s)'
    'run:Execute command on server(s)'
    'script:Run script on server(s)'
    'ssh:Connect to server'
    'connect:Connect to server'
    'tunnel:Create SSH tunnel'
    'socks:Create SOCKS5 proxy'
    'status:Check server status'
    'stat:Check server status'
    'info:Show server info'
    'list:List servers and groups'
    'ls:List servers and groups'
    'add:Add new server'
    'remove:Remove server'
    'rm:Remove server'
    'group:Manage server groups'
    'deploy:Deploy application'
    'rollback:Rollback deployment'
    'monitor:Monitor servers'
    'logs:Tail remote logs'
    'backup:Create backup'
    'config:Manage configuration'
    'log:View logs'
    'help:Show help'
    'version:Show version'
  )
  
  # Read server aliases
  if [[ -f "$SERVA_SERVERS_FILE" ]]; then
    while IFS='|' read -r alias rest; do
      [[ "$alias" =~ ^#.*$ || -z "$alias" ]] && continue
      servers+=("$alias")
    done < "$SERVA_SERVERS_FILE"
  fi
  
  # Read groups
  if [[ -f "$SERVA_GROUPS_FILE" ]]; then
    while IFS='=' read -r group rest; do
      [[ "$group" =~ ^#.*$ || -z "$group" ]] && continue
      groups+=("$group")
    done < "$SERVA_GROUPS_FILE"
  fi
  
  case $CURRENT in
    2)
      _describe 'command' commands
      ;;
    3)
      case "${words[2]}" in
        push|sync|exec|run|script|status|stat|info|deploy|rollback|monitor)
          _describe 'server or group' servers
          _describe 'server or group' groups
          ;;
        pull|ssh|connect|tunnel|socks|logs|backup|remove|rm)
          _describe 'server' servers
          ;;
        group)
          _values 'group command' 'add' 'remove'
          ;;
        config)
          _values 'config command' 'edit' 'show' 'reset'
          ;;
      esac
      ;;
    *)
      _files
      ;;
  esac
}

# Register completion
if [[ -n "$ZSH_VERSION" ]]; then
  compdef _serva_completion serva
fi

