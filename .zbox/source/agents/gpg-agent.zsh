##############
# GPG AGENT
##############

# ---------- GPG Agent Initialization ----------
# Ensure GPG agent is running and available
if ! gpgconf --list-dirs agent-socket &>/dev/null; then
  eval "$(gpg-agent --daemon 2>/dev/null)" >/dev/null 2>&1
fi

# ---------- GPG Keychain Initialization ----------
# Start keychain for GPG and capture output silently
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  keychain_output=$(keychain --eval --quiet --gpg2 2>/dev/null)
  eval "$keychain_output" >/dev/null 2>&1
  unset keychain_output
fi
