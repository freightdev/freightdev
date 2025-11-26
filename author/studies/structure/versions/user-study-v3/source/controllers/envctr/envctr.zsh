#!/usr/bin/env zsh
#! ╔═══════════════════════════════╗
#!   zenvctr (zsh-plugin)- v1.0.0 
#! ╚═══════════════════════════════╝

set -euo pipefail

# Defaults (override by loading custom env if needed)
: "${ENV_DIR:=$HOME/.zshrc.d}"
: "${ENV_SRC_BACKUP:=$ENV_DIR/backups}"
: "${EDITOR:=nano}"

# Environment Controller (name)
ENVCTR="zenvctr"

# Environment Controller (usage)
usage() {
    cat <<EOF
Usage: $ENVCTR <commands> [args]

Core:
    add <name>               Create new script
    edit <name>              Edit existing script
    print <name>             View contents of script (with bat or cat)
    delete <name>            Delete a script
    rename <old> <new>       Rename a script 

Management:
    lru                      List recent usage
    audit                    Check scripts for syntax errors

Helper:
    list [category]          List scripts (all, or by category like functions, aliases)
    view <category> [name]   View scripts by category with syntax highlighting
    source <source>          Reload environment source
    backup                   Backup all scripts (to $ENV_SRC_BACKUP-$TS)
    search <term>            Search for a keyword inside scripts

Examples:
    $ENVCTR add aliases
    $ENVCTR edit exports
    $ENVCTR print paths
    $ENVCTR delete exports
    $ENVCTR rename plugs plugins
    $ENVCTR list functions
    $ENVCTR view aliases
    $ENVCTR view functions my-func
EOF
    exit 1
}

normalize() {
    echo "${1%.zsh}.zsh"
}

# Check if required argument exists
[[ -z "$1" ]] && usage

