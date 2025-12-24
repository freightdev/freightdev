#!/bin/zsh

###################
# GITA - Git Assistant CLI
# A comprehensive Git wrapper with safety features
###################

# Configuration directory
GITA_CONFIG_DIR="${HOME}/.config/gita"
GITA_CONFIG_FILE="${GITA_CONFIG_DIR}/config"

# Initialize config
_gita_init_config() {
  if [[ ! -d "$GITA_CONFIG_DIR" ]]; then
    mkdir -p "$GITA_CONFIG_DIR"
  fi
  
  if [[ ! -f "$GITA_CONFIG_FILE" ]]; then
    cat > "$GITA_CONFIG_FILE" << 'EOF'
# GITA Configuration
GITA_DEFAULT_BRANCH=main
GITA_AUTO_FETCH=true
GITA_CONFIRM_FORCE=true
GITA_CONFIRM_DESTRUCTIVE=true
GITA_SHOW_WARNINGS=true
GITA_DEFAULT_EDITOR=vim
GITA_LOG_FORMAT=oneline
EOF
  fi
  source "$GITA_CONFIG_FILE"
}

# Load configuration
_gita_init_config

# Color codes
_gita_colors() {
  if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
  else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' NC=''
  fi
}
_gita_colors

# Utility functions
_gita_error() {
  echo "${RED}❌ Error:${NC} $1" >&2
}

_gita_warning() {
  [[ "$GITA_SHOW_WARNINGS" == "true" ]] && echo "${YELLOW}⚠️  Warning:${NC} $1"
}

_gita_success() {
  echo "${GREEN}✅${NC} $1"
}

_gita_info() {
  echo "${BLUE}ℹ️${NC}  $1"
}

_gita_confirm() {
  local prompt="$1"
  local response
  echo -n "${YELLOW}${prompt}${NC} (yes/no): "
  read response
  [[ "$response" == "yes" ]]
}

_gita_check_git() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    _gita_error "Not a git repository"
    return 1
  fi
  return 0
}

_gita_current_branch() {
  git branch --show-current
}

_gita_has_changes() {
  [[ -n $(git status -s) ]]
}

_gita_has_upstream() {
  git rev-parse --abbrev-ref @{u} > /dev/null 2>&1
}

