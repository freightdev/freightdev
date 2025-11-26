#!  ╔══════════════════════════════════╗
#!  ║  Jesse Conley's Source - v1.0.0  ║
#!  ╚══════════════════════════════════╝

section "Bin Links (customs)"

# Symlink dotfiles (ignores . and ..)
for f in $ENV_DIR/dotfiles/.[^.]*; do
    ln -sf "$f" ~/
done

#! --- Source all files defined below --- !#

typeset -a load_order=("$ENV_DIR/configs" "$ENV_DIR/functions" "$ENV_DIR/functions")
typeset -a ignore_files=("")

typeset -a config_files=( 
    alias.zsh autoload.zsh color.zsh export.zsh format.zsh setopt.zsh zstyle.zsh
)
typeset -a function_files=( 
    archive.zsh backup.zsh docker.zsh encryption.zsh git.zsh history.zsh management.zsh
    network.zsh quick.zsh scan.zsh search.zsh ssh.zsh storage.zsh system.zsh viewer.zsh
)
typeset -a function_files=( 
    plugin.zsh prompt.zsh route.zsh source.zsh
)

src_start=$SECONDS

for dir in "${load_order[@]}"; do
    [[ -d "$dir" ]] || continue

    case "$dir" in 
        *config)
            priority_files=("${setting_files[@]}")
            section "Configss"
            ;; 
        *functions)
            priority_files=("${function_files[@]}")
            section "Functions"
            ;;
        *helper)
            priority_files=("${setting_files[@]}")
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
        [[ -f "$dir/$pf" ]] && {
            ((LOADED_COUNT++))
            log_loading "[$LOADED_COUNT] $basename..."
            source "$dir/$pf"
        fi
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

src_time=$((SECONDS - src_start))
log_set "Loaded $LOADED_COUNT files in ${src_time}s"

#! --- Session Summary --- !#

summary "$SESSION_DURATION" "$LOADED_COUNT" "$VARS_ADDED"

log_ok "Source loading complete."