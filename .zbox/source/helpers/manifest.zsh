#!/bin/zsh
#############################
# ZBOX Manifest Loader
# Load and process profile manifests
#############################

# Simple YAML parser for zBox manifests
# Extracts key-value pairs from YAML files
_zbox_parse_yaml() {
    local yaml_file="$1"
    local prefix="$2"

    if [[ ! -f "$yaml_file" ]]; then
        echo "ERROR: Manifest file not found: $yaml_file" >&2
        return 1
    fi

    # Simple YAML parser using awk
    # This handles basic key: value pairs and lists
    awk -v prefix="$prefix" '
        BEGIN { section = ""; indent = 0 }

        # Skip comments and empty lines
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }

        # Track sections
        /^[[:alpha:]_][[:alnum:]_]*:/ {
            section = $1
            gsub(/:/, "", section)
            next
        }

        # Handle indented key-value pairs
        /^[[:space:]]+[[:alpha:]_][[:alnum:]_]*:/ {
            key = $1
            gsub(/:/, "", key)
            gsub(/^[[:space:]]+/, "", key)
            value = $0
            sub(/^[[:space:]]+[[:alpha:]_][[:alnum:]_]*:[[:space:]]*/, "", value)
            gsub(/^"|"$/, "", value)
            if (value != "") {
                print prefix section "_" key "=\"" value "\""
            }
            next
        }

        # Handle list items
        /^[[:space:]]+- / {
            value = $0
            sub(/^[[:space:]]*- [[:space:]]*/, "", value)
            gsub(/^"|"$/, "", value)
            if (value != "") {
                print prefix section "_items+=(\"" value "\")"
            }
        }
    ' "$yaml_file"
}

# Load a manifest file
zbox_load_manifest() {
    local profile_name="${1:-workspace}"
    local manifest_file="${ZBOX_PROFILES}/${profile_name}/manifest.yaml"

    [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Loading manifest: $profile_name"

    if [[ ! -f "$manifest_file" ]]; then
        echo "ERROR: Manifest not found: $manifest_file" >&2
        return 1
    fi

    # Export current profile
    export ZBOX_CURRENT_PROFILE="$profile_name"
    export ZBOX_CURRENT_MANIFEST="$manifest_file"

    # Parse manifest into variables
    local manifest_vars
    manifest_vars="$(_zbox_parse_yaml "$manifest_file" "ZBOX_MANIFEST_")"

    if [[ -n "$manifest_vars" ]]; then
        eval "$manifest_vars"
    fi

    # Run activation hooks
    _zbox_manifest_activate

    [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Manifest loaded: $profile_name"
}

# Activate manifest (run hooks, set vars, create aliases)
_zbox_manifest_activate() {
    # Run on_activate hooks if they exist
    if [[ -n "$ZBOX_MANIFEST_hooks_items" ]]; then
        for hook in "${ZBOX_MANIFEST_hooks_items[@]}"; do
            if [[ "$hook" == *"on_activate"* ]]; then
                eval "$hook" 2>/dev/null || true
            fi
        done
    fi

    # Set environment variables from manifest
    # This would be expanded based on parsed YAML

    # Create aliases from manifest
    # This would be expanded based on parsed YAML
}

# List available profiles
zbox_list_profiles() {
    echo "Available ZBOX Profiles:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for profile_dir in "$ZBOX_PROFILES"/*; do
        if [[ -d "$profile_dir" ]]; then
            local profile_name="$(basename "$profile_dir")"
            local manifest="$profile_dir/manifest.yaml"

            if [[ -f "$manifest" ]]; then
                local description=$(grep "^  description:" "$manifest" | sed 's/.*: "\(.*\)"/\1/')
                local current=""
                [[ "$profile_name" == "$ZBOX_CURRENT_PROFILE" ]] && current=" (active)"

                echo "📦 $profile_name$current"
                [[ -n "$description" ]] && echo "   $description"
            else
                echo "📦 $profile_name (no manifest)"
            fi
        fi
    done
}

# Switch to a different profile
zbox_switch_profile() {
    local new_profile="$1"

    if [[ -z "$new_profile" ]]; then
        echo "Usage: zbox_switch_profile <profile_name>"
        echo ""
        zbox_list_profiles
        return 1
    fi

    if [[ ! -d "$ZBOX_PROFILES/$new_profile" ]]; then
        echo "ERROR: Profile not found: $new_profile" >&2
        return 1
    fi

    # Deactivate current profile
    if [[ -n "$ZBOX_CURRENT_PROFILE" ]]; then
        [[ -n "$ZBOX_DEBUG" ]] && echo "[ZBOX] Deactivating profile: $ZBOX_CURRENT_PROFILE"
        # Run deactivation hooks here
    fi

    # Load new profile
    zbox_load_manifest "$new_profile"

    echo "✓ Switched to profile: $new_profile"
}

# Show current profile info
zbox_profile_info() {
    if [[ -z "$ZBOX_CURRENT_PROFILE" ]]; then
        echo "No profile currently loaded"
        return 1
    fi

    echo "Current Profile: $ZBOX_CURRENT_PROFILE"
    echo "Manifest: $ZBOX_CURRENT_MANIFEST"
    echo ""

    if [[ -f "$ZBOX_CURRENT_MANIFEST" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$ZBOX_CURRENT_MANIFEST"
    fi
}

# Aliases for convenience
alias zbox-profiles='zbox_list_profiles'
alias zbox-profile='zbox_profile_info'
alias zbox-switch='zbox_switch_profile'
