#####################
# DEFUALT EXPORTS
#####################

# Export Logic
load_export() {
  local export_file="${(%):-%x}"
  echo "export $1=\"$2\"" >> "$export_file"
  export "$1"="$2"
}

# Default System Settings
export TERM="xterm-256color"
export COLORTERM="truecolor"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export EDITOR="nano"
export VISUAL="$EDITOR"
export PAGER="less"
export BROWSER="firefox"
export SHELL="/bin/zsh"
export GPG_TTY="$(tty)"
