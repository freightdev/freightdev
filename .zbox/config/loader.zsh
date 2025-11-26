#############################
# Master Config Loader
#############################

# 1. Define the directories to search.
# This list specifies the order in which modules will be loaded.
typeset -a config_dirs=(
    'defaults'
    'settings'
)

# 2. Check for the existence of the config root directory.
if [[ ! -d "$ZBOX_CFG" ]]; then
    echo "WARNING: Environment Config Directory not found at $ZBOX_CFG. Skipping source loading." >&2
    return 0
fi

# 3. Iterate through the directories and source files.
for dir in "${config_dirs[@]}"; do
    dirpath="$ZBOX_CFG/$dir"
    
    # Check if the subdirectory exists.
    if [[ -d "$dirpath" ]]; then
        
        # Glob the files. (N) is the NULL_GLOB option, preventing an error
        # We explicitly check for both .zsh and .sh extensions.
        for file in "$dirpath"/*.{zsh,sh}(N); do
            
            # Use read-only check for robustness, though (N) helps prevent errors.
            if [[ -f "$file" && -r "$file" ]]; then
                
                # Source the file in the current shell context.
                source "$file"
                
                # Optional: Add debugging line for complex environments:
                # echo "Sourced: $file"
            fi
        done
    fi
done

# 4. Cleanup (optional)
# Unset the temporary array used only by this script to keep the environment clean.
unset config_dirs

# Note: The 'source' command is an alias for '.', and both are often interchangeable in Zsh.
