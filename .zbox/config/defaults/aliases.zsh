###################
# ALIAS DEFAULTS
###################

# Primary Aliases
alias pytree='tree -a -I ".venv|prompts|__pycache__|tests|scripts|TODO" '
alias prettier="prettier --config ~/.prettierrc"
alias finder='ranger --choosedir=$HOME/.config/ranger/.rangerdir; cd $(<~/.config/ranger/.rangerdir)'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias cls='clear'

# Safe-Net Aliases
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Trash Bin Aliases (safer than rm)
alias del='trash'           # Delete to trash
alias undel='trash -r'      # Restore from trash
alias lstrash='trash -l'    # List trash contents
alias emptytrash='trash -e' # Empty trash permanently
# Uncomment to override rm with trash by default:
# alias rm='trash'

# Network Aliases
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias localip='ip route get 1 | awk '"'"'{print $NF;exit}'"'"''
alias publicip='dig +short myip.opendns.com @resolver1.opendns.com'
alias ips='ip addr show'
alias routes='ip route show'

# Process Manager Aliases
alias k9='kill -9'
alias kall='killall -v'
