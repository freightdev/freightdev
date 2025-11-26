#!  ╔══════════════════════════════════════════╗
#?    Alias Configs - Environment Source (Zsh)  
#!  ╚══════════════════════════════════════════╝

# Helper (aliases)
alias h='history | grep'
alias path='echo -e ${PATH//:/\\n}'
alias cls='clear'
alias rlsrc='source ~/.zshrc'
alias rlenv='source ~/.zshenv'
alias prettier="prettier --config ~/.prettierrc"
alias finder='ranger --choosedir=$HOME/.rangerdir; cd $(<~/.config/ranger/.rangerdir)'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# List (aliases)
if command -v exa >/dev/null 2>&1; then    
    alias l='exa --group-directories-first --color=auto'
    alias ls='exa --group-directories-first --color=auto'
    alias ll='exa --group-directories-first --color=auto -alF --git'
    alias la='exa --group-directories-first --color=auto -a'
    alias lt='exa --group-directories-first --color=auto -alT'
    alias lh='exa --group-directories-first --color=auto -lah'
    alias lt='exa --group-directories-first --color=autor -altr'
    alias lstree='exa --tree --level=3 --group-directories-first'
    alias lssize='exa --group-directories-first --color=auto -laSh'
fi

if command -v bat &> /dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catt='bat --style=full'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
    alias fgrep='rg -F'
    alias egrep='rg'
else
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Safety net (aliases)
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Network (aliases)
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias localip='ip route get 1 | awk '"'"'{print $NF;exit}'"'"''
alias publicip='dig +short myip.opendns.com @resolver1.opendns.com'
alias ips='ip addr show'
alias routes='ip route show'

# Process Management (aliases)
alias k='kill'
alias k9='kill -9'
alias killall='killall -v'

# Package Management (aliases)
if command -v pacman &> /dev/null; then
    alias pacsearch='pacman -Ss'
    alias pacinit='sudo pacman -S'
    alias pacrm='sudo pacman -R'
    alias pacup='sudo pacman -Syu'
    alias paclist='pacman -Qi'
    alias pacclean='sudo pacman -Rns $(pacman -Qtdq)'
fi

if command -v yay &> /dev/null; then
    alias y='yay'
    alias ys='yay -Ss'
    alias yi='yay -S'
    alias yr='yay -R'
    alias yu='yay -Syu'
fi

# Clock (aliases)
alias time='date +"%T"'
alias date='date +"%d-%m-%Y"'
alias week='date +%V'

# Fun (aliases)
alias weather='curl wttr.in'
alias cheat='curl cheat.sh/'