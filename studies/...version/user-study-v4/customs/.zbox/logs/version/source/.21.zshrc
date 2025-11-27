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
    log_error "Environments not found!"
    return 1
fi


#!  Symlink Environment Secerts
# ================================
for f in "$ENV_SRC/dotfiles"/.*(DN); do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$HOME/${f:t}"
done


#!      Load All Resources
# ================================
if [[ -n "$ENV_SRC"/**/*(N.) ]]; then
    for res in "$ENV_SRC"/**/*(N.); do
        source "$res"
    done
else
    log_error "Environment resources not found: $ENV_SRC"
    return 1
fi

log_ok "All resource loaded!"
