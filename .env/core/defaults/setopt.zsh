#######################
# SETOPT CONFIGS
#######################

# SetOpt Options
setopt NO_GLOBAL_RCS
skip_global_compinit=1

## Core navigation options
setopt AUTO_CD              # Just type a directory name and Zsh will `cd` into it
unsetopt CORRECT            # Disable automatic correction for mistyped commands
unsetopt CORRECT_ALL        # Disable correction for command arguments as well
#setopt EXTENDED_GLOB        # Enable advanced globbing features (*, **, ^, etc.)
#setopt GLOB_DOTS            # Include dotfiles in glob matches (e.g., ls **/*)
#setopt INTERACTIVE_COMMENTS # Allow `# comment` lines in interactive shell
setopt NO_BEEP              # Disable annoying beeps
#setopt NO_CASE_GLOB         # Case-insensitive globbing (e.g., *.TXT matches *.txt)
#setopt NUMERIC_GLOB_SORT    # Sort numbers naturally when globbing (1,2,10 instead of 1,10,2)
setopt PROMPT_SUBST         # Allow dynamic prompt evaluation (variables, commands)

## History options
setopt HIST_IGNORE_DUPS     # Ignore consecutive duplicate commands in history
setopt HIST_IGNORE_SPACE    # Ignore commands that start with a space in history
setopt HIST_REDUCE_BLANKS   # Remove extra spaces in history entries
setopt HIST_SAVE_NO_DUPS    # Do not save duplicate entries in history file
setopt INC_APPEND_HISTORY   # Append commands to history immediately, not just at exit
setopt SHARE_HISTORY        # Share history across multiple Zsh sessions
#setopt EXTENDED_HISTORY     # Include timestamp in history
setopt HIST_VERIFY          # Expand history before execution for review
#setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history
#setopt HIST_FIND_NO_DUPS    # Don't show duplicates when searching history
#setopt HIST_IGNORE_ALL_DUPS # Remove older duplicates when adding new ones
#setopt APPEND_HISTORY       # Append to history file rather than overwrite
setopt INC_APPEND_HISTORY   # append to history immediately

## Completion options
#setopt ALWAYS_TO_END        # Move cursor to end after completion
#setopt AUTO_LIST           # Automatically list choices on ambiguous completion
#setopt AUTO_MENU           # Show completion menu on successive tab press
#setopt AUTO_PARAM_SLASH    # Add trailing slash when completing directories
#setopt COMPLETE_IN_WORD    # Complete from both ends of a word
#setopt LIST_PACKED         # Make completion lists more compact
#setopt MENU_COMPLETE       # Insert first match immediately on tab
#setopt AUTO_PARAM_KEYS     # Intelligently add/remove characters after completion

## Directory navigation options
#setopt AUTO_PUSHD          # Make cd push old directory onto stack
#setopt PUSHD_IGNORE_DUPS   # Don't push duplicate directories
#setopt PUSHD_MINUS         # Make cd -n go to nth directory in stack
#setopt PUSHD_SILENT        # Don't print directory stack after pushd/popd
#setopt PUSHD_TO_HOME       # Push to home if no argument is given

## Job control options
#setopt AUTO_RESUME         # Attempt to resume existing job before creating new one
#setopt LONG_LIST_JOBS      # List jobs in long format by default
setopt NOTIFY              # Report job status immediately
setopt CHECK_JOBS          # Report job status before exiting shell
setopt HUP                 # Send HUP signal to jobs when shell exits

## Globbing options
#setopt GLOB_COMPLETE       # Generate glob matches as completions
#setopt GLOB_STAR_SHORT     # ** means **/* (recursive descent)
#setopt MARK_DIRS           # Add trailing slash to directory names from glob
#setopt RC_EXPAND_PARAM     # Array expansion with parameters

## Input/Output options
#setopt CORRECT_ALL         # Try to correct all arguments (disabled above, enable if wanted)
#setopt DVORAK              # Use Dvorak keyboard for spelling correction
#setopt FLOW_CONTROL        # Enable flow control (Ctrl+S/Ctrl+Q)
#setopt IGNORE_EOF          # Don't exit on EOF (Ctrl+D)
#setopt INTERACTIVE_COMMENTS # Allow comments in interactive mode
#setopt MAIL_WARNING        # Warn about new mail
#setopt PATH_DIRS           # Perform path search on commands with slashes
#setopt PRINT_EIGHT_BIT     # Print eight bit characters literally
#setopt SHORT_LOOPS         # Allow short forms of for, repeat, select, if, function

## Pattern matching options
setopt BAD_PATTERN         # Print error for badly formed glob patterns
#setopt BARE_GLOB_QUAL      # Treat trailing parentheses specially in globbing
#setopt BRACE_CCL           # Allow brace character class list expansion
#setopt CSH_NULL_GLOB       # Don't error on no glob matches, return empty
#setopt EQUALS              # Perform = filename expansion
#setopt GLOB_ASSIGN         # Expand globs on right side of assignment
#setopt MAGIC_EQUAL_SUBST   # Expand filenames in --option=filename
#setopt MULTIBYTE           # Respect multibyte characters
setopt NOMATCH             # Print error if glob pattern has no matches
#setopt NULL_GLOB           # Delete glob pattern if no matches found
#setopt WARN_CREATE_GLOBAL  # Warn when creating global variables

## Shell emulation options
#setopt BASH_AUTO_LIST      # On ambiguous completion, list possibilities
#setopt C_BASES             # Output hex/octal numbers in C format
#setopt OCTAL_ZEROES        # Interpret numbers with leading zeros as octal
#setopt POSIX_ALIASES       # Expand aliases before other expansions
#setopt POSIX_BUILTINS      # Make builtins more POSIX compliant
#setopt POSIX_IDENTIFIERS   # Only POSIX characters in identifiers

## History expansion options
#setopt BANG_HIST           # Perform history expansion with !
#setopt HIST_ALLOW_CLOBBER  # Allow history to clobber files
#setopt HIST_BEEP           # Beep on history expansion errors
#setopt HIST_NO_FUNCTIONS   # Don't store function definitions in history
#setopt HIST_NO_STORE       # Don't store 'history' command in history
