#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝


#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- Load Environments --- !#
load_envs() {
    log_info "#! === Environment Loader === !#"
    
    #* --- Get environment directory --- *#
    local env_dir=""
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        env_dir="$HOME/.config/envs"
        log_info "Non-interactive mode: using default directory $env_dir"
    else
        read -r "env_dir?Enter your environment directory path: "
    fi
    [[ -z "$env_dir" ]] && { log_warn "No path entered. Skipping."; return 1; }
    [[ ! -d "$env_dir" ]] && { log_error "Directory not found: $env_dir"; return 1; }
    
    #* --- Collect all environment items --- *#
    local env_items=()
    for item in "$env_dir"/*(N); do
        env_items+=("$item")
    done
    
    (( ${#env_items[@]} == 0 )) && { log_warn "No environment items found in $env_dir"; return 1; }
    
    #* --- Display available items --- *#
    log_info "Found the following environment items:"
    local i
    for i in {1..${#env_items[@]}}; do
        local item="${env_items[$i]}"
        local type=""
        if [[ -f "$item" ]]; then
            case "$item" in
                *.env) type=" (env file)" ;;
                *.key|*.pem|id_*) type=" (key file)" ;;
                *.pub) type=" (public key)" ;;
                *.crt) type=" (certificate)" ;;
                *.sh|*.zsh|*.bash) type=" (shell config)" ;;
                *.conf|*.config|*.cfg) type=" (config file)" ;;
                *) type=" (file)" ;;
            esac
        else
            case "$(basename "$item")" in
                .ssh|*ssh*) type=" (SSH directory)" ;;
                .gnupg|.gpg|*gpg*) type=" (GPG directory)" ;;
                *) type=" (directory)" ;;
            esac
        fi
        echo " [$i] $(basename "$item")$type"
    done
    
    #* --- Get user selection --- *#
    local selected=()
    local choice=""
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        choice="a"
        log_info "Non-interactive mode: loading all environment items"
    else
        read -r "choice?Select items (number), 'a' for all, or 'e' for env files only: "
    fi
    
    case "$choice" in
        a|A)
            selected=("${env_items[@]}")
            log_info "Selected all environment items"
            ;;
        e|E)
            for item in "${env_items[@]}"; do
                [[ "$item" == *.env ]] && selected+=("$item")
            done
            (( ${#selected[@]} == 0 )) && { log_warn "No .env files found"; return 1; }
            log_info "Selected all .env files"
            ;;
        *)
            if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#env_items[@]} )); then
                log_error "Invalid choice. Must be a number between 1-${#env_items[@]}, 'e' for env files, or 'a' for all"
                return 1
            fi
            selected=("${env_items[$choice]}")
            log_info "Selected: $(basename "${env_items[$choice]}")"
            ;;
    esac
    
    #* --- Confirm loading --- *#
    local confirm="y"
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        confirm="y"
    else
        read -r "confirm?Load selected environment item(s)? (y/N): "
    fi
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { log_info "Operation cancelled."; return 0; }
    
    echo
    
    #* --- Process each selected item --- *#
    for item in "${selected[@]}"; do
        if [[ -f "$item" ]]; then
            case "$item" in
                *.env)
                    log_info "Loading env file: $(basename "$item")"
                    if [[ -r "$item" ]]; then
                        set -a; source "$item" 2>/dev/null; set +a
                    else
                        log_warn "Cannot read env file: $(basename "$item")"
                    fi
                    ;;
                *.sh|*.zsh|*.bash)
                    log_info "Sourcing shell config: $(basename "$item")"
                    if [[ -r "$item" ]]; then
                        source "$item" 2>/dev/null || log_warn "Failed to source $(basename "$item")"
                    else
                        log_warn "Cannot read config file: $(basename "$item")"
                    fi
                    ;;
                *.conf|*.config|*.cfg)
                    log_info "Loading config file: $(basename "$item")"
                    if [[ -r "$item" ]]; then
                        if head -n 5 "$item" 2>/dev/null | grep -q '='; then
                            set -a; source "$item" 2>/dev/null; set +a
                        else
                            log_warn "Config file $(basename "$item") doesn't appear to contain shell variables"
                        fi
                    else
                        log_warn "Cannot read config file: $(basename "$item")"
                    fi
                    ;;
                *.key|*.pem|id_*)
                    if [[ -r "$item" ]] && grep -q "PRIVATE KEY" "$item" 2>/dev/null; then
                        log_info "Adding SSH private key: $(basename "$item")"
                        if [[ -z "$SSH_AUTH_SOCK" ]]; then
                            eval "$(ssh-agent -s)" >/dev/null 2>&1
                        fi
                        if ssh-add "$item" 2>/dev/null; then
                            log_ok "SSH key added: $(basename "$item")"
                        else
                            log_warn "Failed to add SSH key: $(basename "$item")"
                        fi
                    else
                        log_info "Key file found: $(basename "$item") (manual processing may be required)"
                    fi
                    ;;
                *.crt|*.pub)
                    log_info "Certificate/public key found: $(basename "$item") (no automatic loading)"
                    ;;
                *)
                    log_info "Loading file: $(basename "$item")"
                    if [[ -r "$item" ]]; then
                        source "$item" 2>/dev/null || log_warn "Could not source $(basename "$item")"
                    else
                        log_warn "Cannot read file: $(basename "$item")"
                    fi
                    ;;
            esac
        elif [[ -d "$item" ]]; then
            case "$(basename "$item")" in
                .ssh|*ssh*)
                    log_info "Processing SSH directory: $(basename "$item")"
                    if [[ -z "$SSH_AUTH_SOCK" ]]; then
                        eval "$(ssh-agent -s)" >/dev/null 2>&1
                    fi
                    for key in "$item"/id_* "$item"/*.key "$item"/*.pem; do
                        if [[ -f "$key" && -r "$key" && ! "$key" == *.pub ]] && grep -q "PRIVATE KEY" "$key" 2>/dev/null; then
                            if ssh-add "$key" 2>/dev/null; then
                                log_ok "Added SSH key: $(basename "$key")"
                            else
                                log_warn "Failed to add SSH key: $(basename "$key")"
                            fi
                        fi
                    done
                    ;;
                .gnupg|.gpg|*gpg*)
                    log_info "Processing GPG directory: $(basename "$item")"
                    # Use proper zsh globbing with fallback
                    local gpg_files=()
                    for pattern in "$item"/*.gpg "$item"/*.asc "$item"/*.key; do
                        [[ -f "$pattern" ]] && gpg_files+=("$pattern")
                    done
                    for key in "${gpg_files[@]}"; do
                        if [[ -f "$key" && -r "$key" ]]; then
                            if gpg --import "$key" 2>/dev/null; then
                                log_ok "Imported GPG key: $(basename "$key")"
                            else
                                log_warn "Failed to import GPG key: $(basename "$key")"
                            fi
                        fi
                    done
                    ;;
                *)
                    log_info "Processing directory: $(basename "$item")"
                    for subitem in "$item"/*; do
                        [[ -f "$subitem" ]] && log_info "Found: $(basename "$subitem")"
                    done
                    ;;
            esac
        fi
    done
    
    log_ok "Environment loading completed."
    return 0
}