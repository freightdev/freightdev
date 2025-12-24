#!  ╔══════════════════════════════════╗
#?     Jesse Conley's Source - v1.0.0
#!  ╚══════════════════════════════════╝


#!        Configurations 
# ================================
: "${ENV_SRC:=$HOME/.zshrc.d}"
: "${ENV_CFG:=$ENV_SRC/configs}"
: "${ENV_HELP:=$ENV_SRC/helpers}"

#!     Load Environment Init
# ================================
[[ -f "$ENV_SRC/.zshenv" ]] && source "$ENV_SRC/.zshenv"


#!     Check for Completions 
# ================================
if [[ -f "$ENV_FILE" ]]; then
    echo "Environment already loaded, skipping..."
    return 0
else
    [[ -f "$ENV_SRC/.zshenv" ]] && source "$ENV_SRC/.zshenv"
fi


#!  Load All Enironment Sources 
# ================================
typeset -a load_order=("$ENV_CFG" "$ENV_HELP")
typeset -a ignore_files=("")

typeset -a config_files=( 
    alias.zsh autoload.zsh color.zsh export.zsh format.zsh setopt.zsh zstyle.zsh
)
typeset -a helper_files=( 
    archive.zsh backup.zsh docker.zsh encryption.zsh git.zsh history.zsh
    network.zsh plugin.zsh pretty.zsh prompt.zsh quick.zsh scan.zsh
    search.zsh ssh.zsh storage.zsh system.zsh viewer.zsh
)

src_start=$SECONDS

for dir in "${load_order[@]}"; do
    [[ -d "$dir" ]] || continue

    case "$dir" in 
        *config)
            priority_files=("${config_files[@]}")
            section "Configs"
            ;; 
        *helper)
            priority_files=("${helper_files[@]}")
            section "Helpers"
            ;; 
        *)
            priority_files=()
            section "$(basename "$dir")"
            ;;
    esac

    #* Load priority files first *#
    for pf in "${priority_files[@]}"; do
        basename="$(basename "$pf")"
        [[ -f "$dir/$pf" && -r "$dir/$pf" ]] || continue
        ((LOADED_COUNT++))
        log_loading "[$LOADED_COUNT] $basename..."
        source "$dir/$pf"
    done

    #* Load remaining *.zsh files *#
    for rf in "$dir"/*.zsh(N); do
        basename="$(basename "$rf")"
        [[ -f "$rf" && -r "$rf" ]] || continue

        #* Skip if file is in priority_files or ignore_files
        if (( ${priority_files[(Ie)$basename]} == 0 && ${ignore_files[(Ie)$basename]} == 0 )); then
            ((LOADED_COUNT++))
            log_loading "[$LOADED_COUNT] $basename..."
            source "$rf"
        fi
    done
done

log_ok "Source loading complete."
