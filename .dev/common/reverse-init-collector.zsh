#!/usr/bin/env zsh
##################################
# Freightdev Reverse Init Collector
# Scans repo and packages files based on config
##################################

setopt err_exit
setopt no_unset
setopt extended_glob
setopt nullglob

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly COLLECTOR_VERSION="1.0.0"
readonly DEFAULT_CONFIG="$SCRIPT_DIR/collector.conf"
readonly DEFAULT_OUTPUT="$SCRIPT_DIR/freightdev-init.tar.gz"

# Runtime Variables
: "${MY_HOME:=$HOME/main}"
typeset -A collected_files
typeset -a collection_errors
typeset -gi files_collected=0

# Logging Functions
log_info() { printf "\033[34m[INFO]\033[0m %s\n" "$*" >&2; }
log_warn() { printf "\033[33m[WARN]\033[0m %s\n" "$*" >&2; }
log_error() { printf "\033[31m[ERROR]\033[0m %s\n" "$*" >&2; }
log_ok() { printf "\033[32m[OK]\033[0m %s\n" "$*" >&2; }

# Parse collector configuration file
parse_collection_config() {
    local config_file="${1:-$DEFAULT_CONFIG}"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Parsing collection config: $config_file"

    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ `^[[:space:]]*#` ]] && continue

        # Remove inline comments and trim whitespace
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        # Parse line format: source_path:destination_path or just source_path
        if [[ "$line" == *:* ]]; then
            local source_path="${line%:*}"
            local dest_path="${line#*:}"
        else
            local source_path="$line"
            local dest_path="$line"
        fi

        # Validate source path exists
        local full_source_path="$MY_HOME/$source_path"
        if [[ ! -e "$full_source_path" ]]; then
            log_warn "Line $line_num: Source not found - $source_path"
            collection_errors+=("Line $line_num: $source_path not found")
            continue
        fi

        collected_files[$full_source_path]="$dest_path"
        log_info "Mapped: $source_path -> $dest_path"

    done < "$config_file"

    local mapped_count=${#collected_files[@]}
    log_ok "Configuration parsed: $mapped_count items mapped"

    if (( ${#collection_errors[@]} > 0 )); then
        log_warn "Configuration issues found:"
        printf "  %s\n" "${collection_errors[@]}"
    fi

    return 0
}

# Create temporary staging area and collect files
stage_collected_files() {
    local staging_dir="/tmp/freightdev-collector-$$"

    log_info "Creating staging area: $staging_dir"
    mkdir -p "$staging_dir" || {
        log_error "Cannot create staging directory: $staging_dir"
        return 1
    }

    # Ensure cleanup on exit
    trap "rm -rf '$staging_dir' 2>/dev/null" EXIT

    log_info "Staging ${#collected_files[@]} items..."

    for source_path dest_path in "${(@kv)collected_files}"; do
        local target_path="$staging_dir/$dest_path"
        local target_dir="${target_path%/*}"

        # Create target directory structure
        mkdir -p "$target_dir" || {
            log_error "Cannot create target directory: $target_dir"
            continue
        }

        # Copy file or directory
        if [[ -d "$source_path" ]]; then
            log_info "Copying directory: ${source_path/#$MY_HOME/}"
            cp -r "$source_path" "$target_path" || {
                log_error "Failed to copy directory: $source_path"
                continue
            }
        elif [[ -f "$source_path" ]]; then
            log_info "Copying file: ${source_path/#$MY_HOME/}"
            cp "$source_path" "$target_path" || {
                log_error "Failed to copy file: $source_path"
                continue
            }
        fi

        ((files_collected++))
    done

    log_ok "Staged $files_collected items"
    echo "$staging_dir"  # Return staging directory path
    return 0
}

# Create deployment manifest
create_deployment_manifest() {
    local staging_dir="$1"
    local manifest_file="$staging_dir/DEPLOYMENT_MANIFEST"

    log_info "Creating deployment manifest"

    cat > "$manifest_file" << EOF
# Freightdev Deployment Manifest
# Generated: $(date -Iseconds)
# Collector Version: $COLLECTOR_VERSION
# Source: $MY_HOME
# Files Collected: $files_collected

# File Mappings (source:destination)
EOF

    for source_path dest_path in "${(@kv)collected_files}"; do
        local relative_source="${source_path/#$MY_HOME/}"
        echo "$relative_source:$dest_path" >> "$manifest_file"
    done

    log_ok "Manifest created: DEPLOYMENT_MANIFEST"
}

# Package staged files into tarball
package_collection() {
    local staging_dir="$1"
    local output_file="${2:-$DEFAULT_OUTPUT}"

    log_info "Packaging collection to: $output_file"

    # Change to staging directory for clean archive paths
    cd "$staging_dir"

    # Create compressed archive
    tar -czf "$output_file" . || {
        log_error "Failed to create package: $output_file"
        return 1
    }

    # Get package info
    local package_size
    package_size=$(du -h "$output_file" | cut -f1)

    log_ok "Package created: $output_file ($package_size)"
    return 0
}

# Generate default configuration file
generate_default_config() {
    local config_file="${1:-$DEFAULT_CONFIG}"

    if [[ -f "$config_file" ]]; then
        log_warn "Configuration file already exists: $config_file"
        local overwrite="n"
        read -r "overwrite?Overwrite existing config? (y/N): "
        [[ ! "$overwrite" =~ ^[Yy]$ ]] && return 1
    fi

    log_info "Generating default configuration: $config_file"

    cat > "$config_file" << 'EOF'
# Freightdev Collection Configuration
# Format: source_path[:destination_path]
# Lines starting with # are comments
# Empty lines are ignored

# Collect files
main/containers:main/containers
main/devtools:main/devtools
main/environments:main/environments
main/packages:main/packages
main/projects:main/projects
main/resources:main/resources
EOF

    log_ok "Default configuration generated"
    log_info "Edit $config_file to customize collection"
    return 0
}

# Display usage information
show_usage() {
    cat << EOF
Freightdev Reverse Init Collector v$COLLECTOR_VERSION

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -c, --config FILE     Collection configuration file (default: $DEFAULT_CONFIG)
    -o, --output FILE     Output package file (default: $DEFAULT_OUTPUT)
    -g, --generate        Generate default configuration file
    -h, --help           Show this help message

EXAMPLES:
    $0                           # Use default config and output
    $0 -c custom.conf -o init.tar.gz
    $0 --generate               # Create default config file
    $0 -g -c my-config.conf     # Generate config with custom name

CONFIGURATION FORMAT:
    Each line specifies a file or directory to collect:

    source_path                 # Copy to same relative path
    source_path:dest_path       # Copy to different destination

    Paths are relative to MY_HOME ($MY_HOME)
EOF
}

# Main execution function
main() {
    local config_file="$DEFAULT_CONFIG"
    local output_file="$DEFAULT_OUTPUT"
    local generate_config=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -g|--generate)
                generate_config=true
                shift
                ;;
            -h|--help)
                show_usage
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                return 1
                ;;
        esac
    done

    log_info "Freightdev Reverse Init Collector v$COLLECTOR_VERSION"
    log_info "Source directory: $MY_HOME"

    # Generate configuration if requested
    if [[ "$generate_config" == true ]]; then
        generate_default_config "$config_file" || return 1
        [[ $# -eq 1 ]] && return 0  # Exit if only generating config
    fi

    # Verify source directory exists
    if [[ ! -d "$MY_HOME" ]]; then
        log_error "Source directory not found: $MY_HOME"
        log_info "Set MY_HOME environment variable or ensure directory exists"
        return 1
    fi

    # Parse collection configuration
    parse_collection_config "$config_file" || return 1

    if (( ${#collected_files[@]} == 0 )); then
        log_error "No files to collect"
        return 1
    fi

    # Stage files for packaging
    local staging_dir
    staging_dir=$(stage_collected_files) || return 1

    # Create deployment manifest
    create_deployment_manifest "$staging_dir" || return 1

    # Package everything
    package_collection "$staging_dir" "$output_file" || return 1

    log_ok "Collection complete: $files_collected files packaged"
    log_info "Deploy with: tar -xzf $output_file"

    return 0
}

# Execute main function with all arguments
main "$@"
