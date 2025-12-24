# ==========================================
# Universal Bootstrap Setup 
# ==========================================

#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }

#! --- System Initiation --- !#
system_inits() {
    log_info "#! === System Initiation Process === !#"
    
    #* --- Root directory --- *#
    local init_root="$(cd "$(dirname "${(%):-%x}")" && pwd)"
    log_info "Initiating system from: $init_root"
    
    #* --- Load main package config --- *#
    local package_list=()
    local config_file="$init_root/configs/init-pkg.conf"
    
    if [[ -f "$config_file" ]]; then
        #* --- Read config file, filtering out empty lines and comments --- *#
        while IFS= read -r line || [[ -n "$line" ]]; do
            #* --- Skip empty lines and comments --- *#
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            #* --- Remove inline comments and trim whitespace --- *#
            line="${line%%#*}"
            line="${line#"${line%%[![:space:]]*}"}"  # Remove leading whitespace
            line="${line%"${line##*[![:space:]]}"}"  # Remove trailing whitespace
            [[ -n "$line" ]] && package_list+=("$line")
        done < "$config_file"
        log_info "Loaded ${#package_list[@]} packages from configuration"
    else
        log_warn "Package config file not found: $config_file"
        local manual_input="n"
        if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
            manual_input="n"
            log_info "Non-interactive mode: skipping manual package input"
        else
            read -r "manual_input?Enter packages manually? (y/N): "
        fi
        
        if [[ "$manual_input" =~ ^[Yy]$ ]]; then
            read -r "manual_packages?Enter packages (space-separated): "
            [[ -n "$manual_packages" ]] && package_list=(${(z)manual_packages})
        fi
    fi
    
    (( ${#package_list[@]} == 0 )) && { log_warn "No packages to install. Exiting."; return 0; }
    
    #* --- Interactive Package Filter --- *#
    log_info "Packages to process:"
    printf " - %s\n" "${package_list[@]}"
    
    local optimize="n"
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        optimize="n"
        log_info "Non-interactive mode: using all packages"
    else
        read -r "optimize?Remove any packages before processing? (y/N): "
    fi
    
    if [[ "$optimize" =~ ^[Yy]$ ]]; then
        local skip_packages=()
        echo
        log_info "Select packages to SKIP (press Enter to keep, 'y' to skip):"
        
        for pkg in "${package_list[@]}"; do
            read -r "remove?Skip package '$pkg'? (y/N): "
            [[ "$remove" =~ ^[Yy]$ ]] && skip_packages+=("$pkg")
        done
        
        #* --- Filter out skipped packages --- *#
        if (( ${#skip_packages[@]} > 0 )); then
            local filtered_list=()
            for pkg in "${package_list[@]}"; do
                local skip=false
                for skip_pkg in "${skip_packages[@]}"; do
                    [[ "$pkg" == "$skip_pkg" ]] && { skip=true; break; }
                done
                [[ "$skip" == false ]] && filtered_list+=("$pkg")
            done
            package_list=("${filtered_list[@]}")
            log_info "Packages after filtering: ${(j:, :)package_list}"
        fi
    fi
    
    (( ${#package_list[@]} == 0 )) && { log_warn "All packages filtered out. Exiting."; return 0; }
    
    #* --- Detect Operating System --- *#
    log_info "Detecting operating system..."
    local os_name="unknown"
    local os_type="unknown"
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        os_name="${NAME:-unknown}"
        log_info "OS detected: $os_name"
    else
        os_name="$(uname -s)"
        log_warn "Using fallback OS detection: $os_name"
    fi
    
    #* --- Map OS to package manager --- *#
    case "$os_name" in
        *"Arch"*|*"Manjaro"*|*"EndeavourOS"*)
            os_type="arch"
            ;;
        *"Debian"*|*"Ubuntu"*|*"Mint"*|*"Pop"*)
            os_type="debian"
            ;;
        *"Alpine"*)
            os_type="alpine"
            ;;
        *"Fedora"*|*"Red Hat"*|*"CentOS"*)
            os_type="redhat"
            ;;
        *)
            os_type="unknown"
            ;;
    esac
    
    #* --- Handle unknown OS --- *#
    if [[ "$os_type" == "unknown" ]]; then
        if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
            log_error "Cannot detect OS in non-interactive mode. Aborting."
            return 1
        fi
        
        log_warn "Unsupported OS detected. Please select package manager:"
        echo "1) pacman (Arch Linux / Manjaro)"
        echo "2) apt (Debian / Ubuntu)"
        echo "3) apk (Alpine Linux)" 
        echo "4) dnf/yum (Fedora / RHEL)"
        echo "5) Cancel"
        
        read -r "os_choice?Enter choice (1-5): "
        case "$os_choice" in
            1) os_type="arch" ;;
            2) os_type="debian" ;;
            3) os_type="alpine" ;;
            4) os_type="redhat" ;;
            *) log_error "Operation cancelled."; return 1 ;;
        esac
    fi
    
    log_info "Using package manager for: $os_type"
    
    #* --- Check for required privileges --- *#
    if ! sudo -n true 2>/dev/null; then
        log_warn "Root privileges required for package installation"
        local continue_install="y"
        if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
            continue_install="y"
            log_info "Non-interactive mode: continuing with sudo prompts"
        else
            read -r "continue_install?Continue and prompt for password when needed? (y/N): "
        fi
        [[ ! "$continue_install" =~ ^[Yy]$ ]] && { log_info "Operation cancelled."; return 0; }
    fi
    
    #* --- Update system repositories first --- *#
    log_info "Updating package repositories..."
    local update_success=true
    
    case "$os_type" in
        "arch")
            sudo pacman -Sy --noconfirm || update_success=false
            ;;
        "debian")
            sudo apt update || update_success=false
            ;;
        "alpine")
            sudo apk update || update_success=false
            ;;
        "redhat")
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf check-update || true  #* dnf check-update returns 100 if updates available
            else
                sudo yum check-update || true  #* yum check-update returns 100 if updates available
            fi
            ;;
    esac
    
    if [[ "$update_success" == false ]]; then
        log_error "Failed to update package repositories"
        local continue_anyway="n"
        if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
            continue_anyway="y"
            log_info "Non-interactive mode: continuing despite update failure"
        else
            read -r "continue_anyway?Continue anyway? (y/N): "
        fi
        [[ ! "$continue_anyway" =~ ^[Yy]$ ]] && return 1
    fi
    
    #* --- Install packages --- *#
    log_info "Installing ${#package_list[@]} packages..."
    local failed_packages=()
    local success_count=0
    
    for pkg in "${package_list[@]}"; do
        log_info "Installing: $pkg"
        local install_success=true
        
        case "$os_type" in
            "arch")
                sudo pacman -S --needed --noconfirm "$pkg" || install_success=false
                ;;
            "debian")
                sudo apt install -y "$pkg" || install_success=false
                ;;
            "alpine")
                sudo apk add "$pkg" || install_success=false
                ;;
            "redhat")
                if command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y "$pkg" || install_success=false
                else
                    sudo yum install -y "$pkg" || install_success=false
                fi
                ;;
        esac
        
        if [[ "$install_success" == true ]]; then
            log_ok "Successfully installed: $pkg"
            ((success_count++))
        else
            log_error "Failed to install: $pkg"
            failed_packages+=("$pkg")
        fi
    done
    
    #* --- Report results --- *#
    echo
    log_info "=== Installation Summary ==="
    log_ok "Successfully installed: $success_count/${#package_list[@]} packages"
    
    if (( ${#failed_packages[@]} > 0 )); then
        log_error "Failed packages: ${(j:, :)failed_packages}"
        log_info "You may want to install these manually or check package names"
    fi
    
    log_ok "System initiation completed."
    return 0
}

#! --- Git Repos --- !#
git_repos() {
    log_info "#! === Git Repository Cloner === !#"
    
    #* --- Get repository URLs --- *#
    local repos=""
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        log_warn "Non-interactive mode: no repository URLs provided. Skipping."
        return 0
    else
        read -r "repos?Enter your repo URLs (space-separated): "
    fi
    [[ -z "$repos" ]] && { log_warn "No URLs entered. Skipping."; return 1; }
    
    #* --- Get destination directory ---*#
    local dest=""
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        dest="$HOME/repositories"
        log_info "Non-interactive mode: using default destination $dest"
    else
        read -r "dest?Enter directory to clone repos into: "
    fi
    [[ -z "$dest" ]] && { log_warn "No destination entered. Skipping."; return 1; }
    
    #* --- Safely expand tilde and create directory --- *#
    dest="${dest/#\~/$HOME}"
    if ! mkdir -p "$dest" 2>/dev/null; then
        log_error "Cannot create directory: $dest"
        return 1
    fi
    
    #* --- Convert to absolute path for clarity --- *#
    dest="$(realpath "$dest" 2>/dev/null)" || dest="$(cd "$dest" && pwd)"
    log_info "Cloning repositories to: $dest"
    
    #* --- Parse URLs using zsh word splitting --- *#
    local url_array=()
    for url in ${(z)repos}; do
        #* --- Basic URL validation --- *#
        if [[ "$url" =~ ^https?:// ]] || [[ "$url" =~ ^git@ ]] || [[ "$url" =~ \.git$ ]]; then
            url_array+=("$url")
        else
            log_warn "Skipping invalid URL format: $url"
        fi
    done
    
    (( ${#url_array[@]} == 0 )) && { log_error "No valid URLs provided"; return 1; }
    
    #* --- Ask for confirmation --- *#
    local confirm="y"
    if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
        confirm="y"
        log_info "Non-interactive mode: proceeding with ${#url_array[@]} repositories"
    else
        log_info "Found ${#url_array[@]} valid repository URL(s)"
        read -r "confirm?Proceed with cloning? (y/N): "
    fi
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { log_info "Operation cancelled."; return 0; }
    
    echo
    
    #* --- Track background processes --- *#
    local pids=()
    local failed_repos=()
    local existing_repos=()
    local cloned_repos=()
    local updated_repos=()
    
    #* --- Create unique temp directory for this session --- *#
    local temp_dir="/tmp/git_ops_$$"
    mkdir -p "$temp_dir" || {
        log_error "Cannot create temp directory: $temp_dir"
        return 1
    }
    
    #* --- Process each repository --- *#
    for url in "${url_array[@]}"; do
        #* --- Extract repository name --- *#
        local repo_name=""
        
        # Handle different URL formats
        if [[ "$url" =~ ([^/]+)\.git$ ]]; then
            repo_name="${match[1]}"
        elif [[ "$url" =~ /([^/]+)/?$ ]]; then
            repo_name="${match[1]}"
        else
            # Fallback method
            repo_name="$(basename "$url")"
            repo_name="${repo_name%.git}"
        fi
        
        # Ensure we have a valid repo name
        [[ -z "$repo_name" ]] && repo_name="repo_$(date +%s)"
        
        local target="$dest/$repo_name"
        local result_file="$temp_dir/result_$repo_name"
        
        #* --- Check if repo already exists --- *#
        if [[ -d "$target/.git" ]]; then
            log_warn "Repository already exists: $repo_name"
            existing_repos+=("$repo_name")
            
            #* --- Ask if they want to pull updates --- *#
            local update="n"
            if [[ ${FORCE_YES:-false} == true ]] || [[ ${INTERACTIVE:-false} == false ]]; then
                update="y"
                log_info "Non-interactive mode: updating existing repository $repo_name"
            else
                read -r "update?Pull updates for $repo_name? (y/N): "
            fi
            
            if [[ "$update" =~ ^[Yy]$ ]]; then
                log_info "Updating $repo_name..."
                (
                    cd "$target" || { echo "UPDATE_FAILED:$repo_name" > "$result_file"; exit 1; }
                    if git fetch --all 2>/dev/null && git pull 2>/dev/null; then
                        echo "UPDATE_SUCCESS:$repo_name" > "$result_file"
                    else
                        echo "UPDATE_FAILED:$repo_name" > "$result_file"
                    fi
                ) &
                pids+=($!)
            fi
        else
            log_info "Cloning $repo_name from $url"
            #* --- Clone in background with error handling --- *#
            (
                if git clone "$url" "$target" 2>/dev/null; then
                    echo "CLONE_SUCCESS:$repo_name" > "$result_file"
                else
                    echo "CLONE_FAILED:$repo_name" > "$result_file"
                fi
            ) &
            pids+=($!)
        fi
        
        #* --- Limit concurrent processes to avoid overwhelming the system --- *#
        if (( ${#pids[@]} >= 5 )); then
            log_info "Waiting for current batch to complete..."
            wait "${pids[@]}"
            pids=()
        fi
    done
    
    #* --- Wait for all remaining background processes --- *#
    if (( ${#pids[@]} > 0 )); then
        log_info "Waiting for remaining operations to complete..."
        wait "${pids[@]}"
    fi
    
    #* --- Collect results from temporary files --- *#
    for result_file in "$temp_dir"/result_*; do
        [[ -f "$result_file" ]] || continue
        local result
        result=$(cat "$result_file" 2>/dev/null) || continue
        local status="${result%%:*}"
        local repo="${result##*:}"
        
        case "$status" in
            CLONE_SUCCESS)
                cloned_repos+=("$repo")
                ;;
            CLONE_FAILED)
                failed_repos+=("$repo")
                ;;
            UPDATE_SUCCESS)
                updated_repos+=("$repo")
                ;;
            UPDATE_FAILED)
                failed_repos+=("$repo")
                ;;
        esac
    done
    
    #* --- Cleanup temp directory --- *#
    rm -rf "$temp_dir" 2>/dev/null
    
    #* --- Report results --- *#
    echo
    log_info "=== Operation Summary ==="
    (( ${#cloned_repos[@]} > 0 )) && log_ok "Successfully cloned: ${(j:, :)cloned_repos}"
    (( ${#updated_repos[@]} > 0 )) && log_ok "Successfully updated: ${(j:, :)updated_repos}"
    (( ${#existing_repos[@]} > 0 )) && log_info "Already existed (skipped): ${(j:, :)existing_repos}"
    (( ${#failed_repos[@]} > 0 )) && log_error "Failed operations: ${(j:, :)failed_repos}"
    
    #* --- Final status --- *#
    local total_success=$(( ${#cloned_repos[@]} + ${#updated_repos[@]} ))
    local total_operations=$(( ${#url_array[@]} ))
    
    if (( ${#failed_repos[@]} > 0 )); then
        log_warn "Completed with ${#failed_repos[@]} failures out of $total_operations operations"
        return 1
    else
        log_ok "All git repository operations completed successfully."
        return 0
    fi
}

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

#! --- Main Loader --- !#
bootstrap() {
    #* --- Parse flags before the case statement --- *#
    FORCE_YES=false
    INTERACTIVE=false
    
    while [[ "$1" == -* ]]; do
        case "$1" in
            --force|-f) FORCE_YES=true; shift ;;
            --interactive|-i) INTERACTIVE=true; shift ;;
            --help|-h) 
                cat <<EOF
Usage: main [options] [command]

Options:
    -f, --force        Force yes to all prompts (non-interactive)
    -i, --interactive  Enable interactive mode
    -h, --help         Show this help message

Commands:
    setup              Run all components (init, repo, env) [default]
    init               Run system initialization only
    repo               Run git repository cloning only
    env                Run environment loading only

Examples:
    main                    # Run all components interactively
    main --force setup      # Run all components non-interactively
    main -i init            # Run only system init interactively
    main --force repo       # Run only repo cloning non-interactively
EOF
                return 0
                ;;
            --) shift; break ;;  # End of options
            -*) 
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done
    
    # Export variables so subfunctions can access them
    export FORCE_YES INTERACTIVE
    
    case "${1:-setup}" in
        setup|"") 
            log_info "Running complete setup: system initialization, git repos, and environment loading"
            system_inits && git_repos && load_envs
            ;;
        init) 
            log_info "Running system initialization only"
            system_inits
            ;;
        repo) 
            log_info "Running git repository operations only"
            git_repos
            ;;
        env) 
            log_info "Running environment loading only"
            load_envs
            ;;
        *) 
            echo "Error: Unknown command '$1'" >&2
            echo "Use 'main --help' for usage information" >&2
            return 1
            ;;
    esac
}
