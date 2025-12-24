#############################
# Master Source Loader
#############################

# Define the directories to search.
typeset -a source_dirs=(
    'agents'
    'helpers'
    'suites'
)

# Iterate through the directories and source files.
for dir in "${source_dirs[@]}"; do
    dirpath="$ZBOX_SRC/$dir"

    if [[ -d "$dirpath" ]]; then
        for file in "$dirpath"/*.{zsh,sh}(N); do
            if [[ -f "$file" && -r "$file" ]]; then
                source "$file"
            fi
        done
    fi
done
