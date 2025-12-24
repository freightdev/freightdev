# Modern, clean zsh prompt configuration

# Git status function
git_prompt_info() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            echo " %F{yellow}($branch *)%f"
        else
            echo " %F{green}($branch)%f"
        fi
    fi
}

# Battery level function (Linux)
battery_level() {
    local bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null)
    echo "${bat}%%"
}

# Prompt
PROMPT='%F{cyan}%~%f$(git_prompt_info)
%F{magenta}❯%f '

# Right prompt: hostname + time + battery
RPROMPT='%F{blue}%m%f %F{240}%*%f %F{yellow}$(battery_level)%f'

# Continuation prompt (multi-line)
PROMPT2='%F{240}..%f '
