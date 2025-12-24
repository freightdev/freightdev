#############################
# Master Config Loader
#############################

# Define the directories to search.
typeset -a config_dirs=(
    'defaults'
    'settings'
)

# Iterate through the directories and source files.
for dir in "${config_dirs[@]}"; do
    dirpath="$ZBOX_CFG/$dir"
    if [[ -d "$dirpath" ]]; then
        for file in "$dirpath"/*.{zsh,sh}(N); do
            if [[ -f "$file" && -r "$file" ]]; then
                source "$file"
            fi
        done
    fi
done

#############################
# Symlink Management
#############################

# Function to create symlink safely
create_symlink() {
    local source="$1"
    local target="$2"

    # Create parent directory if it doesn't exist
    local target_dir="$(dirname "$target")"
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # If target exists and is a symlink pointing to the correct source, skip
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi

    # If target exists but is not the correct symlink, remove it
    if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
    fi

    # Create the symlink
    ln -sf "$source" "$target"
}

# Symlink dotfiles from config/symlinks/dotfiles/.* to ~/*
if [[ -d "$ZBOX_CFG/symlinks/dotfiles" ]]; then
    for file in "$ZBOX_CFG/symlinks/dotfiles"/.[^.]*; do
        if [[ -e "$file" ]]; then
            filename="$(basename "$file")"
            create_symlink "$file" "$HOME/$filename"
        fi
    done
fi

# Symlink dotdirs from config/symlinks/dotdirs/.config/* to ~/.config/*
if [[ -d "$ZBOX_CFG/symlinks/dotdirs/.config" ]]; then
    for item in "$ZBOX_CFG/symlinks/dotdirs/.config"/*; do
        if [[ -e "$item" ]]; then
            itemname="$(basename "$item")"
            create_symlink "$item" "$HOME/.config/$itemname"
        fi
    done
fi