# Environment Controller (commands)
case "$1" in

    #* === Core === *#
    add)
        [[ -z "$2" ]] && usage
        NAME=$(normalize "$2")
        FILE="$ENV_DIR/$NAME"
        [[ -f "$FILE" ]] && { echo "'$NAME' already exists."; exit 1; }
        mkdir -p "$(dirname "$FILE")" 
        echo "# $NAME" > "$FILE"
        "$EDITOR" "$FILE"
        ;;

    edit)
        [[ -z "$2" ]] && usage
        NAME=$(normalize "$2")
        FILE="$ENV_DIR/$NAME"
        [[ ! -f "$FILE" ]] && { echo "'$NAME' not found."; exit 1; }
        touch -a "$FILE"
        "$EDITOR" "$FILE"
        ;;

    print)
        [[ -z "$2" ]] && usage
        NAME=$(normalize "$2")
        FILE="$ENV_DIR/$NAME"
        [[ ! -f "$FILE" ]] && { echo "'$NAME' not found."; exit 1; }
        echo "Contents of '$NAME':"
        if command -v bat >/dev/null 2>&1; then
            bat --style=plain --paging=never "$FILE"
        else
            cat "$FILE"
        fi
        ;;

    delete)
        [[ -z "$2" ]] && usage
        NAME=$(normalize "$2")
        FILE="$ENV_DIR/$NAME"
        [[ ! -f "$FILE" ]] && { echo "'$NAME' not found."; exit 1; }
        read -p "Delete '$NAME'? (y/N): " CONFIRM
        [[ "$CONFIRM" == [yY] ]] && rm "$FILE" && echo "Deleted '$NAME'"
        ;;

    rename)
        [[ -z "$2" || -z "$3" ]] && usage
        OLD=$(normalize "$2")
        NEW=$(normalize "$3")
        OLD_FILE="$ENV_DIR/$OLD"
        NEW_FILE="$ENV_DIR/$NEW"
        [[ ! -f "$OLD_FILE" ]] && { echo "'$OLD' not found."; exit 1; }
        [[ -f "$NEW_FILE" ]] && { echo "'$NEW' already exists."; exit 1; }
        mv "$OLD_FILE" "$NEW_FILE"
        echo "Renamed '$OLD' → '$NEW'"
        ;;

    #* === Management === *#
    lru)
        echo "Scripts by Last Access:"
        if [[ -d "$ENV_DIR" ]]; then
            find "$ENV_DIR" -type f -name '*.zsh' -exec stat -c "%X %n" {} + 2>/dev/null |
                sort -nr | head -10 | while read -r timestamp file; do
                    echo "$(date -d @$timestamp '+%Y-%m-%d %H:%M:%S') $file"
                done
        else
            echo "Directory $ENV_DIR not found."
        fi
        ;;

    audit)
        echo "Checking syntax:"
        if [[ -d "$ENV_DIR" ]]; then
            find "$ENV_DIR" -type f -name '*.zsh' | while read -r file; do
                if [[ -r "$file" ]]; then
                    echo -n "$(basename "$file") ... "
                    if zsh -n "$file" 2>/dev/null; then 
                        echo "OK"; 
                    else 
                        echo "ERROR"; 
                    fi
                fi
            done
        else
            echo "Directory $ENV_DIR not found."
        fi
        ;;

    #* === Helper === *#
    list)
        local category="$2"
        if [[ -z "$category" ]]; then
            echo "Listing all $ENV_DIR scripts:"
            if [[ -d "$ENV_DIR" ]]; then
                find "$ENV_DIR" -type f -name '*.zsh' | sort
            else
                echo "Directory $ENV_DIR not found."
            fi
        else
            local target_dir="$ENV_DIR/$category"
            if [[ -d "$target_dir" ]]; then
                echo "Listing scripts in $category:"
                find "$target_dir" -type f -name '*.zsh' | sort | while read -r file; do
                    local basename=$(basename "$file" .zsh)
                    local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                    printf "  %-20s (%s lines)\n" "$basename" "$lines"
                done
            else
                echo "Category directory not found: $target_dir"
                echo "Available categories:"
                if [[ -d "$ENV_DIR" ]]; then
                    find "$ENV_DIR" -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
                        echo "  - $(basename "$dir")"
                    done
                fi
            fi
        fi
        ;;

    view)
        [[ -z "$2" ]] && { echo "Usage: $ENVCTR view <category> [script_name]"; echo "Categories: functions, aliases, configs, exports, etc."; exit 1; }
        
        local category="$2"
        local script_name="$3"
        local target_dir="$ENV_DIR/$category"
        
        # Define colors for syntax highlighting
        typeset -A colors
        colors[reset]="\033[0m"
        colors[green]="\033[32m"
        colors[yellow]="\033[33m"
        colors[blue]="\033[34m"
        colors[magenta]="\033[35m"
        colors[cyan]="\033[36m"
        
        if [[ ! -d "$target_dir" ]]; then
            echo "Category directory not found: $target_dir"
            echo "Available categories:"
            if [[ -d "$ENV_DIR" ]]; then
                find "$ENV_DIR" -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
                    echo "  - $(basename "$dir")"
                done
            fi
            exit 1
        fi
        
        # If specific script requested
        if [[ -n "$script_name" ]]; then
            local file="$target_dir/$(normalize "$script_name")"
            if [[ ! -f "$file" ]]; then
                echo "Script not found: $script_name in $category"
                echo "Available scripts in $category:"
                find "$target_dir" -type f -name '*.zsh' | while read -r f; do
                    echo "  - $(basename "$f" .zsh)"
                done
                exit 1
            fi
            
            echo "${colors[cyan]}=== $(basename "$file") ===${colors[reset]}"
            if command -v bat >/dev/null 2>&1; then
                bat --style=plain --paging=never "$file"
            else
                cat "$file"
            fi
            return 0
        fi
        
        # Show all scripts in category with syntax-aware viewing
        echo "${colors[cyan]}=== Viewing $category ===${colors[reset]}"
        
        local files=()
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$target_dir" -type f -name '*.zsh' -print0 2>/dev/null | sort -z)
        
        if (( ${#files[@]} == 0 )); then
            echo "No scripts found in $category"
            return 1
        fi
        
        for file in "${files[@]}"; do
            echo "\n${colors[yellow]}File: $(basename "$file")${colors[reset]}"
            
            # Category-specific parsing
            case "$category" in
                functions)
                    # Extract functions with comments
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                        /^[[:space:]]*#/ { 
                            comment = comment $0 "\n"; 
                            next 
                        }
                        /^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*\(\)/ {
                            if (comment != "") {
                                printf "%s%s%s", magenta, comment, reset
                            }
                            print blue $0 reset
                            comment=""
                            next
                        }
                        /^[[:space:]]*$/ { 
                            if (comment != "") comment = ""
                        }
                    ' "$file" 2>/dev/null
                    ;;
                    
                aliases)
                    # Extract aliases with comments
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                        /^[[:space:]]*#/ { 
                            comment = comment $0 "\n"; 
                            next 
                        }
                        /^[[:space:]]*alias / {
                            if (comment != "") {
                                printf "%s%s%s", magenta, comment, reset
                            }
                            print blue $0 reset
                            comment=""
                            next
                        }
                        /^[[:space:]]*$/ { 
                            if (comment != "") comment = ""
                        }
                    ' "$file" 2>/dev/null
                    ;;
                    
                exports|configs)
                    # Extract exports/variables with comments
                    awk -v reset="${colors[reset]}" -v blue="${colors[blue]}" -v magenta="${colors[magenta]}" '
                        /^[[:space:]]*#/ { 
                            comment = comment $0 "\n"; 
                            next 
                        }
                        /^[[:space:]]*(export|declare|typeset|local)/ {
                            if (comment != "") {
                                printf "%s%s%s", magenta, comment, reset
                            }
                            print blue $0 reset
                            comment=""
                            next
                        }
                        /^[[:space:]]*[A-Z_][A-Z0-9_]*=/ {
                            if (comment != "") {
                                printf "%s%s%s", magenta, comment, reset
                            }
                            print blue $0 reset
                            comment=""
                            next
                        }
                        /^[[:space:]]*$/ { 
                            if (comment != "") comment = ""
                        }
                    ' "$file" 2>/dev/null
                    ;;
                    
                *)
                    # Generic view - show first 10 lines with line numbers
                    echo "  Preview (first 10 lines):"
                    head -n 10 "$file" 2>/dev/null | nl -ba | sed 's/^/    /'
                    local total_lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                    [[ $total_lines -gt 10 ]] && echo "    ... ($(($total_lines - 10)) more lines)"
                    ;;
            esac
        done
        ;;

    source)
        [[ -z "$2" ]] && { echo "Please specify a source file."; exit 1; }
        SOURCE_FILE="$2"
        if [[ -r "$SOURCE_FILE" ]]; then
            echo "Sourcing $SOURCE_FILE..."
            source "$SOURCE_FILE"
            echo "Done."
        else
            echo "Error: Could not read $SOURCE_FILE" >&2
            exit 1
        fi
        ;;

    backup)
        TS="$(date +%Y%m%d_%H%M%S)"
        DEST="$ENV_SRC_BACKUP-$TS"
        if [[ -d "$ENV_DIR" ]]; then
            mkdir -p "$DEST"
            cp -r "$ENV_DIR"/. "$DEST"/
            echo "Backup complete: $DEST"
        else
            echo "Error: Source directory $ENV_DIR not found."
            exit 1
        fi
        ;;

    search)
        [[ -z "$2" ]] && usage
        echo "Searching for '$2' in $ENV_DIR..."
        if [[ -d "$ENV_DIR" ]]; then
            if command -v rg >/dev/null 2>&1; then
                rg --color=auto -Hn "$2" "$ENV_DIR"
            elif command -v grep >/dev/null 2>&1; then
                grep -rn --color=auto "$2" "$ENV_DIR"
            else
                echo "No search tool available (rg or grep required)"
                exit 1
            fi
        else
            echo "Directory $ENV_DIR not found."
        fi
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        echo "Unknown command: '$1'"
        usage
        ;;
esac