#!/usr/bin/env bash
# install-tools.sh — Dynamic installer for tools under $HOME/path/to/tools
set -euo pipefail

# ─── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Output Helpers ────────────────────────────────────────────────────────
print_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_header()  { echo -e "\n${BLUE}$1${NC}"; }

# ─── Paths ─────────────────────────────────────────────────────────────────
TOOLS_ROOT="$HOME/_data"
BIN_DIR="$HOME/.local/bin"
INSTALL_NAME="install.sh"

# ─── Ensure bin dir exists ─────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

# ─── Ensure $HOME/.local/bin is in PATH ────────────────────────────────────
ensure_path_in_zsh() {
    if ! echo "$PATH" | grep -qF "$HOME/.local/bin"; then
        print_warn "$HOME/.local/bin not in PATH — adding to Zsh config."
        local BLOCK='
# >>> LOCAL BIN PATH >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< LOCAL BIN PATH <<<
'
        local ZSHRC="$HOME/.zshrc"
        [[ ! -f "$ZSHRC" ]] && touch "$ZSHRC" && print_info "Created $ZSHRC"

        if ! grep -qF "$HOME/.local/bin" "$ZSHRC" 2>/dev/null; then
            echo "$BLOCK" >> "$ZSHRC"
            print_info "Added $HOME/.local/bin to PATH in $ZSHRC"
        fi

        for f in "$HOME/.zshrc.d"/*.zsh; do
            [[ -f "$f" ]] && ! grep -qF "$HOME/.local/bin" "$f" && {
                echo "$BLOCK" >> "$f"
                print_info "Added $HOME/.local/bin to PATH in $f"
            }
        done
    else
        print_info "$HOME/.local/bin already in PATH."
    fi
}

# ─── Scan for tools ────────────────────────────────────────────────────────
print_header "=== Tool Configuration Setup ==="
print_info "Scanning: $TOOLS_ROOT"

mapfile -t INSTALLERS < <(find "$TOOLS_ROOT" -mindepth 2 -maxdepth 5 -type f -name "$INSTALL_NAME")

if [[ ${#INSTALLERS[@]} -eq 0 ]]; then
    print_error "No installable tools found (missing $INSTALL_NAME)"
    exit 1
fi

# ─── Map tool names ────────────────────────────────────────────────────────
TOOL_KEY=()
for path in "${INSTALLERS[@]}"; do
    REL_PATH="${path#"$TOOLS_ROOT/"}"
    TOOL_KEY+=("${REL_PATH%/$INSTALL_NAME}")
done

echo ""
print_info "Installable Tools:"
printf '  %s\n' "${TOOL_KEY[@]}"
echo ""

# ─── Prompt user ───────────────────────────────────────────────────────────
read -rp "Tools to install (or type 'all'): " SELECTION
SELECTION_LOWER=$(echo "$SELECTION" | tr '[:upper:]' '[:lower:]')

install_tool() {
    local path="$1"
    local tool_dir
    tool_dir="$(dirname "$path")"
    local tool_name
    tool_name="$(basename "$tool_dir")"

    print_header "Installing: $tool_name"
    (cd "$tool_dir" && bash "./$INSTALL_NAME")
    echo ""
}

# ─── Ensure PATH is set before installing ──────────────────────────────────
ensure_path_in_zsh

# ─── Install all or selected ───────────────────────────────────────────────
if [[ "$SELECTION_LOWER" == "all" ]]; then
    for path in "${INSTALLERS[@]}"; do
        install_tool "$path"
    done
else
    MATCHED=0
    for i in "${!TOOL_KEY[@]}"; do
        if [[ "$(echo "${TOOL_KEY[$i]}" | tr '[:upper:]' '[:lower:]')" == *"$SELECTION_LOWER"* ]]; then
            install_tool "${INSTALLERS[$i]}"
            MATCHED=1
        fi
    done
    if [[ $MATCHED -eq 0 ]]; then
        print_error "No match for '$SELECTION'"
        exit 1
    fi
fi

print_info "✅ Install complete."
