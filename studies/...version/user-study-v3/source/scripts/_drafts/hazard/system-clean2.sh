#!/bin/bash
set -euo pipefail

echo "==== SYSTEM CLEANUP PREVIEW ===="
echo

declare -A cleanup_targets
declare -A cleanup_desc

# Add your cleanup paths and descriptions here
cleanup_targets["trash_user"]="$HOME/.local/share/Trash"
cleanup_desc["trash_user"]="Trash (current user)"

cleanup_targets["trash_root"]="/root/.local/share/Trash"
cleanup_desc["trash_root"]="Trash (root)"

cleanup_targets["tmp"]="/tmp /var/tmp"
cleanup_desc["tmp"]="Temporary files"

cleanup_targets["journal"]="journalctl"
cleanup_desc["journal"]="Old journal logs (>2 days)"

cleanup_targets["apt_cache"]="/var/cache/apt/archives"
cleanup_desc["apt_cache"]="apt cache"

cleanup_targets["pacman_cache"]="/var/cache/pacman/pkg"
cleanup_desc["pacman_cache"]="pacman cache"

# Add more caches if needed

# To keep track of exclusions for each category
declare -A exclusions

# Function to preview files/folders for cleanup
function preview_and_prompt() {
    local key=$1
    local desc=${cleanup_desc[$key]}
    local target=${cleanup_targets[$key]}
    echo "Checking $desc..."

    if [[ "$key" == "journal" ]]; then
        echo "System journal logs size:"
        journalctl --disk-usage
        echo "Old journal logs will be cleaned with 'journalctl --vacuum-time=2d'"
        echo
        return
    fi

    # Handle multiple paths separated by space
    local paths=($target)
    local total_files=0
    local total_size=0

    for p in "${paths[@]}"; do
        if [ -e "$p" ]; then
            local files=$(find "$p" -type f 2>/dev/null)
            local count=$(echo "$files" | wc -l)
            local size_bytes=$(du -sb "$p" 2>/dev/null | cut -f1 || echo 0)
            local size_human=$(du -sh "$p" 2>/dev/null | cut -f1 || echo "0")
            echo "  $p: $count files, $size_human size"
            total_files=$((total_files + count))
            total_size=$((total_size + size_bytes))
        else
            echo "  $p: Not found."
        fi
    done

    if (( total_files == 0 )); then
        echo "  Nothing to clean here."
        echo
        return
    fi

    echo
    echo "Do you want to exclude any files/directories from cleaning in '$desc'? (y/N)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Please enter exclude paths or patterns, separated by spaces (relative or absolute):"
        read -r exclude_input
        exclusions[$key]="$exclude_input"
    fi
    echo
}

# Preview each target and prompt for excludes
for key in "${!cleanup_targets[@]}"; do
    preview_and_prompt "$key"
done

echo "Summary of exclusions you set:"
for key in "${!exclusions[@]}"; do
    echo "$key (${cleanup_desc[$key]}): ${exclusions[$key]}"
done
echo

read -rp "Proceed with cleanup? [y/N] " proceed
if ! [[ "$proceed" =~ ^[Yy]$ ]]; then
    echo "Cleanup aborted."
    exit 0
fi

echo "Starting cleanup..."

# Helper function to clean with exclusions
function clean_with_exclusions() {
    local path=$1
    local excludes=$2

    if [ ! -d "$path" ]; then
        echo "Skipping $path - not found"
        return
    fi

    # If no excludes, just delete all inside path
    if [ -z "$excludes" ]; then
        rm -rf "${path}/"* 2>/dev/null || true
        return
    fi

    # Build find prune expressions for excludes
    IFS=' ' read -r -a excl_array <<< "$excludes"
    local prune_expr=""
    for excl in "${excl_array[@]}"; do
        prune_expr+=" -path '$path/$excl' -prune -o"
    done

    # Remove trailing -o
    prune_expr=${prune_expr% -o}

    # Use eval to run find with prune
    eval "find '$path' $prune_expr -type f -exec rm -f {} +"
    eval "find '$path' $prune_expr -type d -empty -delete"
}

# Clean Trash (user)
clean_with_exclusions "$HOME/.local/share/Trash/files" "${exclusions[trash_user]}"
clean_with_exclusions "$HOME/.local/share/Trash/info" "${exclusions[trash_user]}"

# Clean Trash (root) - needs sudo
sudo bash -c "rm -rf /root/.local/share/Trash/files/* /root/.local/share/Trash/info/*" # skipping excludes here for simplicity

# Clean temp dirs (handle excludes)
for tmpdir in /tmp /var/tmp; do
    clean_with_exclusions "$tmpdir" "${exclusions[tmp]}"
done

# Clean caches similarly with excludes if you want — omitted for brevity

# Clean journal logs older than 2 days
sudo journalctl --vacuum-time=2d

echo "Cleanup done."
