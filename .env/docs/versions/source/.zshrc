#!  ╔══════════════════════════════════╗
#!  ║  Jesse Conley's Source - v1.0.0  ║
#!  ╚══════════════════════════════════╝

section "Bin Links (customs)"

# Symlink dotfiles (ignores . and ..)
for f in $DOT_DIR/.[^.]*; do
    ln -sf "$f" ~/
done

#! --- Validate Target (.zshrc.d) --- !#
if [[ ! -d "$SRC_DIR" ]]; then
    log_error "$(basename "$SRC_DIR") not detected!"
    exit 1
fi

log_scan "Found $(basename "$SRC_DIR")!"
prompt "Would you like to backup $(basename "$SRC_DIR")? (y/N) " CONFIRM
if [[ "$CONFIRM" == [yY] ]]; then
    mkdir -p "$(dirname "${SRC_DIR}-${TS}")"
    cp -r "$SRC_DIR" "${SRC_DIR}-${TS}"
    log_set "Backup created at $(dirname "$SRC_DIR")"
else
    log_warn "Skipped backup generator..."
fi

#! --- Source all files defined below --- !#

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

src_time=$((SECONDS - src_start))
log_set "Loaded $LOADED_COUNT files in ${src_time}s"

#! --- Session Summary --- !#

summary "$SESSION_DURATION" "$LOADED_COUNT" "$VARS_ADDED"

log_ok "Source loading complete."