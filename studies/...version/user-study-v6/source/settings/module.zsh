#*  ╔═══════════════════════╗
#?      Optional Settings     
#*  ╚═══════════════════════╝

#!     Performance Options
#? ================================
setopt NO_GLOBAL_RCS
skip_global_compinit=1

#!        Shell Options
#? ================================
setopt NO_BEEP
unsetopt correct_all

#!       Color Options
#? ================================
autoload -Uz colors && colors

#!        VCS Options
#? ================================
autoload -Uz vcs_info

#!        Histoy Options
#? ================================
setopt HIST_IGNORE_DUPS     # ignore duplicate history entries
setopt HIST_IGNORE_SPACE    # ignore commands starting with space
setopt HIST_REDUCE_BLANKS   # remove extra whitespace from history
setopt HIST_SAVE_NO_DUPS    # don't save duplicate entries
setopt HIST_VERIFY          # verify history expansion
setopt INC_APPEND_HISTORY   # append to history immediately
setopt SHARE_HISTORY        # share history between sessions

#!        Prompt Options
#? ================================
setopt PROMPT_SUBST

#!         Zstyle Options
#? ================================
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '(%b)'

