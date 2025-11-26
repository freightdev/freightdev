#!  ╔════════════════════════════════════════╗
#?    Git Helpers - Environment Source (Zsh)  
#!  ╚════════════════════════════════════════╝

# Git log with graph
gitlog() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit ${1:---all}
}

# Create a new git repository and make initial commit
gitinit() {
    # Get current directory name as repo name
    local repo="${PWD##*/}"

    # Try to grab GitHub username from git config
    local user_name=$(git config --get github.user)

    # If not set, fall back to regular git user.name
    if [[ -z "$user_name" ]]; then
        user_name=$(git config --get user.name)
    fi

    # If still empty, ask the user once
    if [[ -z "$user_name" ]]; then
        echo "⚠️  GitHub username not found in config. Please enter:"
        read -r user_name
    fi

    git init
    git add .
    git commit -m "Initial commit"
    git branch -M main
    git remote add origin git@github.com:$user_name/$repo.git
    print -P "✅ Git repository '$repo' initialized and linked to $user_name/$repo"
}

# Git Repos
gitrepo() {
    # Prompt for repo URLs
    read -r "repos?Enter your repo URLs (space-separated): "
    # Prompt for destination directory
    read -r "dest?Enter directory to place repos: "

    # Expand ~ in path
    dest=${~dest}

    mkdir -p "$dest"

    for url in ${(z)repos}; do
        repo_name=$(basename "$url" .git)
        target="$dest/$repo_name"

        if [[ -d "$target/.git" ]]; then
            print -P "⚠️ Repo already exists: %F{yellow}$target%f"
        else
            print -P "⬇️  Cloning %F{green}$url%f into %F{blue}$target%f"
            git clone "$url" "$target"
        fi
    done
}