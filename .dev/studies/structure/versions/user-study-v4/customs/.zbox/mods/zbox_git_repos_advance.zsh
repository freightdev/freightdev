#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝


#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


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