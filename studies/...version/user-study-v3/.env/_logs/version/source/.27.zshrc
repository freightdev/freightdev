#!  ╔══════════════════════════════════╗
#?     Jesse Conley's Source - v1.0.0
#!  ╚══════════════════════════════════╝
: "${ENV_SRC:=$HOME/.zshrc.d}"

#!   Interactive Shells Runner
# ================================
[[ $- != *i* ]] && return


#!      Check for Resources
# ================================
[[ -d "$ENV_SRC" ]] || { 
echo "\e[31m[WARN]\e[0m Environment resources not found: $ENV_SRC"; return 1;
}


#!      Load All Resources
# ================================
for res in "$ENV_SRC"/* "$ENV_SRC"/**/*; do
    [[ -f "$res" ]] || continue
    source "$res"
done

log_ok "All resource loaded!"
