#!  ╔══════════════════════════════════╗
#?     Jesse Conley's Source - v1.0.0
#!  ╚══════════════════════════════════╝
: "${ENV_SRC:=$HOME/.zshrc.d}"

#!   Interactive Shells Runner
# ================================
[[ $- != *i* ]] && return


#!      Load All Resources
# ================================
if [[ ! "$ENV_SRC" ]]; then
    echo "\e[31m[WARN]\e[0m Environments not found!"
    return 1
fi

if [[ -n "$ENV_SRC"/**/*(N.) ]]; then
    for res in "$ENV_SRC"/**/*(N.); do
        source "$res"
    done
else
    echo "Environment resources not found: $ENV_SRC"
    return 1
fi

log_ok "All resource loaded!"
