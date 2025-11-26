#!  ╔═════════════════════════════════════════════╗
#?    Viewer Functions - Environment Source (Zsh)  
#!  ╚═════════════════════════════════════════════╝

# Function Viewer (viewer function)
fnviewer() {
    read -r "ENV_DIR?Enter the path to your environments directory: "
    [[ ! -d "$ENV_DIR" ]] && { log_error "Directory not found: $ENV_DIR"; return }
    local ZSH_DIR="$HOME/.zshrc.d"
    local category

    echo "${colors[cyan]}Select category to view:${colors[reset]}"
    select category in functions aliases configs quit; do
        case $category in
            functions)
                echo "${colors[green]}=== Functions ===${colors[reset]}"
                for file in $(fd -e zsh . "$ZSH_DIR/functions"); do
                    echo "${colors[yellow]}File: $(basename $file)${colors[reset]}"
                    # Extract each function with preceding comment block
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                    /^#/ { comment = comment $0 "\n"; next }
                    /^[a-zA-Z0-9_]+\(\)/ {
                        printf "%s%s%s", magenta, comment, reset
                        print blue $0 reset
                        comment=""
                    }
                    ' "$file"
                    echo ""
                done
                ;;
            aliases)
                echo "${colors[green]}=== Aliases ===${colors[reset]}"
                for file in $(fd -e zsh . "$ZSH_DIR/aliases"); do
                    echo "${colors[yellow]}File: $(basename $file)${colors[reset]}"
                    # Extract alias with preceding comment
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                    /^#/ { comment = comment $0 "\n"; next }
                    /^alias / {
                        printf "%s%s%s", magenta, comment, reset
                        print blue $0 reset
                        comment=""
                    }
                    ' "$file"
                    echo ""
                done
                ;;
            settings)
                echo "${colors[green]}=== Setting Files ===${colors[reset]}"
                for file in $(fd -e zsh . "$ZSH_DIR/configs"); do
                    echo "${colors[magenta]}Config: $(basename $file)${colors[reset]}"
                done
                ;;
            quit)
                break
                ;;
            *)
                echo "${colors[red]}Invalid selection.${colors[reset]}"
                ;;
        esac
    done
}