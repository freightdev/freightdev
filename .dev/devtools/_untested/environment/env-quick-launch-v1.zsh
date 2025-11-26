#! /usr/bin/env zsh
#! ╔═════════════════════════════════╗
#?   zBox Environment Quick Launch - v1.0.0
#! ╚═════════════════════════════════╝


#? Load Secure Environments
# ================================
for env in ./secure/**/.[!.]*; do #? <=== Default KEY:VALUE pairs live here.
    if [[ -f "$env" ]]; then
        source "$env"
    fi
done
log_scan "Scanning for your envinronment : $ENV_SRC"


#? Check for Completions
# ================================
if [[ -d "$ENV_SRC" ]]; then
    echo "Envriroment already loaded: $ENV_SRC"
    return 1
fi


#? Symlink Environment Paths
# ================================
mkdir -p "$ENV_DIR"

for f in "$ENV_DIR/src"/*; do
    ln -sfnv "$f" "$ENV_SRC/"
done

for f in "$ENV_DIR/dotfiles"/.[!.]; do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$HOME/${f##*/}"
done

echo "Environment resource symlink set!"

#? Creating Source Loader
# ================================
if [[ ! -f "$HOME/.zshrc" ]]; then
    cat > "$HOME/.zshrc" <<'EOF'
#! ╔══════════════════════════════════╗
#? zBoxxy's Source Loader - v1.0.0
#! ╚══════════════════════════════════╝
: "${ENV_SRC:=$HOME/.zshrc.d}"
# Interactive Shells Runner
# ================================
[[ $- != *i* ]] && return
#! Check for Resources
# ================================
[[ -d "$ENV_SRC" ]] || {
echo "\e[31m[WARN]\e[0m Environment resources not found: $ENV_SRC"; return 1;
}
#! Load All Resources
# ================================
typeset -a load_order=("$ENV_SRC/envs" "$ENV_SRC/helpers" "$ENV_SRC/settings")
typeset -a ignore_files=("")
typeset -a env_files=(
    .env.example
)
typeset -a helper_files=(
    archive.zsh backup.zsh docker.zsh encryption.zsh git.zsh history.zsh
    network.zsh plugin.zsh prompt.zsh quick.zsh scan.zsh search.zsh
    ssh.zsh storage.zsh system.zsh viewer.zsh
)
typeset -a setting_files=(
    alias.zsh autoload.zsh color.zsh export.zsh format.zsh setopt.zsh zstyle.zsh
)
src_start=$SECONDS
for dir in "${load_order[@]}"; do
    [[ -d "$dir" ]] || continue
        case "$dir" in
    *env)
        priority_files=("${env_files[@]}")
    ;;
    *helper)
        priority_files=("${helper_files[@]}")
    ;;
    *setting)
        priority_files=("${setting_files[@]}")
    ;;
    *)
        priority_files=()
    ;;
    esac
    
    #* Load priority files first *#
    for pf in "${priority_files[@]}"; do
        basename="$(basename "$pf")"
        [[ -f "$dir/$pf" && -r "$dir/$pf" ]] || continue
        ((LOADED_COUNT++))
        echo "[$LOADED_COUNT] $basename..."
        source "$dir/$pf"
    done
    #* Load remaining *.zsh files *#
    for rf in "$dir"/*.zsh(N); do
        basename="$(basename "$rf")"
        [[ -f "$rf" && -r "$rf" ]] || continue
        if (( ${priority_files[(Ie)$basename]} == 0 && ${ignore_files[(Ie)$basename]} == 0 )); then
            ((LOADED_COUNT++))
            echo "[$LOADED_COUNT] $basename..."
            source "$rf"
        fi
    done
done
log_ok "All resource loaded!"
EOF
log_info "Environment source file created: $ENV_LOADER"
fi