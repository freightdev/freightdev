#!/bin/bash

# =============================================================================
# Tree Scaffold Creator - Professional Directory Structure Generator
# =============================================================================
# Author: Generated Script
# Version: 0.1.0
# Description: Parses tree structure files and creates directory scaffolds
# Usage: ./create-scaffold.sh [input_file] [output_directory]
#
# Supports:
# - Standard tree command output format
# - Various tree representations with different symbols
# - Comment filtering and cleanup
# - Preview mode before creation
# - Flexible input formats
# =============================================================================

set -euo pipefail

# Configuration Variables
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="0.1.0"
readonly DEFAULT_INPUT_EXT=".tree"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global variables
VERBOSE=false
DRY_RUN=false
FORCE=false
INPUT_FILE=""
OUTPUT_DIR=""

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_usage() {
    cat << EOF
${SCRIPT_NAME} v${VERSION} - Tree Scaffold Creator

USAGE:
    ${SCRIPT_NAME} [OPTIONS] <input_file> [output_directory]

DESCRIPTION:
    Parses tree structure files (.tree format or plain text) and creates
    actual directory structures with files and folders.

ARGUMENTS:
    input_file          Input file containing tree structure
    output_directory    Target directory (default: current directory)

OPTIONS:
    -p, --preview       Preview mode - show what would be created
    -v, --verbose       Verbose output
    -f, --force         Overwrite existing files/directories
    -h, --help          Show this help message
    --version           Show version information

EXAMPLES:
    ${SCRIPT_NAME} project.tree
    ${SCRIPT_NAME} --preview structure.tree ./new-project
    ${SCRIPT_NAME} -vf my-scaffold.tree /path/to/output

SUPPORTED TREE FORMATS:
    - Standard tree command output (├── └── │)
    - Simple indented structure
    - Mixed symbol formats
    - Comments (# // /* */) are automatically filtered
EOF
}

print_version() {
    echo "${SCRIPT_NAME} version ${VERSION}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${PURPLE}[VERBOSE]${NC} $1"
    fi
}

# =============================================================================
# PARSING FUNCTIONS
# =============================================================================

extract_filename() {
    local line="$1"

    # Remove tree drawing characters more systematically
    local clean_line=$(echo "$line" | sed -E 's/^[[:space:]`|│├└─]+*[[:space:]]*//')

    # Remove comment portions (everything after # or //) 
    clean_line=$(echo "$clean_line" | sed -E 's/[[:space:]]*#.*$//')
    clean_line=$(echo "$clean_line" | sed -E 's/[[:space:]]*\/\/.*$//')

    # Trim remaining whitespace
    clean_line=$(echo "$clean_line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//')

    echo "$clean_line"
}



calculate_depth() {
    local line="$1"
    
    # Count the depth by analyzing the tree structure more carefully
    # Remove everything after the actual filename/dirname to isolate tree structure
    local tree_part=$(echo "$line" | sed -E 's/[a-zA-Z0-9_.*-]+[/]?([[:space:]]*#.*)?$//')
    
    # Count the levels by counting the sets of tree connectors
    # Each level adds either "├── " or "└── " or "│   " continuation
    local depth=0
    
    # Method 1: Count ├── and └── occurrences 
    local branch_count=$(echo "$tree_part" | grep -o '[├└]' | wc -l)
    if [[ $branch_count -gt 0 ]]; then
        depth=$branch_count
    else
        # Method 2: Count indentation groups (every "│   " or "    " represents one level)
        # Remove the filename part and count indentation
        local indent_part=$(echo "$line" | sed -E 's/[├└─]*[[:space:]]*[a-zA-Z0-9_.*-]+.*//')
        
        # Count groups of 4 characters (typical tree indentation)
        local char_count=$(echo "$indent_part" | wc -c)
        depth=$(( (char_count - 1) / 4 ))
    fi
    
    # Debug output for depth calculation
    if [[ "$VERBOSE" == true ]]; then
        echo "  [DEPTH DEBUG] tree_part='$tree_part', branch_count=$branch_count, final_depth=$depth" >&2
    fi
    
    echo $depth
}

is_directory() {
    local name="$1"
    
    # Explicit directory markers
    [[ "$name" =~ /$ ]] && return 0
    
    # Files with clear extensions are definitely files
    if [[ "$name" =~ \.(py|js|ts|tsx|jsx|sql|yml|yaml|json|md|txt|sh|toml)$ ]]; then
        return 1
    fi
    
    # Dockerfile variants are files, not directories
    if [[ "$name" =~ ^Dockerfile ]]; then
        return 1
    fi
    
    # docker-compose files are files
    if [[ "$name" =~ docker-compose ]]; then
        return 1
    fi
    
    # Special Python files
    if [[ "$name" == "__init__.py" ]] || [[ "$name" =~ \*\*.*\*\* ]]; then
        return 1
    fi
    
    # Common directory names (no extension)
    case "$name" in
        # Backend/framework directories
        backend|frontend|app|api|components|pages|hooks|types|utils|helpers) return 0 ;;
        # Data/storage directories  
        data|migrations|models|memory|agents|inference|embeddings|conversations) return 0 ;;
        # Build/config directories
        docker|build|dist|assets|images|styles|scripts|src|lib|bin|test|tests|docs) return 0 ;;
        # Hidden directories
        .git|.vscode|.idea|node_modules) return 0 ;;
        # Custom directories (capitalized components)
        Chat|Layout) return 0 ;;
        */) return 0 ;;
    esac
    
    # Files starting with underscore are usually files
    if [[ "$name" =~ ^_ ]] && [[ ! "$name" =~ /$ ]]; then
        return 1
    fi
    
    # Files with dots but no clear extension (like requirements.txt already handled above)
    if [[ "$name" =~ \. ]] && [[ ! "$name" =~ ^[A-Z] ]]; then
        return 1
    fi
    
    # Default to directory for ambiguous cases
    return 0
}

