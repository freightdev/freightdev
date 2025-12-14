#! /usr/bin/env zsh
#  ╔══════════════════════════════╗
#?   ZBox Configurations - v1.0.0
#  ╚══════════════════════════════╝


#!      Load Default Paths
# ================================
echo "Script is running from: $SCRIPT_DIR"




#!      Load Default Paths
# ================================

for env in ./secure/**/.[!.]*; do  #? <=== Default KEY:VALUE pairs live here.
    if [[ -f "$env" ]]; then
        source "$env"
    fi
done

log_scan "Scanning for your envinronment : $ENV_SRC"


#!     Check for Completions 
# ================================
if [[ -d "$ENV_SRC" ]]; then
    echo "Envriroment already loaded: $ENV_SRC"
    return 1
fi


#!   Symlink Environment Paths
# ================================
mkdir -p "$ENV_DIR"
for f in "$ENV_DIR/src"/*; do
    ln -sfnv "$f" "$ENV_SRC/"
done

for f in "$ENV_DIR/dotfiles"/.[!.]; do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$HOME/${f##*/}"
done

for f in "$ENV_DIR/secure"/* "$ENV_DIR/secure"/**/.[!.]*; do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$HOME/${f##*/}"
done

echo "Environment resource symlink set!"



#!     Creating Source Loader
# ================================
if [[ ! -f "$HOME/.zshrc" ]]; then
    cat > "$HOME/.zshrc" <<'EOF'
#!  ╔═════════════════════════════════╗
#?     zBOXXY Source Loader - v1.0.0
#!  ╚═════════════════════════════════╝
: "${ENV_SRC:=$HOME/.zshrc.d}"

#!   Interactive Shells Runner
# ================================
[[ $- != *i* ]] && return


#!  Check for resource symlink
# ================================
[[ -d "$ENV_SRC" ]] || { 
echo "\e[31m[WARN]\e[0m Environment resources not found: $ENV_SRC"; return 1;
}


#! Source all files defined below 
# ================================
typeset -a load_order=("$SRC_DIR/functions" "$SRC_DIR/settings")
typeset -a ignore_files=("")

typeset -a function_files=( 
    archive.zsh backup.zsh bootstrap.zsh container.zsh encryption.zsh git.zsh history.zsh
    management.zsh network.zsh quick.zsh scan.zsh search.zsh ssh.zsh storage.zsh system.zsh 
    viewer.zsh
)
typeset -a setting_files=( 
    alias.zsh configuration.zsh export.zsh format.zsh optimization.zsh path.zsh plugin.zsh
    prompt.zsh
)

src_start=$SECONDS

for dir in "${load_order[@]}"; do
    [[ -d "$dir" ]] || continue

    case "$dir" in 
        *functions)
            priority_files=("${function_files[@]}")
            section "Functions"
            ;;
        *settings)
            priority_files=("${setting_files[@]}")
            section "Settings"
            ;; 
        *)
            priority_files=()
            section "$(basename "$dir")"
            ;;
    esac

    #* Load priority files first *#
    for pf in "${priority_files[@]}"; do
        basename="$(basename "$pf")"
        [[ -f "$dir/$pf" ]] && {
            ((LOADED_COUNT++))
            log_loading "[$LOADED_COUNT] $basename..."
            source "$dir/$pf"
        }
    done

    #* Load remaining *.zsh files *#
    for rf in "$dir"/*.zsh(N); do
        basename="$(basename "$rf")"
        if [[ -f "$rf" && -r "$rf" 
            && ! " ${priority_files[*]} " =~ " $basename "
            && ! " ${ignore_files[*]} " =~ " $basename " ]]; then
            ((LOADED_COUNT++))
            log_loading "[$LOADED_COUNT] $basename..."
            source "$file"
        fi
    done
done
EOF
    log_info "Environment source file created: $HOME/.zshrc"
fi