#!  ╔═══════════════════════════════════════════╗
#?    Setopt Configs - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Shell Optimization
setopt NO_BEEP              # disable beeping
unsetopt correct_all        # disable command argument correction

# Histoy Optimization
setopt HIST_IGNORE_DUPS     # ignore duplicate history entries
setopt HIST_IGNORE_SPACE    # ignore commands starting with space
setopt HIST_REDUCE_BLANKS   # remove extra whitespace from history
setopt HIST_SAVE_NO_DUPS    # don't save duplicate entries
setopt HIST_VERIFY          # verify history expansion
setopt INC_APPEND_HISTORY   # append to history immediately
setopt SHARE_HISTORY        # share history between sessions

# Prompt Optimization
setopt PROMPT_SUBST

# Performance Optimization
setopt NO_GLOBAL_RCS
skip_global_compinit=1