parse_tree_structure() {
    local input_file="$1"
    local -n result_ref=$2
    
    log_verbose "Parsing tree structure from: $input_file"
    
    local line_num=0
    declare -a path_stack=()
    local items_added=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Skip completely empty lines
        [[ -z "$(echo "$line" | tr -d '[:space:]')" ]] && continue
        
        # Extract the actual filename/dirname
        local name=$(extract_filename "$line")
        
        # Skip if we couldn't extract a valid name
        if [[ -z "$name" ]]; then
            log_verbose "Line $line_num: Skipped - empty name after extraction"
            continue
        fi
        
        # Skip lines that are just tree artifacts
        if [[ "$name" =~ ^[├└│─[:space:]]*$ ]]; then
            log_verbose "Line $line_num: Skipped - tree artifacts only"
            continue
        fi
        
        # Calculate the depth
        local depth=$(calculate_depth "$line")
        
        log_verbose "Line $line_num: depth=$depth, name='$name', raw_line='$line'"
        
        # Adjust path stack based on current depth
        while [[ ${#path_stack[@]} -gt $depth ]]; do
            unset 'path_stack[-1]'
        done
        
        # Build the full path
        local full_path=""
        if [[ ${#path_stack[@]} -gt 0 ]]; then
            full_path=$(IFS='/'; echo "${path_stack[*]}")
            full_path="${full_path}/"
        fi
        
        # Clean up the name (remove trailing slash for processing)
        local clean_name="${name%/}"
        full_path="${full_path}${clean_name}"
        
        # Determine if it's a directory or file
        if is_directory "$name"; then
            result_ref["$full_path"]="directory"
            path_stack[depth]="$clean_name"
            log_verbose "Added directory: $full_path"
            ((items_added++))
        else
            result_ref["$full_path"]="file"
            log_verbose "Added file: $full_path"
            ((items_added++))
        fi
        
    done < "$input_file"
    
    log_info "Parsed $items_added items from tree structure (${#result_ref[@]} in array)"
    
    # Debug: show first few items if verbose
    if [[ "$VERBOSE" == true ]]; then
        log_verbose "Sample items in structure:"
        local count=0
        for key in "${!result_ref[@]}"; do
            log_verbose "  '$key' => '${result_ref[$key]}'"
            ((count++))
            [[ $count -ge 5 ]] && break
        done
    fi
}

# =============================================================================
# CREATION FUNCTIONS
# =============================================================================

preview_structure() {
    local -n struct_ref=$1
    
    echo
    log_info "Preview of structure to be created:"
    echo
    
    # Sort paths for better display
    local sorted_paths=($(printf '%s\n' "${!struct_ref[@]}" | sort))
    
    for path in "${sorted_paths[@]}"; do
        local type="${struct_ref[$path]}"
        local indent_level=$(echo "$path" | tr -cd '/' | wc -c)
        local indent=$(printf "%*s" $((indent_level * 2)) "")
        
        if [[ "$type" == "directory" ]]; then
            echo -e "${indent}${CYAN}📁 ${path}/${NC}"
        else
            echo -e "${indent}${GREEN}📄 ${path}${NC}"
        fi
    done
    
    echo
}

create_structure() {
    local -n struct_ref=$1
    local output_dir="$2"
    local created_count=0
    local skipped_count=0
    
    log_info "Creating structure in: $output_dir"
    
    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        log_verbose "Creating output directory: $output_dir"
        mkdir -p "$output_dir" || {
            log_error "Failed to create output directory: $output_dir"
            return 1
        }
    fi
    
    # Sort paths to ensure directories are created before their contents
    local sorted_paths=($(printf '%s\n' "${!struct_ref[@]}" | sort))
    
    for path in "${sorted_paths[@]}"; do
        local type="${struct_ref[$path]}"
        local full_path="$output_dir/$path"
        
        if [[ "$type" == "directory" ]]; then
            if [[ -d "$full_path" ]] && [[ "$FORCE" != true ]]; then
                log_verbose "Directory already exists: $path"
                ((skipped_count++))
            else
                log_verbose "Creating directory: $path"
                mkdir -p "$full_path" || {
                    log_error "Failed to create directory: $full_path"
                    continue
                }
                ((created_count++))
            fi
        else
            # Ensure parent directory exists
            local parent_dir=$(dirname "$full_path")
            [[ ! -d "$parent_dir" ]] && mkdir -p "$parent_dir"
            
            if [[ -f "$full_path" ]] && [[ "$FORCE" != true ]]; then
                log_verbose "File already exists: $path"
                ((skipped_count++))
            else
                log_verbose "Creating file: $path"
                touch "$full_path" || {
                    log_error "Failed to create file: $full_path"
                    continue
                }
                ((created_count++))
            fi
        fi
    done
    
    log_success "Created $created_count items, skipped $skipped_count existing items"
    return 0
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    declare -A structure
    
    # Validate input file
    if [[ ! -f "$INPUT_FILE" ]]; then
        log_error "Input file not found: $INPUT_FILE"
        return 1
    fi
    
    # Set default output directory
    [[ -z "$OUTPUT_DIR" ]] && OUTPUT_DIR="."
    
    # Parse the tree structure
    parse_tree_structure "$INPUT_FILE" structure
    
    if [[ ${#structure[@]} -eq 0 ]]; then
        log_error "No valid structure found in input file"
        return 1
    fi
    
    # Show preview
    preview_structure structure
    
    # If dry run mode, exit after preview
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run mode - no files created"
        return 0
    fi
    
    # Ask for confirmation unless in force mode
    if [[ "$FORCE" != true ]]; then
        echo -n "Do you want to create this structure? [y/N]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) ;;
            *) log_info "Operation cancelled"; return 0 ;;
        esac
    fi
    
    # Create the structure
    create_structure structure "$OUTPUT_DIR"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--preview)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        --version)
            print_version
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            if [[ -z "$INPUT_FILE" ]]; then
                INPUT_FILE="$1"
            elif [[ -z "$OUTPUT_DIR" ]]; then
                OUTPUT_DIR="$1"
            else
                log_error "Too many arguments"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$INPUT_FILE" ]]; then
    log_error "Input file is required"
    print_usage
    exit 1
fi

# Run main function
main
exit $?