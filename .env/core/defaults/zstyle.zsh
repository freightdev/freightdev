#######################
# ZSTYLE CONFIGS
#######################

# Zstyle Options

## VCS info styles
zstyle ':vcs_info:*' enable git svn hg bzr
#zstyle ':vcs_info:*' check-for-changes true
#zstyle ':vcs_info:*' unstagedstr '%F{red}●%f'
#zstyle ':vcs_info:*' stagedstr '%F{green}●%f'
zstyle ':vcs_info:git:*' formats '%F{blue}%b%f%u%c'
#zstyle ':vcs_info:git:*' actionformats '%F{blue}%b%f%u%c %F{yellow}(%a)%f'

## Completion menu and display
#zstyle ':completion:*' menu select
#zstyle ':completion:*' verbose yes
#zstyle ':completion:*' group-name ''
#zstyle ':completion:*' special-dirs true
#zstyle ':completion:*' squeeze-slashes true
#zstyle ':completion:*' file-sort modification
#zstyle ':completion:*' rehash true

## Completion descriptions and messages
#zstyle ':completion:*:descriptions' format '[%d]'
#zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
#zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
#zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
#zstyle ':completion:*:default' list-prompt '%S%M matches%s'

## Completion matching (case insensitive, partial matching)
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

## Completion colors
#zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
#zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

## Completion caching
#zstyle ':completion:*' use-cache on
#zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"

## Directory completion
#zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
#zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
#zstyle ':completion:*:-command-:*:' verbose false
#zstyle ':completion:*:cd:*' ignore-parents parent pwd

## Process completion
#zstyle ':completion:*:processes' command 'ps -u ${USER} -o pid,user,comm -w -w'
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z]*)=34=1'
#zstyle ':completion:*:*:kill:*' menu yes select
#zstyle ':completion:*:kill:*' force-list always

## Git completion
#zstyle ':completion:*:*:git:*' script ~/.config/git/git-completion.zsh
#zstyle ':completion:*:*:git*:*' group-order alias files

## SSH/SCP completion
#zstyle ':completion:*:ssh:*' hosts off
#zstyle ':completion:*:scp:*' hosts off
#zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'

## Man pages completion
#zstyle ':completion:*:manuals' separate-sections true
#zstyle ':completion:*:manuals.*' insert-sections true

## Command completion
#zstyle ':completion:*:*:-command-:*:*' group-order aliases functions builtins commands
#zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

## History completion
#zstyle ':completion:*:history-words' stop yes
#zstyle ':completion:*:history-words' remove-all-dups yes
#zstyle ':completion:*:history-words' list false
#zstyle ':completion:*:history-words' menu yes

## Correction
#zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
#zstyle ':completion:*:correct:*' insert-unambiguous true
#zstyle ':completion:*:correct:*' original true

## Expansion
#zstyle ':completion:*:expand:*' tag-order all-expansions
#zstyle ':completion:*:expand-alias:*' complete true

## Ignored patterns
#zstyle ':completion:*:*:*:users' ignored-patterns \
#    adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
#    clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
#    gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
#    ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios \
#    named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
#    operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
#    rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
#    usbmux uucp vcsa wwwrun xfs '_*'

## Performance optimization
#zstyle ':completion:*' accept-exact '*(N)'
#zstyle ':completion:*' accept-exact-dirs true

## Custom completions path
#zstyle ':completion:*' completer _extensions _complete _approximate
#zstyle ':completion:*' complete-options true

## Approximate completion
#zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

## Menu selection colors
#zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
