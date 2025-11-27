#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝


#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- System Initiation --- !#
system_init() {
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