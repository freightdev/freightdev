#######################
# KEYBINDING CONFIGS
#######################

# KeyBinding Options

## Set emacs mode (use bindkey -v for vi mode)
#bindkey -e

## Navigation keys
#bindkey '^[[H' beginning-of-line      # Home
#bindkey '^[[F' end-of-line            # End
#bindkey '^[[3~' delete-char           # Delete
#bindkey '^[[2~' overwrite-mode        # Insert
#bindkey '^A' beginning-of-line        # Ctrl+A - start of line
#bindkey '^E' end-of-line             # Ctrl+E - end of line

## Word movement
#bindkey '^[[1;5C' forward-word        # Ctrl+Right
#bindkey '^[[1;5D' backward-word       # Ctrl+Left
#bindkey '^[[1;3C' forward-word        # Alt+Right
#bindkey '^[[1;3D' backward-word       # Alt+Left
#bindkey '^F' forward-word             # Ctrl+F - forward word
#bindkey '^B' backward-word            # Ctrl+B - backward word

## History navigation
#bindkey '^R' history-incremental-search-backward  # Ctrl+R - search history
#bindkey '^S' history-incremental-search-forward   # Ctrl+S - forward search
#bindkey '^P' up-line-or-history                   # Ctrl+P - previous command
#bindkey '^N' down-line-or-history                 # Ctrl+N - next command
#bindkey '^[[A' up-line-or-history                 # Up arrow
#bindkey '^[[B' down-line-or-history               # Down arrow

## Text editing
#bindkey '^K' kill-line                # Ctrl+K - delete from cursor to end
#bindkey '^U' kill-whole-line          # Ctrl+U - delete entire line
#bindkey '^W' backward-kill-word       # Ctrl+W - delete word backward
#bindkey '^Y' yank                     # Ctrl+Y - paste what you killed
#bindkey '^T' transpose-chars          # Ctrl+T - swap characters
#bindkey '^D' delete-char              # Ctrl+D - delete character
#bindkey '^H' backward-delete-char     # Ctrl+H - backspace

## Line manipulation
#bindkey '^L' clear-screen             # Ctrl+L - clear screen
#bindkey '^Z' undo                     # Ctrl+Z - undo last change
#bindkey '^_' undo                     # Ctrl+_ - undo (alternative)
#bindkey '^X^U' undo                   # Ctrl+X Ctrl+U - undo
#bindkey '^Q' push-line                # Ctrl+Q - push line to buffer
#bindkey '^V' quoted-insert            # Ctrl+V - insert next char literally

## Command line editing
#autoload -Uz edit-command-line
#zle -N edit-command-line
#bindkey '^X^E' edit-command-line      # Ctrl+X Ctrl+E - edit in editor

## Tab completion
#bindkey '^I' complete-word            # Tab - complete
#bindkey '^[[Z' reverse-menu-complete  # Shift+Tab - reverse complete

## Advanced navigation
#bindkey '^X^F' vi-find-next-char      # Ctrl+X Ctrl+F - find character
#bindkey '^X^B' vi-find-prev-char      # Ctrl+X Ctrl+B - find character backward

## Copy/paste (if using terminal with clipboard support)
#bindkey '^X^C' copy-region-as-kill    # Ctrl+X Ctrl+C - copy
#bindkey '^X^V' yank                   # Ctrl+X Ctrl+V - paste

## Special functions
#bindkey '^O' accept-line-and-down-history  # Ctrl+O - run and move to next
#bindkey '^G' send-break               # Ctrl+G - abort current command
#bindkey '^C' interrupt                # Ctrl+C - interrupt (SIGINT)

## Menu navigation (when in completion menu)
#bindkey -M menuselect '^[[Z' reverse-menu-complete  # Shift+Tab in menu
#bindkey -M menuselect '^M' accept-line              # Enter in menu
#bindkey -M menuselect '^[' send-break               # Escape from menu
