#!/bin/bash

#################################
# sync-identity.sh
# Pushes .ssh and .gnupg from this machine to a remote
#################################

# Check for required arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    echo "Example: $0 john server.example.com"
    exit 1
fi

# Configuration
REMOTE_USER="$1"
REMOTE_HOST="$2"
REMOTE_BASE_DIR="/home/$REMOTE_USER"

# Paths - use actual user's home, not root if running with sudo
if [[ -n "$SUDO_USER" ]]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    ACTUAL_USER="$SUDO_USER"
else
    USER_HOME="$HOME"
    ACTUAL_USER="$USER"
fi

SSH_SRC="$USER_HOME/.ssh"
GPG_SRC="$USER_HOME/.gnupg"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Sync function
sync_identity() {
    remote_ssh="$REMOTE_BASE_DIR/.ssh"
    remote_gpg="$REMOTE_BASE_DIR/.gnupg"

    echo -e "${YELLOW}Starting identity sync to $REMOTE_USER@$REMOTE_HOST...${NC}"
    echo -e "${YELLOW}Using home directory: $USER_HOME${NC}"

    # Push .ssh (excluding agent sockets and other runtime files)
    if [[ -d "$SSH_SRC" ]]; then
        echo -e "${GREEN}Syncing .ssh directory...${NC}"
        rsync -avz \
            --exclude='agent/' \
            --exclude='*.sock' \
            --exclude='control-*' \
            --exclude='known_hosts.old' \
            "$SSH_SRC/" "$REMOTE_USER@$REMOTE_HOST:$remote_ssh/"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Setting permissions on remote .ssh...${NC}"
            ssh "$REMOTE_USER@$REMOTE_HOST" "chmod 700 $remote_ssh; find $remote_ssh -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} \; ; find $remote_ssh -type f -name '*.pub' -exec chmod 644 {} \;"
        else
            echo -e "${RED}Failed to sync .ssh directory${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}No .ssh directory found at $SSH_SRC${NC}"
    fi

    # Push .gnupg (excluding sockets and locks)
    if [[ -d "$GPG_SRC" ]]; then
        echo -e "${GREEN}Syncing .gnupg directory...${NC}"
        
        # Check if we need sudo for GPG files
        if [[ $EUID -ne 0 ]]; then
            echo -e "${YELLOW}GPG files require elevated permissions. You may need to enter your password.${NC}"
            sudo rsync -avz \
                --exclude='S.*' \
                --exclude='*.lock' \
                --exclude='*.tmp' \
                "$GPG_SRC/" "$REMOTE_USER@$REMOTE_HOST:$remote_gpg/"
        else
            rsync -avz \
                --exclude='S.*' \
                --exclude='*.lock' \
                --exclude='*.tmp' \
                "$GPG_SRC/" "$REMOTE_USER@$REMOTE_HOST:$remote_gpg/"
        fi
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Setting permissions on remote .gnupg...${NC}"
            ssh "$REMOTE_USER@$REMOTE_HOST" "chmod 700 $remote_gpg; find $remote_gpg -type f -exec chmod 600 {} \;"
        else
            echo -e "${RED}Failed to sync .gnupg directory${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}No .gnupg directory found at $GPG_SRC${NC}"
    fi

    echo -e "${GREEN}Identity sync complete!${NC}"
}

# Run the sync
sync_identity

exit 0
