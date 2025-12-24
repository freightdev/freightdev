#!/bin/bash

siza() {
    local target="${1:-.}"  # Default to current directory if no argument

    echo "=== SIZEYT - Comprehensive Size Analysis ==="
    echo "Target: $target"
    echo "Analysis Time: $(date 2>/dev/null || echo 'Unknown')"
    echo "========================================"
    echo

    # Check if target exists
    if [[ ! -e "$target" ]]; then
        echo "❌ Error: '$target' does not exist"
        return 1
    fi

    # Total size summary
    echo "📊 TOTAL SIZE SUMMARY"
    echo "--------------------"
    if [[ -d "$target" ]]; then
        # Use ls -la for basic size info
        echo "Directory contents:"
        ls -lah "$target" 2>/dev/null || echo "Cannot read directory"
        echo
        echo "Subdirectories:"
        ls -la "$target"/ 2>/dev/null | grep "^d" || echo "No subdirectories or cannot read"
        echo
        echo "File count estimate:"
        ls -1 "$target"/* 2>/dev/null | wc -l 2>/dev/null || echo "Cannot count files"
    else
        echo "File size:"
        ls -lah "$target" 2>/dev/null || echo "Cannot read file"
        echo "File type:"
        file "$target" 2>/dev/null || echo "Cannot determine file type"
    fi
    echo

    # If it's a directory, show more details
    if [[ -d "$target" ]]; then
        echo "📁 DIRECTORY CONTENTS"
        echo "--------------------"
        for item in "$target"/*; do
            if [[ -e "$item" ]]; then
                ls -lah "$item"
            fi
        done 2>/dev/null
        echo

        echo "📸 MEDIA FILES FOUND"
        echo "-------------------"
        echo "Photos:"
        ls -1 "$target"/*.jpg "$target"/*.jpeg "$target"/*.png "$target"/*.JPG "$target"/*.JPEG "$target"/*.PNG 2>/dev/null | wc -l || echo "0"
        echo "Videos:"
        ls -1 "$target"/*.mp4 "$target"/*.MP4 "$target"/*.mov "$target"/*.MOV "$target"/*.avi "$target"/*.AVI 2>/dev/null | wc -l || echo "0"
        echo

        echo "📄 SAMPLE FILES"
        echo "---------------"
        for file in "$target"/*; do
            if [[ -f "$file" ]]; then
                echo "$(basename "$file"): $(ls -lah "$file" | awk '{print $5}')"
            fi
        done 2>/dev/null | head -10
        echo

        echo "🗂️  SUBDIRECTORIES"
        echo "------------------"
        for dir in "$target"/*; do
            if [[ -d "$dir" ]]; then
                echo "$(basename "$dir")/"
                ls -1 "$dir" 2>/dev/null | wc -l | sed 's/^/  Files: /'
            fi
        done 2>/dev/null
    else
        # Single file analysis
        echo "📄 FILE DETAILS"
        echo "---------------"
        ls -lah "$target"
        echo
        echo "File info:"
        file "$target" 2>/dev/null || echo "Cannot determine file type"

        # If it's an archive, try to analyze contents
        case "$target" in
            *.tar.gz|*.tgz)
                echo
                echo "🗜️  ARCHIVE CONTENTS"
                echo "-------------------"
                tar -tzvf "$target" 2>/dev/null | head -20 || echo "Cannot read archive"
                ;;
            *.zip)
                echo
                echo "🗜️  ARCHIVE CONTENTS"
                echo "-------------------"
                unzip -l "$target" 2>/dev/null | head -20 || echo "Cannot read archive"
                ;;
            *.tar)
                echo
                echo "🗜️  ARCHIVE CONTENTS"
                echo "-------------------"
                tar -tvf "$target" 2>/dev/null | head -20 || echo "Cannot read archive"
                ;;
        esac
    fi

    echo "========================================"
    echo "Analysis complete!"
}

# Usage examples:
# siza                    # Analyze current directory
# siza phone_backup/      # Analyze phone_backup directory
# siza backup.tar.gz      # Analyze archive file
# siza /path/to/folder    # Analyze specific path