# Main function
gita() {
  local cmd=$1
  shift
  
  case "$cmd" in
    
    ###################
    # SIZE & ANALYSIS
    ###################
    
    size)
      _gita_check_git || return 1
      _gita_info "Finding largest files in Git history..."
      git rev-list --objects --all | \
      git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
      sed -n 's/^blob //p' | \
      sort -k2 -nr | \
      head -20 | \
      awk '{printf "%s%.2f MB%s\t%s\n", "'$CYAN'", $1/1024/1024, "'$NC'", $2}'
      ;;
      
    large)
      local size=${1:-50}
      _gita_info "Finding files larger than ${size}MB in working directory..."
      find . -type f -size +${size}M -not -path "./.git/*" -exec ls -lh {} \; | \
      awk '{print "'$CYAN'" $5 "'$NC'\t" $9}' | sort -hr
      ;;
      
    status|st)
      _gita_check_git || return 1
      git status
      echo ""
      echo "${BOLD}📊 Repository Stats:${NC}"
      echo "Branch: ${CYAN}$(_gita_current_branch)${NC}"
      if _gita_has_upstream; then
        echo "Commits ahead: ${GREEN}$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)${NC}"
        echo "Commits behind: ${RED}$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)${NC}"
      else
        echo "${YELLOW}No upstream branch set${NC}"
      fi
      local repo_size=$(du -sh .git 2>/dev/null | cut -f1)
      echo "Repository size: ${CYAN}${repo_size}${NC}"
      ;;
      
    info)
      _gita_check_git || return 1
      echo "${BOLD}📁 Repository Information:${NC}"
      echo "Remote URL: ${CYAN}$(git remote get-url origin 2>/dev/null || echo 'No remote')${NC}"
      echo "Current branch: ${CYAN}$(_gita_current_branch)${NC}"
      echo "Total commits: ${CYAN}$(git rev-list --count HEAD)${NC}"
      echo "Total branches: ${CYAN}$(git branch -a | wc -l | tr -d ' ')${NC}"
      echo "Contributors: ${CYAN}$(git shortlog -sn --all | wc -l | tr -d ' ')${NC}"
      echo "Last commit: ${CYAN}$(git log -1 --format=%ar)${NC}"
      ;;
    
    ###################
    # STAGING
    ###################
    
    add)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git add -A
        _gita_success "Staged all changes"
      else
        git add "$@"
        _gita_success "Staged: $*"
      fi
      ;;
      
    unstage)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git reset HEAD
        _gita_success "Unstaged all files"
      else
        git reset HEAD "$@"
        _gita_success "Unstaged: $*"
      fi
      ;;
      
    diff)
      _gita_check_git || return 1
      if [[ -n "$1" ]]; then
        git diff "$@"
      else
        git diff
      fi
      ;;
      
    diffc)
      _gita_check_git || return 1
      git diff --cached "$@"
      ;;
    
    ###################
    # COMMITTING
    ###################
    
    commit|cm)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_error "Commit message required"
        echo "Usage: gita commit <message>"
        return 1
      fi
      git commit -m "$*"
      ;;
      
    amend)
      _gita_check_git || return 1
      if [[ -n "$1" ]]; then
        git commit --amend -m "$*"
      else
        git commit --amend --no-edit
      fi
      _gita_success "Amended last commit"
      ;;
      
    quick|qc)
      _gita_check_git || return 1
      local message="${*:-Quick commit: $(date '+%Y-%m-%d %H:%M:%S')}"
      if ! _gita_has_changes; then
        _gita_info "No changes to commit"
        return 0
      fi
      git add -A
      git commit -m "$message"
      _gita_success "Committed: $message"
      ;;
    
    ###################
    # PUSH/PULL
    ###################
    
    push)
      _gita_check_git || return 1
      if ! _gita_has_upstream; then
        _gita_warning "No upstream branch set"
        if _gita_confirm "Push and set upstream to origin/$(_gita_current_branch)?"; then
          git push -u origin "$(_gita_current_branch)"
          return $?
        else
          return 1
        fi
      fi
      git push "$@"
      ;;
      
    pushf)
      _gita_check_git || return 1
      _gita_warning "Force push will OVERWRITE remote history!"
      _gita_warning "This can cause problems for collaborators!"
      if [[ "$GITA_CONFIRM_FORCE" == "true" ]]; then
        if ! _gita_confirm "Are you absolutely sure?"; then
          _gita_info "Aborted"
          return 1
        fi
      fi
      git push --force-with-lease "$@"
      ;;
      
    pull)
      _gita_check_git || return 1
      if [[ "$GITA_AUTO_FETCH" == "true" ]]; then
        git fetch --prune
      fi
      git pull "$@"
      ;;
      
    sync)
      _gita_check_git || return 1
      local branch="${1:-$GITA_DEFAULT_BRANCH}"
      _gita_warning "This will DISCARD ALL local changes!"
      _gita_warning "Branch: origin/$branch"
      if [[ "$GITA_CONFIRM_DESTRUCTIVE" == "true" ]]; then
        if ! _gita_confirm "Proceed with sync?"; then
          _gita_info "Aborted"
          return 1
        fi
      fi
      git fetch origin "$branch"
      git reset --hard "origin/$branch"
      _gita_success "Synced with origin/$branch"
      ;;
      
    fetch)
      _gita_check_git || return 1
      git fetch --all --prune "$@"
      _gita_success "Fetched from all remotes"
      ;;
    
    ###################
    # BRANCHING
    ###################
    
    branch|br)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git branch -vv
      else
        local subcommand="$1"
        shift
        case "$subcommand" in
          -d|delete)
            if [[ -z "$1" ]]; then
              _gita_error "Branch name required"
              return 1
            fi
            git branch -d "$@"
            ;;
          -D|force-delete)
            if [[ -z "$1" ]]; then
              _gita_error "Branch name required"
              return 1
            fi
            _gita_warning "Force deleting branch(es): $*"
            git branch -D "$@"
            ;;
          -r|remote)
            git branch -r
            ;;
          -a|all)
            git branch -a
            ;;
          *)
            git checkout -b "$subcommand" "$@"
            _gita_success "Created and switched to branch: $subcommand"
            ;;
        esac
      fi
      ;;
      
    switch|sw)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_error "Branch name required"
        return 1
      fi
      git switch "$@"
      ;;
      
    checkout|co)
      _gita_check_git || return 1
      git checkout "$@"
      ;;
      
    merge)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_error "Branch name required"
        return 1
      fi
      git merge "$@"
      ;;
      
    rebase)
      _gita_check_git || return 1
      if [[ "$1" == "-i" || "$1" == "--interactive" ]]; then
        shift
        git rebase -i "$@"
      else
        git rebase "$@"
      fi
      ;;
    
    ###################
    # STASHING
    ###################
    
    stash)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git stash push
        _gita_success "Stashed changes"
      else
        local subcommand="$1"
        shift
        case "$subcommand" in
          pop)
            git stash pop "$@"
            ;;
          list|ls)
            git stash list
            ;;
          show)
            git stash show -p "$@"
            ;;
          drop)
            git stash drop "$@"
            ;;
          clear)
            _gita_warning "This will delete ALL stashes!"
            if _gita_confirm "Clear all stashes?"; then
              git stash clear
              _gita_success "Cleared all stashes"
            fi
            ;;
          apply)
            git stash apply "$@"
            ;;
          *)
            git stash push -m "$subcommand $*"
            _gita_success "Stashed with message: $subcommand $*"
            ;;
        esac
      fi
      ;;
    
    ###################
    # HISTORY
    ###################
    
    log|lg)
      _gita_check_git || return 1
      local format="${GITA_LOG_FORMAT:-oneline}"
      if [[ -n "$1" ]]; then
        git log "$@"
      else
        git log --oneline --graph --decorate -20
      fi
      ;;
      
    history)
      _gita_check_git || return 1
      git log --all --graph --decorate --oneline
      ;;
      
    blame)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_error "File name required"
        return 1
      fi
      git blame "$@"
      ;;
      
    show)
      _gita_check_git || return 1
      git show "$@"
      ;;
    
    ###################
    # UNDOING
    ###################
    
    undo)
      _gita_check_git || return 1
      _gita_info "Undoing last commit (keeping changes staged)"
      git reset --soft HEAD~1
      _gita_success "Last commit undone"
      ;;
      
    reset)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_error "Specify: soft, mixed, or hard"
        echo "Usage: gita reset {soft|mixed|hard} [commit]"
        return 1
      fi
      local mode="$1"
      shift
      case "$mode" in
        soft)
          git reset --soft "$@"
          ;;
        mixed)
          git reset --mixed "$@"
          ;;
        hard)
          _gita_warning "Hard reset will DISCARD all changes!"
          if [[ "$GITA_CONFIRM_DESTRUCTIVE" == "true" ]]; then
            if ! _gita_confirm "Proceed with hard reset?"; then
              _gita_info "Aborted"
              return 1
            fi
          fi
          git reset --hard "$@"
          ;;
        *)
          _gita_error "Invalid mode: $mode"
          return 1
          ;;
      esac
      ;;
      
    revert)
      _gita_check_git || return 1
      git revert "$@"
      ;;
      
    clean)
      _gita_check_git || return 1
      echo "${BOLD}Files that will be removed:${NC}"
      git clean -n
      if _gita_confirm "Remove these untracked files?"; then
        git clean -f
        _gita_success "Cleaned untracked files"
      fi
      ;;
      
    discard)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        _gita_warning "This will discard ALL unstaged changes!"
        if _gita_confirm "Discard all changes?"; then
          git checkout -- .
          _gita_success "Discarded all changes"
        fi
      else
        git checkout -- "$@"
        _gita_success "Discarded changes in: $*"
      fi
      ;;
    
    ###################
    # REMOTES
    ###################
    
    remote)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git remote -v
      else
        git remote "$@"
      fi
      ;;
      
    clone)
      if [[ -z "$1" ]]; then
        _gita_error "Repository URL required"
        return 1
      fi
      git clone "$@"
      ;;
    
    ###################
    # TAGS
    ###################
    
    tag)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        git tag -l
      else
        git tag "$@"
      fi
      ;;
    
    ###################
    # UTILITIES
    ###################
    
    ignore)
      _gita_check_git || return 1
      if [[ -z "$1" ]]; then
        if [[ -f .gitignore ]]; then
          cat .gitignore
        else
          _gita_info "No .gitignore file found"
        fi
      else
        echo "$*" >> .gitignore
        _gita_success "Added to .gitignore: $*"
      fi
      ;;
      
    conflicts)
      _gita_check_git || return 1
      git diff --name-only --diff-filter=U
      ;;
      
    contributors)
      _gita_check_git || return 1
      git shortlog -sn --all
      ;;
      
    stats)
      _gita_check_git || return 1
      echo "${BOLD}📊 Detailed Statistics:${NC}"
      echo ""
      echo "${BOLD}Commits by author:${NC}"
      git shortlog -sn --all | head -10
      echo ""
      echo "${BOLD}File changes:${NC}"
      git log --all --numstat --pretty="%H" | \
        awk 'NF==3 {plus+=$1; minus+=$2} END {printf "+%d -%d\n", plus, minus}'
      echo ""
      echo "${BOLD}Most changed files:${NC}"
      git log --all --pretty=format: --name-only | \
        sort | uniq -c | sort -rg | head -10
      ;;
    
    ###################
    # CONFIG
    ###################
    
    config)
      if [[ -z "$1" ]]; then
        echo "${BOLD}Current GITA Configuration:${NC}"
        cat "$GITA_CONFIG_FILE"
      else
        local subcommand="$1"
        shift
        case "$subcommand" in
          edit)
            ${GITA_DEFAULT_EDITOR:-vim} "$GITA_CONFIG_FILE"
            _gita_init_config
            _gita_success "Config reloaded"
            ;;
          reset)
            rm "$GITA_CONFIG_FILE"
            _gita_init_config
            _gita_success "Config reset to defaults"
            ;;
          set)
            if [[ -z "$1" || -z "$2" ]]; then
              _gita_error "Usage: gita config set <key> <value>"
              return 1
            fi
            local key="$1"
            local value="$2"
            sed -i.bak "s/^${key}=.*/${key}=${value}/" "$GITA_CONFIG_FILE"
            _gita_init_config
            _gita_success "Set ${key}=${value}"
            ;;
          *)
            git config "$subcommand" "$@"
            ;;
        esac
      fi
      ;;
    
    ###################
    # HELP
    ###################
    
    help|--help|-h)
      cat << EOF
