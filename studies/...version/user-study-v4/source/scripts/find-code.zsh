#!/bin/zsh
# ========================================
# find_code.sh
# Recursively search for any text or code in a directory
# Usage: ./find_code.sh <directory> "<pattern>"
# Example: ./find_code.sh ~/Workspace "my_variable"
# ========================================

search_dir="$1"
pattern="$2"

if [[ -z "$search_dir" || -z "$pattern" ]]; then
    echo "Usage: $0 <directory> \"<pattern>\""
    exit 1
fi

if [[ ! -d "$search_dir" ]]; then
    echo "Error: Directory '$search_dir' does not exist."
    exit 1
fi

# Search recursively
grep -RnH --color=always "$pattern" "$search_dir" 2>/dev/null | while IFS=: read -r file line_number line_content; do
    # Find column of first match
    col_number=$(awk -v pat="$pattern" '{
        match($0, pat)
        if (RSTART) print RSTART
        else print "-"
    }' <<< "$line_content")
    
    echo "File: $file"
    echo "Line: $line_number"
    echo "Column: $col_number"
    echo "Content: $line_content"
    echo "--------------------------------------"
done
