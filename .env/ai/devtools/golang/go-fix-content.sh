#!/bin/bash

# scripts/go-fix-content.sh - Interactive find and replace for any directory
# Usage: ./scripts/go-fix-content.sh [directory] [file-pattern]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR="${1:-.}"
FILE_PATTERN="${2:-*.go}"

echo -e "${BLUE}=== Interactive Content Replace Tool ===${NC}"
echo -e "${YELLOW}Target Directory: $TARGET_DIR${NC}"
echo -e "${YELLOW}File Pattern: $FILE_PATTERN${NC}"

# Validate directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

cd "$TARGET_DIR"

# Function to show menu
show_menu() {
    echo -e "\n${BLUE}Choose operation:${NC}"
    echo "1. Simple find/replace (case sensitive)"
    echo "2. Simple find/replace (case insensitive)"
    echo "3. Regex find/replace"
    echo "4. Find and list occurrences only"
    echo "5. Replace in specific file"
    echo "6. Multi-line replace"
    echo "7. Go-specific fixes"
    echo "8. Batch replace from file"
    echo "0. Exit"
}

# Simple find/replace
simple_replace() {
    local case_flag="$1"
    
    read -p "Enter text to find: " find_text
    if [[ -z "$find_text" ]]; then
        echo -e "${RED}Find text cannot be empty${NC}"
        return
    fi
    
    read -p "Enter replacement text (or press Enter for empty): " replace_text
    
    echo -e "${YELLOW}Searching for '$find_text'...${NC}"
    
    # Find files containing the text
    local files_found=()
    while IFS= read -r -d '' file; do
        if grep -l $case_flag "$find_text" "$file" > /dev/null 2>&1; then
            files_found+=("$file")
        fi
    done < <(find . -name "$FILE_PATTERN" -type f -print0)
    
    if [[ ${#files_found[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No files found containing '$find_text'${NC}"
        return
    fi
    
    echo -e "${GREEN}Found in ${#files_found[@]} files:${NC}"
    printf '%s\n' "${files_found[@]}" | head -10
    if [[ ${#files_found[@]} -gt 10 ]]; then
        echo "... and $((${#files_found[@]} - 10)) more"
    fi
    
    # Show preview
    echo -e "\n${BLUE}Preview of first few matches:${NC}"
    for file in "${files_found[@]:0:3}"; do
        echo -e "${YELLOW}$file:${NC}"
        grep -n $case_flag "$find_text" "$file" | head -2
    done
    
    read -p "Proceed with replacement? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        for file in "${files_found[@]}"; do
            cp "$file" "$backup_dir/$(basename "$file")"
            if [[ "$case_flag" == "-i" ]]; then
                sed -i.tmp "s|$find_text|$replace_text|gi" "$file"
            else
                sed -i.tmp "s|$find_text|$replace_text|g" "$file"
            fi
            rm -f "$file.tmp"
        done
        
        echo -e "${GREEN}Replacement complete! Backup created in $backup_dir${NC}"
        echo -e "${YELLOW}Modified ${#files_found[@]} files${NC}"
    fi
}

# Regex find/replace
regex_replace() {
    read -p "Enter regex pattern to find: " find_pattern
    if [[ -z "$find_pattern" ]]; then
        echo -e "${RED}Pattern cannot be empty${NC}"
        return
    fi
    
    read -p "Enter replacement (use \\1, \\2 for capture groups): " replace_text
    
    echo -e "${YELLOW}Searching for pattern '$find_pattern'...${NC}"
    
    local files_found=()
    while IFS= read -r -d '' file; do
        if grep -E "$find_pattern" "$file" > /dev/null 2>&1; then
            files_found+=("$file")
        fi
    done < <(find . -name "$FILE_PATTERN" -type f -print0)
    
    if [[ ${#files_found[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No files found matching pattern${NC}"
        return
    fi
    
    echo -e "${GREEN}Found in ${#files_found[@]} files${NC}"
    
    # Show preview
    echo -e "\n${BLUE}Preview:${NC}"
    for file in "${files_found[@]:0:2}"; do
        echo -e "${YELLOW}$file:${NC}"
        grep -E "$find_pattern" "$file" | head -2
    done
    
    read -p "Proceed with regex replacement? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        for file in "${files_found[@]}"; do
            cp "$file" "$backup_dir/$(basename "$file")"
            sed -E -i.tmp "s|$find_pattern|$replace_text|g" "$file"
            rm -f "$file.tmp"
        done
        
        echo -e "${GREEN}Regex replacement complete! Backup in $backup_dir${NC}"
    fi
}

# Go-specific fixes
go_specific_fixes() {
    echo -e "${BLUE}Go-specific common fixes:${NC}"
    echo "1. Fix import statement formatting"
    echo "2. Replace panic with proper error handling"
    echo "3. Fix variable naming (camelCase)"
    echo "4. Remove debug print statements"
    echo "5. Fix string concatenation to use fmt.Sprintf"
    
    read -p "Choose go- (1-5): " choice
    
    case $choice in
        1)
            echo "Fixing import statements..."
            find . -name "*.go" | while read -r file; do
                # Fix multi-line imports to single line where appropriate
                sed -i.tmp '/^import ($/{N;s/import (\n\t"([^"]*)")/import "\1"/;}' "$file"
                rm -f "$file.tmp"
            done
            ;;
        2)
            simple_replace "" "panic(" "return fmt.Errorf("
            ;;
        3)
            echo "This requires manual review for proper camelCase conversion"
            ;;
        4)
            regex_replace "fmt\.Print.*$" ""
            ;;
        5)
            echo "Converting string concatenation..."
            # This is complex and would need careful regex
            echo "This requires manual review due to complexity"
            ;;
    esac
}

# Find only (no replace)
find_only() {
    read -p "Enter text to search for: " search_text
    if [[ -z "$search_text" ]]; then
        echo -e "${RED}Search text cannot be empty${NC}"
        return
    fi
    
    echo -e "${YELLOW}Searching for '$search_text'...${NC}"
    
    local count=0
    while IFS= read -r -d '' file; do
        if matches=$(grep -n "$search_text" "$file" 2>/dev/null); then
            echo -e "${GREEN}$file:${NC}"
            echo "$matches"
            ((count++))
        fi
    done < <(find . -name "$FILE_PATTERN" -type f -print0)
    
    echo -e "\n${BLUE}Found in $count files${NC}"
}

# Batch replace from file
batch_replace() {
    read -p "Enter path to replacement file (format: find_text|replace_text per line): " replace_file
    
    if [[ ! -f "$replace_file" ]]; then
        echo -e "${RED}File not found: $replace_file${NC}"
        return
    fi
    
    local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Processing batch replacements...${NC}"
    
    while IFS='|' read -r find_text replace_text; do
        if [[ -n "$find_text" ]]; then
            echo "Replacing: '$find_text' -> '$replace_text'"
            find . -name "$FILE_PATTERN" -type f | while read -r file; do
                if grep -q "$find_text" "$file"; then
                    [[ ! -f "$backup_dir/$(basename "$file")" ]] && cp "$file" "$backup_dir/"
                    sed -i.tmp "s|$find_text|$replace_text|g" "$file"
                    rm -f "$file.tmp"
                fi
            done
        fi
    done < "$replace_file"
    
    echo -e "${GREEN}Batch replacement complete!${NC}"
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Choose option (0-8): " choice
        
        case $choice in
            1) simple_replace "" ;;
            2) simple_replace "-i" ;;
            3) regex_replace ;;
            4) find_only ;;
            5) 
                read -p "Enter specific file path: " specific_file
                if [[ -f "$specific_file" ]]; then
                    FILE_PATTERN="$(basename "$specific_file")"
                    TARGET_DIR="$(dirname "$specific_file")"
                    simple_replace ""
                else
                    echo -e "${RED}File not found${NC}"
                fi
                ;;
            6) echo "Multi-line replace not implemented yet" ;;
            7) go_specific_fixes ;;
            8) batch_replace ;;
            0) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

main