${BOLD}🎯 GITA - Git Assistant CLI${NC}

${BOLD}📏 SIZE & ANALYSIS:${NC}
  gita size                    Show largest files in Git history
  gita large [MB]              Find files larger than X MB (default: 50)
  gita status, st              Enhanced status with stats
  gita info                    Repository information
  gita stats                   Detailed repository statistics

${BOLD}📦 STAGING:${NC}
  gita add [files]             Stage files (or all if none specified)
  gita unstage [files]         Unstage files (or all if none specified)
  gita diff [files]            Show unstaged changes
  gita diffc [files]           Show staged changes

${BOLD}💾 COMMITTING:${NC}
  gita commit <msg>            Commit with message
  gita quick [msg]             Add all and commit (auto message if none)
  gita amend [msg]             Amend last commit

${BOLD}🚀 PUSH/PULL:${NC}
  gita push                    Push to remote (safe)
  gita pushf                   ${RED}Force push${NC} (asks confirmation)
  gita pull                    Pull from remote
  gita sync [branch]           ${RED}Hard reset to remote${NC} (destructive)
  gita fetch                   Fetch from all remotes

${BOLD}🌿 BRANCHING:${NC}
  gita branch, br              List branches
  gita branch <name>           Create and switch to branch
  gita branch -d <name>        Delete branch
  gita branch -D <name>        ${RED}Force delete branch${NC}
  gita switch <name>           Switch to branch
  gita merge <branch>          Merge branch into current
  gita rebase [-i] <branch>    Rebase onto branch

