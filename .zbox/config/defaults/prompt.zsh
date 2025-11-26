# Modern, clean zsh prompt configuration

# Git status function
git_prompt_info() {
    # Check if we're in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Get the current branch name
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

        # Check for uncommitted changes
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            echo " %F{yellow}($branch *)%f"
        else
            echo " %F{green}($branch)%f"
        fi
    fi
}

# Build the prompt
PROMPT='%F{cyan}%~%f$(git_prompt_info)
%F{magenta}❯%f '

# Right prompt: hostname + timestamp
RPROMPT='%F{blue}%m%f %F{240}%*%f'

# Continuation prompt (for multi-line commands)
PROMPT2='%F{240}..%f '
