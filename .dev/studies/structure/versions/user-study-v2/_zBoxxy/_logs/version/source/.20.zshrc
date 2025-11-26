#!  ╔══════════════════════════════════╗
#?     Jesse Conley's Source - v1.0.0
#!  ╚══════════════════════════════════╝

#!    Default Resource Paths
# ================================
: "${ENV_SRC:=$HOME/.zshrc.d}"

#!   Interactive Shells Runner
# ================================
[[ $- != *i* ]] && return


#!  Reload Environment Resources
# ================================
if [[ ! -d "$ENV_DIR" ]]; then
    echo "\e[31m[WARN]\e[0m Environments not found!"
    reurn 1
fi


#!  Symlink Environment Secerts
# ================================
for f in "$ENV_SRC/dotfiles"/../.(D); do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$HOME"
done

log_set "All environment symlinks set: $ENV_SRC -> $ENV_DIR && $ENV_DOT -> $HOME"


#!      Load All Resources
# ================================
if [[ -f "$ENV_SRC"/**/*(.) ]]; then
    source "$ENV_SRC"/**/*(.)
else
    log_error "Environment resources not found: $ENV_SRC"
fi

log_ok "All resource loaded!"
