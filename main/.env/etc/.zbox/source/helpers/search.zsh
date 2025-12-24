#!  ╔═══════════════════════════════════════════╗
#?    Search Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Find files by name
fd_file() {
    if [[ -z $1 ]]; then
        echo "Usage: ff <filename_pattern> [directory]"
        return 1
    fi

    local target_dir="${2:-.}"  # Default to current directory
    fd . -type f -name "*$1*" "$target_dir" 2>/dev/null
}


# Find directories by name
fd_dir() {
    if [[ -z $1 ]]; then
        echo "Usage: fd_dir <directory_name_pattern> [search_directory]"
        return 1
    fi

    local target_dir="${2:-.}"  # Default to current directory
    fd . -type d -name "*$1*" "$target_dir" 2>/dev/null
}


# Find large files
fsize() {
    local size="${1:-100M}"      # Default size 100M
    local target_dir="${2:-.}"    # Default current directory

    if ! [[ $size =~ ^[0-9]+[KMG]?$ ]]; then
        echo "Usage: fsize <size> [directory]"
        echo "Example: fsize 500M /home/user"
        return 1
    fi

    fd . -type f -size +"$size" "$target_dir" -exec ls -lh {} \; 2>/dev/null | awk '{ print $NF ": " $5 }'
}


