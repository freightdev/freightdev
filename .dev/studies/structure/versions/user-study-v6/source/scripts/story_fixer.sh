#!/bin/bash

# Tale-Based File Fixer - Bash Script
# Ensures filenames match their tale and title values

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to find schema file
find_schema_file() {
    if [[ -f "stories.schema.yaml" ]]; then
        echo "stories.schema.yaml"
    elif [[ -f "stories.schema.yml" ]]; then
        echo "stories.schema.yml"
    elif [[ -f "story.schema.yml" ]]; then
        echo "story.schema.yml"
    elif [[ -f "story.schema.yaml" ]]; then
        echo "story.schema.yaml"
    else
        return 1
    fi
}

# Function to read schema setting
read_schema_setting() {
    local schema_file="$1"
    local key_path="$2"
    local default_value="$3"
    
    if [[ ! -f "$schema_file" ]]; then
        echo "$default_value"
        return
    fi
    
    # Simple YAML parser for specific keys we need
    case "$key_path" in
        "file_naming.tale_format")
            local result=$(grep -A 5 "^file_naming:" "$schema_file" | grep "tale_format:" | head -1)
            if [[ -n "$result" ]]; then
                extract_yaml_value "$result"
            else
                echo "$default_value"
            fi
            ;;
        "file_naming.title_slug_format")
            local result=$(grep -A 5 "^file_naming:" "$schema_file" | grep "title_slug_format:" | head -1)
            if [[ -n "$result" ]]; then
                extract_yaml_value "$result"
            else
                echo "$default_value"
            fi
            ;;
        "migration.rename_chapter_to_tale")
            local result=$(grep -A 5 "^migration:" "$schema_file" | grep "rename_chapter_to_tale:" | head -1)
            if [[ -n "$result" ]]; then
                extract_yaml_value "$result"
            else
                echo "$default_value"
            fi
            ;;
        "migration.add_missing_story_field")
            local result=$(grep -A 5 "^migration:" "$schema_file" | grep "add_missing_story_field:" | head -1)
            if [[ -n "$result" ]]; then
                extract_yaml_value "$result"
            else
                echo "$default_value"
            fi
            ;;
        "validation.filename_must_match_yaml")
            local result=$(grep -A 5 "^validation:" "$schema_file" | grep "filename_must_match_yaml:" | head -1)
            if [[ -n "$result" ]]; then
                extract_yaml_value "$result"
            else
                echo "$default_value"
            fi
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# Function to convert title to filename format
title_to_filename() {
    local title="$1"
    # Convert to lowercase, replace spaces with hyphens, remove special chars
    echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | sed 's/ \+/-/g'
}

# Function to extract value from YAML line
extract_yaml_value() {
    local line="$1"
    echo "$line" | sed 's/^[^:]*: *//' | sed 's/^["'\'']//' | sed 's/["'\'']$//'
}

# Function to read YAML header from file
read_yaml_header() {
    local file="$1"
    local key="$2"
    local in_yaml=false
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then
            in_yaml=true
            continue
        elif [[ $in_yaml == true && "$line" == "---" ]]; then
            break
        elif [[ $in_yaml == true ]]; then
            if [[ "$line" =~ ^${key}: ]]; then
                extract_yaml_value "$line"
                return 0
            fi
        fi
    done < "$file"
    
    return 1
}

# Function to get expected filename from YAML content
get_expected_filename() {
    local file="$1"
    local schema_file="$2"
    local tale_num=$(read_yaml_header "$file" "tale")
    local title=$(read_yaml_header "$file" "title")
    
    if [[ -z "$tale_num" ]] || [[ -z "$title" ]]; then
        return 1
    fi
    
    # Read tale format from schema
    local tale_format=$(read_schema_setting "$schema_file" "file_naming.tale_format" "zero_padded")
    
    # Format tale number based on schema settings
    local formatted_tale
    if [[ "$tale_format" == "zero_padded" ]]; then
        # Always use zero padding
        formatted_tale=$(printf "t%02d" "$tale_num")
    else
        # No padding
        formatted_tale="t${tale_num}"
    fi
    
    # Read title format from schema
    local title_format=$(read_schema_setting "$schema_file" "file_naming.title_slug_format" "lowercase_hyphenated")
    
    local filename_title
    if [[ "$title_format" == "lowercase_hyphenated" ]]; then
        filename_title=$(title_to_filename "$title")
    else
        # Fallback to default formatting
        filename_title=$(title_to_filename "$title")
    fi
    
    echo "${formatted_tale}.${filename_title}.md"
}