${BOLD}📚 STASHING:${NC}
  gita stash                   Stash current changes
  gita stash pop               Apply and remove latest stash
  gita stash list              List all stashes
  gita stash apply [n]         Apply stash without removing
  gita stash drop [n]          Remove specific stash
  gita stash clear             ${RED}Remove all stashes${NC}

${BOLD}📖 HISTORY:${NC}
  gita log                     Show commit history (graph)
  gita history                 Show full history tree
  gita show [commit]           Show commit details
  gita blame <file>            Show who changed each line

${BOLD}↩️  UNDOING:${NC}
  gita undo                    Undo last commit (keep changes)
  gita reset {soft|mixed|hard} Reset to commit
  gita revert <commit>         Revert a commit
  gita discard [files]         ${RED}Discard unstaged changes${NC}
  gita clean                   ${RED}Remove untracked files${NC}

${BOLD}🔗 REMOTES:${NC}
  gita remote                  List remotes
  gita remote add <n> <url>    Add remote
  gita clone <url>             Clone repository

${BOLD}🏷️  TAGS:${NC}
  gita tag                     List tags
  gita tag <name>              Create tag

${BOLD}🛠️  UTILITIES:${NC}
  gita ignore [pattern]        Add to .gitignore (or view)
  gita conflicts               Show merge conflicts
  gita contributors            Show all contributors

