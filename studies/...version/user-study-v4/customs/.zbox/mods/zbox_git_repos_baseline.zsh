#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝


#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- Git Repos --- !#
git_repos() {
    log_info "=== Syncing git repos ==="
    # Example: keep a central repo for configs
    local repos=(
        "https://github.com/example/mydotfiles.git ~/.zbox/etc/dotfiles"
    )

    for entry in $repos; do
        local url="${(z)entry}[1]"
        local path="${(z)entry}[2]"
        if [[ -d "$path/.git" ]]; then
            log_info "Updating repo: $path"
            (cd "$path" && git pull --ff-only)
        else
            log_info "Cloning repo: $url -> $path"
            git clone "$url" "$path"
        fi
    done
    log_ok "Git repos synced."
}