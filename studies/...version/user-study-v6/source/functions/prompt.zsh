#!  ╔═════════════════════════════════════════════╗
#?    Prompt Functions - Environment Source (Zsh)  
#!  ╚═════════════════════════════════════════════╝

# Command execution time tracking
typeset -g _prompt_start_time
typeset -g _prompt_exec_time

# Git status function
prompt_git() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
        local git_status=""
        
        # Check for changes
        if ! git diff --quiet 2>/dev/null; then
            git_status+="${colors[red]}●${colors[reset]}"
        fi
        if ! git diff --cached --quiet 2>/dev/null; then
            git_status+="${colors[green]}●${colors[reset]}"
        fi
        
        echo "${colors[gray]}on${colors[reset]} ${colors[blue]}${branch}${colors[reset]}${git_status}"
    fi
}

# Terminal title
case $TERM in
    xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty|kitty)
        precmd() {
            if [[ -n $_prompt_start_time ]]; then
                _prompt_exec_time=$((SECONDS - _prompt_start_time))
                unset _prompt_start_time
            fi
            # Update vcs_info
            vcs_info
        }

        preexec() {
            _prompt_start_time=$SECONDS
            print -Pn "\e]0;%n@%m: $1\a"
        }

        # Command execution time function
        prompt_exec_time() {
            [[ -n $_prompt_exec_time ]] && (( _prompt_exec_time > 2 )) &&
                echo "%F{yellow}${_prompt_exec_time}s%f"
        }

        prompt_status() {
            # Exit status of last command
            (( $? == 0 )) && echo "%F{green}✓%f" || echo "%F{red}✗%f"
        }
        ;;
    screen*)
        precmd() {
            print -Pn "\e]83;title\a"
            print -Pn "\e]0;%~\a"
        }
        preexec() {
            _prompt_start_time=$SECONDS
            print -Pn "\e]83;title\a"
            print -Pn "\e]0;$1\a"
        }
        ;;
esac

# Modern prompt
PS1="
╭%F{cyan}%n%f@%F{green}%m%f in %F{blue}%~%f ${vcs_info_msg_0_}$(prompt_exec_time)%(?.%F{green}✓%f.%F{red}✗%f)
╰%F{grey}%*%f %F{cyan}❯%f "

# Continuation prompt
PS2="%F{cyan}❯%f "

# Selection prompt
PS3="%F{magenta}?%f "

# Debug prompt
PS4="%F{grey}+%N:%i%f "