#!/bin/zsh
structure() {
  local cmd=""
  local force=0
  local target=""
  local destination=""
  local matches=()
  local choice=""
  local spaces=4
  local specific_path=""

  usage() {
    cat <<EOF
Usage: structure [mode] [options]

Modes:
  -d, --delete <pattern> [-t <path>] [-f]  Delete matching files/directories
  -a, --add <file> <destination>           Add a file to a destination
  -i, --indent <file> <spaces>             Re-indent a file (default 4 spaces)
  -h, --help                               Show this help message

Options:
  -t, --target <full-path>                 Specify exact path to delete
  -f, --force                              Skip confirmation in delete mode
EOF
  }

  [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]] && usage && return 0

  # -----------------------------
  # Parse args
  # -----------------------------
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force)
        force=1
        ;;
      -t|--target)
        shift
        specific_path="$1"
        ;;
      -d|--delete)
        cmd="delete"
        shift
        target="$1"
        ;;
      -a|--add)
        cmd="add"
        shift
        target="$1"
        shift
        destination="$1"
        ;;
      -i|--indent)
        cmd="indent"
        shift
        target="$1"
        shift
        spaces="$1"
        ;;
      *)
        target="$1"
        ;;
    esac
    shift
  done

  if [[ -z "$cmd" || -z "$target" ]]; then
    echo "Error: missing command or target."
    usage
    return 1
  fi

  # -----------------------------
  # Delete Mode
  # -----------------------------
  if [[ "$cmd" == "delete" ]]; then
    if [[ -n "$specific_path" ]]; then
      if [[ ! -e "$specific_path" ]]; then
        echo "Specified path not found: $specific_path"
        return 1
      fi
      matches=("$specific_path")
    else
      if command -v fd >/dev/null 2>&1; then
        matches=($(fd -H -t f -t d "$target" "$HOME"))
      elif command -v rg >/dev/null 2>&1; then
        matches=($(rg --files "$HOME" | grep -i "$target"))
      else
        matches=($(find "$HOME" -iname "*$target*"))
      fi
    fi

    if [[ ${#matches[@]} -eq 0 ]]; then
      echo "No matches found for '$target'"
      return 1
    fi

    if [[ ${#matches[@]} -eq 1 ]]; then
      choice="${matches[1]}"
    else
      echo "Found ${#matches[@]} matches:"
      for i in {1..${#matches[@]}}; do
        echo "  [$i] ${matches[$i]}"
      done
      echo -n "Enter number of item to delete: "
      read -r index
      if [[ ! "$index" =~ ^[0-9]+$ ]] || (( index < 1 || index > ${#matches[@]} )); then
        echo "Invalid choice."
        return 1
      fi
      choice="${matches[$index]}"
    fi

    if (( force == 1 )); then
      rm -rf -- "$choice"
      echo "Deleted: $choice"
    else
      echo -n "Delete '$choice'? [y/N]: "
      read -r confirm
      if [[ "$confirm" =~ ^[yY]$ ]]; then
        rm -rf -- "$choice"
        echo "Deleted: $choice"
      else
        echo "Aborted."
      fi
    fi
  fi

  # -----------------------------
  # Add Mode
  # -----------------------------
  if [[ "$cmd" == "add" ]]; then
    if [[ ! -f "$target" ]]; then
      echo "File to add not found: $target"
      return 1
    fi
    if [[ -z "$destination" ]]; then
      echo "Destination directory required."
      return 1
    fi
    mkdir -p -- "$destination"
    cp -- "$target" "$destination/"
    echo "Added $target → $destination/"
  fi

  # -----------------------------
  # Indent Mode
  # -----------------------------
  if [[ "$cmd" == "indent" ]]; then
    if [[ ! -f "$target" ]]; then
      echo "File not found: $target"
      return 1
    fi
    spaces=${spaces:-4}
    expand -t "$spaces" "$target" > "${target}.tmp"
    mv "${target}.tmp" "$target"
    echo "Re-indented $target with $spaces spaces"
  fi
}

# -----------------------------
# Auto-call if script executed
# -----------------------------
if [[ "${(%):-%N}" == "$0" ]]; then
  structure "$@"
fi
