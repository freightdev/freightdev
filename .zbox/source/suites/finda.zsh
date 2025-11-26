###################
# FIND FUNCTIONS
###################

finda() {
  local type=$1
  shift

  case "$type" in
    file)
      local name=$1
      find . -type f -iname "*$name*" 2>/dev/null
      ;;
    dir)
      local name=$1
      find . -type d -iname "*$name*" 2>/dev/null
      ;;
    code)
      local search_dir=$1
      local pattern=$2

      if [[ -z "$search_dir" || -z "$pattern" ]]; then
        echo "Usage: finda code <directory> <pattern>"
        return 1
      fi

      if [[ ! -d "$search_dir" ]]; then
        echo "Error: Directory '$search_dir' does not exist."
        return 1
      fi

      grep -RnH --color=always "$pattern" "$search_dir" 2>/dev/null | while IFS=: read -r file line_number line_content; do
        local col_number
        col_number=$(expr index "$line_content" "$pattern")
        [[ "$col_number" -eq 0 ]] && col_number="-"

        echo "File: $file"
        echo "Line: $line_number"
        echo "Column: $col_number"
        echo "Content: $line_content"
        echo "--------------------------------------"
      done
      ;;
    *)
      echo "Usage: finda {file|dir|code} ..."
      ;;
  esac
}
