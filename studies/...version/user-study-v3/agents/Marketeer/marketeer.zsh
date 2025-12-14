#!/bin/bash

# marketeer - Universal YAML CLI Orchestrator
# Reads any schema and becomes whatever tool you define

VERSION="1.0.0"
PROGRAM_NAME="marketeer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Global variables
declare -A SCHEMA_VALUES
declare -A USER_INPUTS
SCHEMA_FILE=""
VERBOSE=false
DRY_RUN=false
FORCE=false

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print usage
show_usage() {
    cat << EOF
${PROGRAM_NAME} v${VERSION} - Universal YAML CLI Orchestrator

USAGE:
    ${PROGRAM_NAME} <schema.yaml> [OPTIONS]
    ${PROGRAM_NAME} --help
    ${PROGRAM_NAME} --version

DESCRIPTION:
    Reads any YAML schema and executes the defined workflow interactively.
    Becomes whatever tool you define in your schema file.

OPTIONS:
    -v, --verbose       Enable verbose output
    -d, --dry-run      Show what would be done without executing
    -f, --force        Skip confirmation prompts
    -q, --quiet        Suppress non-essential output
    --list-schemas     List available schemas in current directory
    --validate         Validate schema without executing

EXAMPLES:
    ${PROGRAM_NAME} infrastructure.schema.yaml
    ${PROGRAM_NAME} story-fixer.schema.yaml --dry-run
    ${PROGRAM_NAME} deploy.schema.yaml --force --verbose
    ${PROGRAM_NAME} --list-schemas

SCHEMA FORMAT:
    name: "Tool Name"
    description: "What this tool does"
    version: "1.0"
    
    variables:
      key1: "default_value"
      key2: ""
    
    prompts:
      - key: "environment"
        question: "Which environment?"
        type: "select"
        options: ["dev", "staging", "prod"]
        default: "dev"
      
      - key: "confirm"
        question: "Continue?"
        type: "confirm"
        default: true
    
    actions:
      - type: "create_file"
        template: "config-{{environment}}.yaml"
        target: "./configs/"
      
      - type: "run_command"
        cmd: "docker-compose up -d"
        condition: "{{confirm}}"

EOF
}

# Function to extract YAML value
extract_yaml_value() {
    local line="$1"
    echo "$line" | sed 's/^[^:]*: *//' | sed 's/^["'\'']//' | sed 's/["'\'']$//' | sed 's/^ *//' | sed 's/ *$//'
}

# Function to read YAML file and populate SCHEMA_VALUES
read_schema() {
    local schema_file="$1"
    local current_section=""
    local in_list=false
    local list_key=""
    
    if [[ ! -f "$schema_file" ]]; then
        print_status "$RED" "Schema file not found: $schema_file"
        exit 1
    fi
    
    print_status "$BLUE" "📋 Loading schema: $schema_file"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Detect sections (top-level keys)
        if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*: ]]; then
            current_section=$(echo "$line" | cut -d: -f1)
            local value=$(extract_yaml_value "$line")
            
            if [[ -n "$value" ]]; then
                SCHEMA_VALUES["$current_section"]="$value"
                in_list=false
            else
                in_list=true
                list_key="$current_section"
            fi
        # Handle indented items (list items or nested keys)
        elif [[ "$line" =~ ^[[:space:]]+ ]]; then
            local indent_level=$(echo "$line" | sed 's/[^[:space:]].*//' | wc -c)
            local trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
            
            # List item
            if [[ "$trimmed" =~ ^- ]]; then
                local item=$(echo "$trimmed" | sed 's/^- *//')
                if [[ -n "${SCHEMA_VALUES[$list_key]}" ]]; then
                    SCHEMA_VALUES["$list_key"]+=$'\n'"$item"
                else
                    SCHEMA_VALUES["$list_key"]="$item"
                fi
            # Nested key-value
            elif [[ "$trimmed" =~ : ]]; then
                local nested_key=$(echo "$trimmed" | cut -d: -f1)
                local nested_value=$(extract_yaml_value "$trimmed")
                SCHEMA_VALUES["${current_section}.${nested_key}"]="$nested_value"
            fi
        fi
    done < "$schema_file"
    
    if [[ "$VERBOSE" == true ]]; then
        print_status "$CYAN" "Schema loaded with ${#SCHEMA_VALUES[@]} key-value pairs"
    fi
}

