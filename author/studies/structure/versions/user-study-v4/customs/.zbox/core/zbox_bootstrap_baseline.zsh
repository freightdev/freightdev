#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝

source zbox_system_init.zsh
source zbox_git_repos.zsh
source zbox_git_repos.zsh

#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- Main Loader --- !#
bootstrap() {
    log_info "=== Running ZBox Bootstrap ==="
    system_init
    git_repos
    load_envs
    log_ok "Bootstrap complete."
}

# Run if executed directly
if [[ "${BASH_SOURCE:-$0}" == "$0" ]]; then
    bootstrap "$@"
fi
