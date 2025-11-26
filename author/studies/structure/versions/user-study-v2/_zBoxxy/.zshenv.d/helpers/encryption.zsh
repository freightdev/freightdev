#!  ╔═══════════════════════════════════════════════╗
#?    Encryption Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════════╝

# URL encoding/decoding

urlencode() {
    if ! command -v python3 &>/dev/null; then
        echo "python3 is required for this function"
        return 1
    fi

    if [[ -z "$1" ]]; then
        echo "Usage: urlencode <string>"
        return 1
    fi

    python3 -c "import urllib.parse; print(urllib.parse.quote_plus('$1'))"
}

urldecode() {
    if ! command -v python3 &>/dev/null; then
        echo "python3 is required for this function"
        return 1
    fi

    if [[ -z "$1" ]]; then
        echo "Usage: urldecode <string>"
        return 1
    fi

    python3 -c "import urllib.parse; print(urllib.parse.unquote_plus('$1'))"
}


# Base64 encode: string, file, or stdin
b64encode() {
    if ! command -v base64 &>/dev/null; then
        echo "base64 command is required"
        return 1
    fi

    if [[ -n "$1" && -f "$1" ]]; then
        # File input
        base64 "$1"
    elif [[ -n "$1" ]]; then
        # String input
        printf "%s" "$1" | base64
    else
        # Read from stdin
        base64
    fi
}

# Base64 decode: string, file, or stdin
b64decode() {
    if ! command -v base64 &>/dev/null; then
        echo "base64 command is required"
        return 1
    fi

    if [[ -n "$1" && -f "$1" ]]; then
        # File input
        base64 -d "$1"
    elif [[ -n "$1" ]]; then
        # String input
        printf "%s" "$1" | base64 -d
    else
        # Read from stdin
        base64 -d
    fi
}

