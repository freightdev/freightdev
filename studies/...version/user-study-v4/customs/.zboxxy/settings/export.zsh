#*  ╔═════════════════════╗
#?      Export Settings     
#*  ╚═════════════════════╝

#!        System Exports
#? ================================
export TERM="xterm-256color"
export COLORTERM="truecolor"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export EDITOR="nano"
export VISUAL="$EDITOR"
export PAGER="less"
export BROWSER="firefox"

#!        Secure Exports
#? ================================
export GPG_TTY="$(tty)"
export gpgconf --launch gpg-agent 2>/dev/null