# Function to process a single file
process_file() {
    local file="$1"
    local story_dir="$2"
    local schema_file="$3"
    local current_filename=$(basename "$file")
    
    print_status "$BLUE" "Processing: $current_filename"
    
    # Check if file has YAML header
    if ! head -n 1 "$file" | grep -q "^---$"; then
        print_status "$YELLOW" "  No YAML header found, skipping..."
        return
    fi
    
    # Handle chapter → tale migration if enabled in schema
    local migrate_chapter=$(read_schema_setting "$schema_file" "migration.rename_chapter_to_tale" "true")
    if [[ "$migrate_chapter" == "true" ]]; then
        local chapter_num=$(read_yaml_header "$file" "chapter")
        local tale_num=$(read_yaml_header "$file" "tale")
        
        if [[ -n "$chapter_num" ]] && [[ -z "$tale_num" ]]; then
            # Need to migrate chapter to tale
            migrate_chapter_to_tale "$file" "$chapter_num"
            print_status "$GREEN" "  Migrated chapter: $chapter_num → tale: $chapter_num"
        fi
    fi
    
    # Get expected filename based on YAML content and schema
    local expected_filename=$(get_expected_filename "$file" "$schema_file")
    if [[ -z "$expected_filename" ]]; then
        print_status "$RED" "  Cannot determine expected filename (missing tale or title)"
        return
    fi
    
    local expected_path="${story_dir}/${expected_filename}"
    
    # Check if filename matches expected
    if [[ "$current_filename" == "$expected_filename" ]]; then
        print_status "$GREEN" "  Filename correct: $current_filename"
        return
    fi
    
    # Check validation settings
    local must_match=$(read_schema_setting "$schema_file" "validation.filename_must_match_yaml" "true")
    if [[ "$must_match" != "true" ]]; then
        print_status "$YELLOW" "  Filename mismatch allowed by schema: $current_filename"
        return
    fi
    
    # Check if target file already exists
    if [[ -f "$expected_path" ]] && [[ "$file" != "$expected_path" ]]; then
        print_status "$RED" "  Target file already exists: $expected_filename"
        return
    fi
    
    # Rename file
    mv "$file" "$expected_path"
    if [[ $? -eq 0 ]]; then
        print_status "$GREEN" "  Renamed: $current_filename → $expected_filename"
    else
        print_status "$RED" "  Failed to rename: $current_filename → $expected_filename"
    fi
}

# Function to migrate chapter field to tale field in YAML
migrate_chapter_to_tale() {
    local file="$1"
    local chapter_num="$2"
    local temp_file=$(mktemp)
    local in_yaml=false
    local yaml_ended=false
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then
            in_yaml=true
            echo "$line" >> "$temp_file"
        elif [[ $in_yaml == true && "$line" == "---" ]]; then
            yaml_ended=true
            echo "$line" >> "$temp_file"
        elif [[ $in_yaml == true ]]; then
            if [[ "$line" =~ ^chapter: ]]; then
                # Replace chapter with tale
                echo "tale: $chapter_num" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    mv "$temp_file" "$file"
}

