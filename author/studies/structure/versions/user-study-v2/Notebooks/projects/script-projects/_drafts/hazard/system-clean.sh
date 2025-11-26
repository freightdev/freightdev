#!/bin/bash
set -euo pipefail

echo "==== SYSTEM CLEANUP PREVIEW ===="
echo

declare -A cleanup_targets
declare -A cleanup_desc

cleanup_targets["trash_user"]="$HOME/.local/share/Trash/files $HOME/.local/share/Trash/info"
cleanup_desc["trash_user"]="Trash (current user)"

cleanup_targets["trash_root"]="/root/.local/share/Trash/files /root/.local/share/Trash/info"
cleanup_desc["trash_root"]="Trash (root)"

cleanup_targets["tmp"]="/tmp /var/tmp"
cleanup_desc["tmp"]="Temporary files"

cleanup_targets["journal"]="journalctl"
cleanup_desc["journal"]="Old journal logs (>2 days)"

# Function to list files to delete
function list_files() {
    local key=$1
    local target_paths=${cleanup_targets[$key]}
    local desc=${cleanup_desc[$key]}
    echo "===== $desc ====="
    if [[ "$key" == "journal" ]]; then
        echo "System journal logs size:"
        journalctl --disk-usage
        echo "Old journal logs (older than 2 days) will be deleted."
        echo
        return
    fi

    for path in $target_paths; do
        if [ -e "$path" ]; then
            echo "Files/folders under: $path"
            find "$path" -mindepth 1 -print 2>/dev/null || echo "(No files found)"
        else
            echo "$path does not exist."
        fi
    done
    echo
}

# Function to clean with excludes
function clean_with_exclusions() {
    local key=$1
    local excludes_var=$2
    local target_paths=${cleanup_targets[$key]}
    local desc=${cleanup_desc[$key]}

    echo "Cleaning $desc..."

    for path in $target_paths; do
        if [ ! -d "$path" ]; then
            echo "Skipping $path - not found"
            continue
        fi

        if [ -z "${!excludes_var}" ]; then
            # No excludes - remove all inside
            rm -rf "${path}/"* 2>/dev/null || true
        else
            # Build find prune expression from excludes
            local excl_list=(${!excludes_var})
            local prune_expr=""
            for excl in "${excl_list[@]}"; do
                prune_expr+=" -path '${path}/${excl}' -prune -o"
            done
            prune_expr=${prune_expr% -o}

            # Use eval to run find with prune
            eval "find '$path' $prune_expr -mindepth 1 -exec rm -rf {} +"
        fi
    done
}

# Step 1: List all files/folders that would be deleted
for key in "${!cleanup_targets[@]}"; do
    list_files "$key"
done

echo "==== Exclusion prompt ===="
echo "For each category, enter space-separated files/folders to exclude from deletion."
echo "If nothing to exclude, just press Enter."

declare -A excludes

for key in "${!cleanup_targets[@]}"; do
    read -rp "Exclude from '${cleanup_desc[$key]}'? " input
    excludes[$key]="$input"
done

echo
echo "Exclusions summary:"
for key in "${!excludes[@]}"; do
    echo "${cleanup_desc[$key]}: ${excludes[$key]}"
done

read -rp "Proceed with cleanup? [y/N]: " confirm
if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Cleaning up..."

# Trash root requires sudo
if [ -d "/root/.local/share/Trash" ]; then
    echo "Cleaning root trash (no excludes)..."
    sudo rm -rf /root/.local/share/Trash/files/* /root/.local/share/Trash/info/* || true
fi

# Clean other targets with excludes
for key in "${!cleanup_targets[@]}"; do
    if [[ "$key" != "trash_root" && "$key" != "journal" ]]; then
        clean_with_exclusions "$key" excludes[$key]
    fi
done

# Vacuum journal logs older than 2 days (no excludes supported)
echo "Cleaning journal logs older than 2 days..."
sudo journalctl --vacuum-time=2d

echo "Cleanup complete."
