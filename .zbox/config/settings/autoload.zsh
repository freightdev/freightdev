#######################
# AUTOLOAD CONFIGS
#######################

# Autoload Options

## Cache compinit for better startup time
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
autoload -Uz colors && colors
autoload -Uz vcs_info && vcs_info

## Completion system
#autoload -Uz bashcompinit && bashcompinit
#autoload -Uz complete-word
#autoload -Uz list-choices
#autoload -Uz menu-complete

## Line editor (zle) functions
#autoload -Uz edit-command-line && zle -N edit-command-line
#autoload -Uz history-search-end
#autoload -Uz up-line-or-beginning-search && zle -N up-line-or-beginning-search
#autoload -Uz down-line-or-beginning-search && zle -N down-line-or-beginning-search
#autoload -Uz history-beginning-search-backward && zle -N history-beginning-search-backward
#autoload -Uz history-beginning-search-forward && zle -N history-beginning-search-forward

## Utility functions
#autoload -Uz zmv          # Advanced move/copy/link (zmv '(*).txt' '$1.bak')
#autoload -Uz zcp          # Copy with zmv syntax
#autoload -Uz zln          # Link with zmv syntax
#autoload -Uz zcalc        # Built-in calculator
#autoload -Uz zargs        # xargs alternative
#autoload -Uz run-help     # Enhanced help system
#autoload -Uz run-help-git
#autoload -Uz run-help-openssl
#autoload -Uz run-help-p4
#autoload -Uz run-help-sudo
#autoload -Uz run-help-svk
#autoload -Uz run-help-svn

## URL handling
#autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic
#autoload -Uz bracketed-paste-magic && zle -N bracketed-paste bracketed-paste-magic

## Prompt functions
#autoload -Uz promptinit && promptinit
#autoload -Uz add-zsh-hook

## File handling
#autoload -Uz zsh-mime-setup && zsh-mime-setup
#autoload -Uz zsh-mime-handler

## Math functions
#autoload -Uz ztcp         # TCP functions
#autoload -Uz zftp         # FTP functions

## Advanced globbing
#autoload -Uz regexp-replace
#autoload -Uz split-shell-arguments

## History functions
#autoload -Uz history-pattern-search
#autoload -Uz narrow-to-region && zle -N narrow-to-region

## Text manipulation
#autoload -Uz select-word-style && select-word-style bash
#autoload -Uz transpose-words-match
#autoload -Uz copy-earlier-word && zle -N copy-earlier-word

## Completion helpers
#autoload -Uz _gnu_generic
#autoload -Uz keeper

## Development tools
#autoload -Uz zrecompile
#autoload -Uz checkmail
#autoload -Uz zed          # Simple text editor

## Load custom functions from functions directory
#if [[ -d "${ZDOTDIR:-$HOME}/functions" ]]; then
#    fpath=("${ZDOTDIR:-$HOME}/functions" $fpath)
#    for func in "${ZDOTDIR:-$HOME}/functions"/*(.N:t); do
#        autoload -Uz "$func"
#    done
#fi

## Load functions from your custom directory
#if [[ -d "$HOME/repos/.env/functions" ]]; then
#    fpath=("$HOME/repos/.env/functions" $fpath)
#    for func in "$HOME/repos/.env/functions"/*.zsh(.N); do
#        local func_name="${func:t:r}"
#        autoload -Uz "$func_name"
#    done
#fi

## Enable help system
#unalias run-help 2>/dev/null
#alias help=run-help

## Smart completion initialization (performance optimization)
#_comp_files=(${ZDOTDIR:-$HOME}/.zcompdump(Nm-20))
#if (( $#_comp_files )); then
#    compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
#else
#    compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
#fi
#unset _comp_files
