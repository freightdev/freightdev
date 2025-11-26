#############################
# Master Source Loader
# Loads all modular Zsh scripts (agents, helpers, suites)
# from the defined $ZBOX_SRC directory.
#############################

# 1. Define the directories to search.
# This list specifies the order in which modules will be loaded.
typeset -a source_dirs=(
    'agents'
    'helpers'
    'suites'
)

# 2. Check for the existence of the source root directory.
# This relies on $ZBOX_SRC being exported by config/loader.zsh.
if [[ ! -d "$ZBOX_SRC" ]]; then
    echo "WARNING: Environment Source Directory not found at $ZBOX_SRC. Skipping source loading." >&2
    return 0 # Exit cleanly if the directory isn't there (e.g., initial setup).
fi

# 3. Iterate through the directories and source files.
for dir in "${source_dirs[@]}"; do
    dirpath="$ZBOX_SRC/$dir"
    
    # Check if the subdirectory exists.
    if [[ -d "$dirpath" ]]; then
        
        # Glob the files. (N) is the NULL_GLOB option, preventing an error
        # if no files are found (i.e., if 'utils/*.{zsh,sh}' matches nothing).
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
unset source_dirs

# Note: The 'source' command is an alias for '.', and both are often interchangeable in Zsh.