# Function to list all schemas in current directory
list_schemas() {
    print_status "$CYAN" "Available schemas in current directory:"
    echo ""
    
    local found=false
    for file in *.schema.yaml *.schema.yml; do
        if [[ -f "$file" ]]; then
            found=true
            local name="${SCHEMA_VALUES[name]:-Unknown}"
            local desc="${SCHEMA_VALUES[description]:-No description}"
            
            # Read basic info from schema
            if [[ -f "$file" ]]; then
                local temp_name=$(grep "^name:" "$file" | head -1 | cut -d: -f2- | sed 's/^ *//' | sed 's/["'\''"]//g')
                local temp_desc=$(grep "^description:" "$file" | head -1 | cut -d: -f2- | sed 's/^ *//' | sed 's/["'\''"]//g')
                name="${temp_name:-Unknown}"
                desc="${temp_desc:-No description}"
            fi
            
            printf "  📄 %-30s %s\n" "$file" "$name"
            printf "     %-30s %s\n" "" "$desc"
            echo ""
        fi
    done
    
    if [[ "$found" == false ]]; then
        print_status "$YELLOW" "  No schema files found (*.schema.yaml, *.schema.yml)"
    fi
}

# Function to validate schema
validate_schema() {
    local issues=0
    
    print_status "$CYAN" "🔍 Validating schema..."
    
    # Check required fields
    if [[ -z "${SCHEMA_VALUES[name]}" ]]; then
        print_status "$RED" "  ❌ Missing required field: name"
        ((issues++))
    fi
    
    # Check if prompts section exists and is properly formatted
    if [[ -n "${SCHEMA_VALUES[prompts]}" ]]; then
        print_status "$GREEN" "  ✅ Prompts section found"
    else
        print_status "$YELLOW" "  ⚠️  No prompts section found"
    fi
    
    # Check if actions section exists
    if [[ -n "${SCHEMA_VALUES[actions]}" ]]; then
        print_status "$GREEN" "  ✅ Actions section found"
    else
        print_status "$RED" "  ❌ No actions section found"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        print_status "$GREEN" "✅ Schema validation passed"
        return 0
    else
        print_status "$RED" "❌ Schema validation failed with $issues issues"
        return 1
    fi
}

# Function to display schema info
show_schema_info() {
    local name="${SCHEMA_VALUES[name]:-Unnamed Tool}"
    local desc="${SCHEMA_VALUES[description]:-No description provided}"
    local version="${SCHEMA_VALUES[version]:-1.0}"
    
    print_status "$MAGENTA" "🎯 $name (v$version)"
    echo "   $desc"
    echo ""
}

# Function to process prompts and collect user input
process_prompts() {
    local prompt_count
    prompt_count=$(yq eval '.prompts | length' "$SCHEMA_FILE")

    for (( i=0; i<prompt_count; i++ )); do
        local key question type default options input
        key=$(yq e ".prompts[$i].key" "$SCHEMA_FILE")
        question=$(yq e ".prompts[$i].question" "$SCHEMA_FILE")
        type=$(yq e ".prompts[$i].type" "$SCHEMA_FILE")
        default=$(yq e ".prompts[$i].default" "$SCHEMA_FILE")

        case "$type" in
            input)
                read -p "$question [$default]: " input
                USER_INPUTS[$key]="${input:-$default}"
                ;;
            confirm)
                read -p "$question [y/N]: " input
                [[ "$input" =~ ^[Yy]$ ]] && USER_INPUTS[$key]="true" || USER_INPUTS[$key]="false"
                ;;
            select)
                echo "$question"
                mapfile -t options < <(yq e ".prompts[$i].options[]" "$SCHEMA_FILE")
                for idx in "${!options[@]}"; do
                    echo "  [$idx] ${options[$idx]}"
                done
                read -p "Choose [0-${#options[@]}] (default: $default): " input
                selected="${options[$input]:-$default}"
                USER_INPUTS[$key]="$selected"
                ;;
            *)
                print_status "$RED" "Unknown prompt type: $type"
                ;;
        esac
    done
}


# Function to substitute variables in text
substitute_variables() {
    local text="$1"

    for key in "${!USER_INPUTS[@]}"; do
        text="${text//\{\{$key\}\}/${USER_INPUTS[$key]}}"
    done

    for key in "${!SCHEMA_VALUES[@]}"; do
        text="${text//\{\{$key\}\}/${SCHEMA_VALUES[$key]}}"
    done

    echo "$text"
}


