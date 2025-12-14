#!  ╔═══════════════════════════════════════════╗
#?    Viewing Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

fnviewer() {
    [[ ! -d "$ENV_DIR" ]] && { log_error "Directory not found: $ENV_DIR"; return }
    local category

    echo "${colors[cyan]}Select category to view:${colors[reset]}"
    select category in helpers configs; do
        case $category in
            helpers)
                echo "${colors[green]}=== Helpers ===${colors[reset]}"
                for file in $(fd -e zsh . "$ENV_DIR/helpers"); do
                    echo "${colors[yellow]}File: $(basename $file)${colors[reset]}"
                    
                    #* Extract each helper with preceding comment block
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
            configs)
                echo "${colors[green]}=== Configs ===${colors[reset]}"
                for file in $(fd -e zsh . "$ENV_DIR/configs"); do
                    echo "${colors[yellow]}File: $(basename $file)${colors[reset]}"
                    
                    #* Extract config with preceding comment
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                    /^#/ { comment = comment $0 "\n"; next }
                    /^config / {
                        printf "%s%s%s", magenta, comment, reset
                        print blue $0 reset
                        comment=""
                    }
                    ' "$file"
                    echo ""
                done
                ;;
            *)
                echo "${colors[red]}Invalid selection.${colors[reset]}"
                ;;
        esac
    done
}