${BOLD}⚙️  CONFIG:${NC}
  gita config                  Show GITA config
  gita config edit             Edit config file
  gita config set <k> <v>      Set config value
  gita config <git-args>       Pass to git config

${BOLD}❓ HELP:${NC}
  gita help                    Show this help

${YELLOW}⚠️  Commands marked in ${RED}red${YELLOW} are destructive!${NC}
${BLUE}ℹ️  Config file: ${GITA_CONFIG_FILE}${NC}
EOF
      ;;
      
    version|--version|-v)
      echo "${BOLD}GITA${NC} version 1.0.0"
      echo "Git version: $(git --version)"
      ;;
      
    *)
      if [[ -z "$cmd" ]]; then
        gita help
      else
        _gita_error "Unknown command: $cmd"
        echo "Run ${CYAN}gita help${NC} for usage"
        return 1
      fi
      ;;
  esac
}

# Zsh completion
if [[ -n "$ZSH_VERSION" ]]; then
  _gita_completion() {
    local -a commands
    commands=(
      'size:Show largest files in Git history'
      'large:Find large files in working directory'
      'status:Enhanced git status'
      'info:Repository information'
      'stats:Detailed statistics'
      'add:Stage files'
      'unstage:Unstage files'
      'diff:Show changes'
      'diffc:Show staged changes'
      'commit:Commit changes'
      'quick:Quick commit'
      'amend:Amend last commit'
      'push:Push to remote'
      'pushf:Force push'
      'pull:Pull from remote'
      'sync:Sync with remote'
      'fetch:Fetch from remotes'
      'branch:Branch operations'
      'switch:Switch branch'
      'checkout:Checkout branch'
      'merge:Merge branch'
      'rebase:Rebase branch'
      'stash:Stash changes'
      'log:Show commit log'
      'history:Show full history'
      'show:Show commit'
      'blame:Show line authors'
      'undo:Undo last commit'
      'reset:Reset to commit'
      'revert:Revert commit'
      'discard:Discard changes'
      'clean:Remove untracked files'
      'remote:Remote operations'
      'clone:Clone repository'
      'tag:Tag operations'
      'ignore:Gitignore operations'
      'conflicts:Show conflicts'
      'contributors:Show contributors'
      'config:Configuration'
      'help:Show help'
      'version:Show version'
    )
    _describe 'gita commands' commands
  }
  
  compdef _gita_completion gita
fi

# Aliases (optional - uncomment if desired)
# alias gs='gita status'
# alias ga='gita add'
# alias gc='gita commit'
# alias gp='gita push'
# alias gl='gita pull'
# alias gco='gita checkout'
# alias gb='gita branch'
# alias glog='gita log'
