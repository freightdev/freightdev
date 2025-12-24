#!/bin/bash
# Pure Bash C/C++ API Extractor
# No Python bullshit - just raw bash power

PROJECT_ROOT="$1"
OUTPUT_WRAPPER="${PROJECT_ROOT}/wrapper.h"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ -z "$PROJECT_ROOT" ]]; then
    log_error "Usage: $0 <project_root>"
    exit 1
fi

# Arrays to store extracted info
declare -a FUNCTIONS=()
declare -a STRUCTS=()
declare -a ENUMS=()
declare -a TYPEDEFS=()
declare -a INCLUDES=()

# Extract functions from header files
extract_functions() {
    local header="$1"
    log_info "Extracting functions from $header"
    
    # Match function declarations (basic patterns)
    # This matches: return_type function_name(params);
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_*\s]+\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*;' "$header" | \
    grep -v '//' | \  # Skip commented lines
    grep -v '#' | \   # Skip preprocessor
    while IFS= read -r line; do
        # Clean up the line
        clean_line=$(echo "$line" | sed 's/^\s*//;s/\s*$//')
        if [[ ! "$clean_line" =~ ^(static|inline|typedef) ]]; then
            FUNCTIONS+=("$clean_line")
            log_info "  FUNC: $clean_line"
        fi
    done
    
    # Also catch extern "C" functions
    sed -n '/extern "C"/,/}/p' "$header" | \
    grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_*\s]+\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*;' | \
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^\s*//;s/\s*$//')
        FUNCTIONS+=("$clean_line")
        log_info "  EXTERN_C: $clean_line"
    done
}

# Extract struct definitions
extract_structs() {
    local header="$1"
    log_info "Extracting structs from $header"
    
    # Find struct definitions
    awk '/^[[:space:]]*struct[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\{/,/^[[:space:]]*\}[[:space:]]*;/' "$header" | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*struct[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            struct_name="${BASH_REMATCH[1]}"
            STRUCTS+=("typedef struct $struct_name $struct_name;")
            log_info "  STRUCT: $struct_name"
        fi
    done
    
    # Also find typedef struct patterns
    grep -E 'typedef\s+struct.*\{' "$header" -A 20 | \
    grep -E '\}\s*[a-zA-Z_][a-zA-Z0-9_]*\s*;' | \
    sed 's/.*}\s*\([a-zA-Z_][a-zA-Z0-9_]*\)\s*;.*/\1/' | \
    while IFS= read -r struct_name; do
        if [[ -n "$struct_name" ]]; then
            STRUCTS+=("typedef struct $struct_name $struct_name;")
            log_info "  TYPEDEF_STRUCT: $struct_name"
        fi
    done
}

# Extract enum definitions  
extract_enums() {
    local header="$1"
    log_info "Extracting enums from $header"
    
    # Find enum definitions
    awk '/^[[:space:]]*enum[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\{/,/^[[:space:]]*\}[[:space:]]*;/' "$header" | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*enum[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            enum_name="${BASH_REMATCH[1]}"
            ENUMS+=("typedef enum $enum_name $enum_name;")
            log_info "  ENUM: $enum_name"
        fi
    done
    
    # Find typedef enum patterns
    grep -E 'typedef\s+enum.*\{' "$header" -A 50 | \
    grep -E '\}\s*[a-zA-Z_][a-zA-Z0-9_]*\s*;' | \
    sed 's/.*}\s*\([a-zA-Z_][a-zA-Z0-9_]*\)\s*;.*/\1/' | \
    while IFS= read -r enum_name; do
        if [[ -n "$enum_name" ]]; then
            ENUMS+=("typedef enum $enum_name $enum_name;")
            log_info "  TYPEDEF_ENUM: $enum_name"
        fi
    done
}

# Extract typedefs
extract_typedefs() {
    local header="$1"
    log_info "Extracting typedefs from $header"
    
    # Simple typedef pattern
    grep -E '^\s*typedef\s+[^{}]*[a-zA-Z_][a-zA-Z0-9_]*\s*;' "$header" | \
    grep -v 'struct\|enum' | \
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^\s*//;s/\s*$//')
        TYPEDEFS+=("$clean_line")
        log_info "  TYPEDEF: $clean_line"
    done
}

# Extract includes
extract_includes() {
    local header="$1"
    
    # Get all #include statements
    grep -E '^\s*#include\s*[<"].*[>"]' "$header" | \
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^\s*//;s/\s*$//')
        # Avoid duplicates
        if [[ ! " ${INCLUDES[*]} " =~ " ${clean_line} " ]]; then
            INCLUDES+=("$clean_line")
        fi
    done
}

# Process all headers in project
process_project() {
    log_info "Scanning project: $PROJECT_ROOT"
    
    # Find all header files
    local header_count=0
    while IFS= read -r -d '' header; do
        ((header_count++))
        log_info "Processing header ($header_count): $header"
        
        extract_includes "$header"
        extract_functions "$header" 
        extract_structs "$header"
        extract_enums "$header"
        extract_typedefs "$header"
        
    done < <(find "$PROJECT_ROOT" -type f \( -name "*.h" -o -name "*.hpp" -o -name "*.hh" -o -name "*.hxx" \) -print0)
    
    log_info "Processed $header_count header files"
}

# Generate the master wrapper header
generate_wrapper() {
    local project_name=$(basename "$(realpath "$PROJECT_ROOT")")
    
    log_info "Generating wrapper: $OUTPUT_WRAPPER"
    
    cat > "$OUTPUT_WRAPPER" << EOF
// AUTO-GENERATED MASTER WRAPPER
// Project: $project_name  
// Generated by Pure Bash C/C++ API Extractor
// $(date)

#ifndef UNIVERSAL_WRAPPER_H
#define UNIVERSAL_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// SYSTEM INCLUDES
// ============================================================================
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

EOF

    # Add original includes (commented for reference)
    if [[ ${#INCLUDES[@]} -gt 0 ]]; then
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "// ORIGINAL INCLUDES (for reference)" >> "$OUTPUT_WRAPPER"  
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        for include in "${INCLUDES[@]}"; do
            echo "// $include" >> "$OUTPUT_WRAPPER"
        done
        echo "" >> "$OUTPUT_WRAPPER"
    fi

    # Add typedefs
    if [[ ${#TYPEDEFS[@]} -gt 0 ]]; then
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "// TYPEDEFS" >> "$OUTPUT_WRAPPER"
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "" >> "$OUTPUT_WRAPPER"
        for typedef in "${TYPEDEFS[@]}"; do
            echo "$typedef" >> "$OUTPUT_WRAPPER"
        done
        echo "" >> "$OUTPUT_WRAPPER"
    fi

    # Add struct/enum forward declarations
    if [[ ${#STRUCTS[@]} -gt 0 ]] || [[ ${#ENUMS[@]} -gt 0 ]]; then
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "// FORWARD DECLARATIONS" >> "$OUTPUT_WRAPPER"
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "" >> "$OUTPUT_WRAPPER"
        
        for struct in "${STRUCTS[@]}"; do
            echo "$struct" >> "$OUTPUT_WRAPPER"
        done
        
        for enum in "${ENUMS[@]}"; do
            echo "$enum" >> "$OUTPUT_WRAPPER"
        done
        echo "" >> "$OUTPUT_WRAPPER"
    fi

    # Add functions
    if [[ ${#FUNCTIONS[@]} -gt 0 ]]; then
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "// FUNCTION DECLARATIONS" >> "$OUTPUT_WRAPPER"
        echo "// ============================================================================" >> "$OUTPUT_WRAPPER"
        echo "" >> "$OUTPUT_WRAPPER"
        
        for func in "${FUNCTIONS[@]}"; do
            echo "$func" >> "$OUTPUT_WRAPPER"
        done
        echo "" >> "$OUTPUT_WRAPPER"
    fi

    cat >> "$OUTPUT_WRAPPER" << EOF
#ifdef __cplusplus
}
#endif

#endif // UNIVERSAL_WRAPPER_H
EOF

    log_success "Generated wrapper with:"
    log_success "  Functions: ${#FUNCTIONS[@]}"
    log_success "  Structs: ${#STRUCTS[@]}"
    log_success "  Enums: ${#ENUMS[@]}" 
    log_success "  Typedefs: ${#TYPEDEFS[@]}"
    log_success "  Includes: ${#INCLUDES[@]}"
}

# Advanced function extraction with better patterns
extract_functions_advanced() {
    local header="$1"
    log_info "Advanced function extraction from $header"
    
    # Use multiple passes with different patterns
    
    # Pass 1: Standard function declarations
    sed -n '/^[^#\/]/p' "$header" | \
    grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_*[:space:]]+[[:space:]]+\*?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*;' | \
    grep -v -E '^[[:space:]]*(static|inline|typedef)' | \
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        FUNCTIONS+=("$clean_line")
        log_info "  ADV_FUNC: $clean_line"
    done
    
    # Pass 2: Functions in extern "C" blocks
    awk '/extern[[:space:]]*"C"[[:space:]]*\{/,/\}/' "$header" | \
    grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_*[:space:]]+[[:space:]]+\*?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*;' | \
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        FUNCTIONS+=("extern \"C\" $clean_line")
        log_info "  EXTERN_C_ADV: $clean_line"
    done
}

# Main execution
main() {
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        log_error "Project directory not found: $PROJECT_ROOT"
        exit 1
    fi
    
    log_info "Pure Bash API Extractor starting..."
    log_info "Target: $PROJECT_ROOT"
    log_info "Output: $OUTPUT_WRAPPER"
    
    process_project
    generate_wrapper
    
    log_success "DONE! Your wrapper is ready: $OUTPUT_WRAPPER"
    log_info "Next steps:"
    log_info "  bindgen $OUTPUT_WRAPPER --output bindings.rs"
}

# Run it
main "$@"