# Function to execute actions
execute_actions() {
    print_status "$CYAN" "🚀 Executing actions..."
    echo ""

    local action_count
    action_count=$(yq eval '.actions | length' "$SCHEMA_FILE")

    for (( i=0; i<action_count; i++ )); do
        local type cmd condition template target run

        type=$(yq e ".actions[$i].type" "$SCHEMA_FILE")
        condition=$(yq e ".actions[$i].condition // \"true\"" "$SCHEMA_FILE")

        # Evaluate condition
        condition_eval=$(substitute_variables "$condition")
        if [[ "$condition_eval" != "true" ]]; then
            print_status "$YELLOW" "⚠️  Skipping action $i due to condition: $condition_eval"
            continue
        fi

        case "$type" in
            run_command)
                cmd=$(yq e ".actions[$i].cmd" "$SCHEMA_FILE")
                cmd_eval=$(substitute_variables "$cmd")
                print_status "$BLUE" "💻 Running: $cmd_eval"
                [[ "$DRY_RUN" != true ]] && eval "$cmd_eval"
                ;;
            create_file)
                template=$(yq e ".actions[$i].template" "$SCHEMA_FILE")
                target=$(yq e ".actions[$i].target" "$SCHEMA_FILE")
                filename=$(substitute_variables "$template")
                destination=$(substitute_variables "$target")/"$filename"
                mkdir -p "$(dirname "$destination")"
                echo "# Auto-generated file" > "$destination"
                print_status "$GREEN" "📄 Created file: $destination"
                ;;
            *)
                print_status "$RED" "Unknown action type: $type"
                ;;
        esac
    done

    print_status "$GREEN" "✅ All actions executed (or skipped)"
}


# Function to show all marked keys and values
show_marked_data() {
    print_status "$CYAN" "🏷️  Marked Schema Data:"
    echo ""
    
    for key in "${!SCHEMA_VALUES[@]}"; do
        local value="${SCHEMA_VALUES[$key]}"
        # Truncate long values for display
        if [[ ${#value} -gt 60 ]]; then
            value="${value:0:57}..."
        fi
        # Replace newlines with comma for multi-line values
        value="${value//$'\n'/, }"
        
        printf "  %-20s: %s\n" "$key" "$value"
    done
    echo ""
}

# Main execution function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --version)
                echo "$PROGRAM_NAME v$VERSION"
                exit 0
                ;;
            --list-schemas)
                list_schemas
                exit 0
                ;;
            --validate)
                if [[ -z "$SCHEMA_FILE" ]]; then
                    print_status "$RED" "Schema file required for validation"
                    exit 1
                fi
                validate_schema
                exit $?
                ;;
            --verbose|-v)
                VERBOSE=true
                ;;
            --dry-run|-d)
                DRY_RUN=true
                ;;
            --force|-f)
                FORCE=true
                ;;
            --quiet|-q)
                QUIET=true
                ;;
            *.yaml|*.yml)
                SCHEMA_FILE="$1"
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
        shift
    done
    
    # Check if schema file provided
    if [[ -z "$SCHEMA_FILE" ]]; then
        print_status "$RED" "Schema file required"
        echo ""
        show_usage
        exit 1
    fi
    
    # Main execution flow
    print_status "$MAGENTA" "🎪 $PROGRAM_NAME v$VERSION - Universal YAML Orchestrator"
    echo ""
    
    # Step 1: Read and mark schema
    read_schema "$SCHEMA_FILE"
    
    # Step 2: Show schema info
    show_schema_info
    
    # Step 3: Show marked data if verbose
    if [[ "$VERBOSE" == true ]]; then
        show_marked_data
    fi
    
    # Step 4: Validate schema
    if ! validate_schema; then
        exit 1
    fi
    echo ""
    
    # Step 5: Process prompts (collect user input)
    process_prompts
    
    # Step 6: Confirmation
    if [[ "$FORCE" != true ]] && [[ "$DRY_RUN" != true ]]; then
        echo ""
        read -p "Proceed with execution? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "$YELLOW" "Cancelled by user"
            exit 0
        fi
    fi
    
    # Step 7: Execute actions
    echo ""
    execute_actions
    
    print_status "$GREEN" "🎉 $PROGRAM_NAME execution complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi