#!/bin/bash
# scan_project.sh
PROJECT_ROOT=$1
OUTPUT_WRAPPER="$PROJECT_ROOT/generated_wrapper.h"

echo "// AUTO-GENERATED MASTER WRAPPER" > $OUTPUT_WRAPPER
echo "// Project: $PROJECT_ROOT" >> $OUTPUT_WRAPPER
echo "" >> $OUTPUT_WRAPPER

# Find ALL headers
find $PROJECT_ROOT -name "*.h" -o -name "*.hpp" -o -name "*.hh" | while read header; do
    echo "Processing: $header"
    
    # Extract everything with clang AST
    clang -Xclang -ast-dump=json -I$PROJECT_ROOT/include "$header" 2>/dev/null | \
    jq -r '.inner[]? | select(.kind == "FunctionDecl" or .kind == "CXXRecordDecl" or .kind == "EnumDecl")' | \
    # Parse and format for your wrapper
    your_ast_parser.py >> $OUTPUT_WRAPPER
done