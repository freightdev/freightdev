##############
# SSH AGENT
##############


if [[ -z "$SSH_AUTH_SOCK" && -f "$SSH_ID" ]]; then
    eval "$(keychain --quiet --nogui --eval "$SSH_ID" 2>/dev/null)" >/dev/null 2>&1
fi