# Function to preview changes
preview_changes() {
    print_status "$YELLOW" "PREVIEW MODE - No files will be modified"
    echo "=================================================="
    
    # Check for schema file
    local schema_file=$(find_schema_file)
    if [[ -n "$schema_file" ]]; then
        print_status "$GREEN" "Found schema file: $schema_file"
        
        # Show schema settings
        local tale_format=$(read_schema_setting "$schema_file" "file_naming.tale_format" "zero_padded")
        local migrate_chapter=$(read_schema_setting "$schema_file" "migration.rename_chapter_to_tale" "true")
        local must_match=$(read_schema_setting "$schema_file" "validation.filename_must_match_yaml" "true")
        
        echo "Schema settings:"
        echo "  - Tale format: $tale_format"
        echo "  - Migrate chapter→tale: $migrate_chapter"
        echo "  - Filename must match: $must_match"
    else
        print_status "$YELLOW" "No schema file found - using defaults"
        schema_file=""
    fi
    echo ""
    
    # Find all story directories
    for story_dir in */; do
        # Skip if not a directory or if it's a hidden directory
        [[ -d "$story_dir" ]] || continue
        [[ "$story_dir" == .* ]] && continue
        
        # Check if directory contains .md files
        if ! find "$story_dir" -maxdepth 1 -name "*.md" -type f | head -1 | grep -q .; then
            continue
        fi
        
        print_status "$BLUE" "Story directory: ${story_dir%/}"
        
        find "$story_dir" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
            local current_filename=$(basename "$file")
            local expected_filename=$(get_expected_filename "$file" "$schema_file")
            
            # Check for chapter migration
            local chapter_num=$(read_yaml_header "$file" "chapter")
            local tale_num=$(read_yaml_header "$file" "tale")
            local migration_note=""
            
            if [[ -n "$chapter_num" ]] && [[ -z "$tale_num" ]]; then
                migration_note=" (will migrate chapter:$chapter_num → tale:$chapter_num)"
            fi
            
            if [[ -n "$expected_filename" ]]; then
                if [[ "$current_filename" == "$expected_filename" ]]; then
                    printf "  ✓ %-30s (correct)%s\n" "$current_filename" "$migration_note"
                else
                    printf "  → %-30s → %s%s\n" "$current_filename" "$expected_filename" "$migration_note"
                fi
            else
                local title=$(read_yaml_header "$file" "title")
                printf "  ? %-30s (tale:%s, title:%s)%s\n" "$current_filename" "${tale_num:-missing}" "${title:-missing}" "$migration_note"
            fi
        done
        echo ""
    done
}

# Function to process all stories
process_all_stories() {
    print_status "$GREEN" "Starting file processing based on schema and YAML content..."
    
    # Check for schema file
    local schema_file=$(find_schema_file)
    if [[ -n "$schema_file" ]]; then
        print_status "$GREEN" "Using schema file: $schema_file"
    else
        print_status "$YELLOW" "No schema file found - using default settings"
        schema_file=""
    fi
    echo ""
    
    # Find all story directories
    for story_dir in */; do
        # Skip if not a directory or if it's a hidden directory
        [[ -d "$story_dir" ]] || continue
        [[ "$story_dir" == .* ]] && continue
        
        # Check if directory contains .md files
        if ! find "$story_dir" -maxdepth 1 -name "*.md" -type f | head -1 | grep -q .; then
            continue
        fi
        
        print_status "$BLUE" "Processing directory: ${story_dir%/}"
        
        find "$story_dir" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
            process_file "$file" "${story_dir%/}" "$schema_file"
        done
        echo ""
    done
    
    print_status "$GREEN" "All files processed!"
}

# Main script logic
main() {
    if [[ $# -gt 0 && "$1" == "preview" ]]; then
        preview_changes
    else
        echo "Tale-Based File Fixer"
        echo "This will rename files to match their YAML tale and title values"
        echo "Expected format: t{tale}.{title-slug}.md"
        echo ""
        echo "Run with 'preview' argument to see what changes would be made"
        echo ""
        
        read -p "Continue with file processing? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            process_all_stories
        else
            print_status "$YELLOW" "Cancelled."
        fi
    fi
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi