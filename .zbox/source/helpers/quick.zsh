#!  ╔══════════════════════════════════════════╗
#?    Quick Helpers - Environment Source (Zsh)  
#!  ╚══════════════════════════════════════════╝

# Generate UUID
uuid() {
    local count="${1:-1}"

    if ! command -v python3 &>/dev/null; then
        echo "python3 is required for this function"
        return 1
    fi

    for ((i=0; i<count; i++)); do
        python3 -c "import uuid; print(uuid.uuid4())"
    done
}


# Quick calculator
calc() {
    if ! command -v python3 &>/dev/null; then
        echo "python3 is required for this function"
        return 1
    fi

    if [[ -z "$*" ]]; then
        echo "Usage: calc <expression>"
        echo "Example: calc 3*4+2"
        return 1
    fi

    python3 -c "print($*)"
}


# JSON pretty print
jsonpp() {
    if ! command -v python3 &>/dev/null; then
        echo "python3 is required for this function"
        return 1
    fi

    if [[ -z "$1" ]]; then
        echo "Usage: jsonpp <file_or_json_string>"
        return 1
    fi

    if [[ -f "$1" ]]; then
        python3 -m json.tool "$1"
    else
        echo "$1" | python3 -m json.tool
    fi
}

# Simple note-taking function
note() {
    local note_file="$HOME/.notes"

    # Ensure note file exists
    [[ -f $note_file ]] || touch "$note_file"

    if [[ $# -eq 0 ]]; then
        if [[ -s $note_file ]]; then
            echo "=== Your Notes ==="
            cat "$note_file"
        else
            echo "No notes found. Use 'note <message>' to add a note."
        fi
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S'): $*" >> "$note_file"
        echo "Note added!"
    fi
}


# Clear all notes
clearnotes() {
    local note_file="$HOME/.notes"

    # Ensure note file exists
    [[ -f $note_file ]] || touch "$note_file"

    echo "=== Clear Notes ==="
    read "?Are you sure you want to clear all notes? [y/N]: " response
    if [[ $response =~ ^[Yy]$ ]]; then
        : > "$note_file"
        echo "Notes cleared!"
    else
        echo "Operation canceled."
    fi
}
