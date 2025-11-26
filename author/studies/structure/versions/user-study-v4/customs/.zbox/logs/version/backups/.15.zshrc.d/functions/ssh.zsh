#!  ╔══════════════════════════════════════════╗
#?    SSH Functions - Environment Source (Zsh) 
#!  ╚══════════════════════════════════════════╝

# Defaults (override by loading custom env if needed)
: "${SSH_LOG:=$HOME/.ssh/ssh_helper.log}"
: "${SSH_TMP:=$HOME/.ssh/.sync_tmp}"
: "${SSH_ID:=$HOME/.ssh/id_rsa}"
: "${GPG_KEY:=$HOME/.gnupg}"            #optional gpg key
: "${SSH_USER:=$USER}"
: "${SSH_PORT:=22}"

# Flags
RSYNC_FLAGS="-avz --progress --delete"

# Checks
[[ ! -f "$SSH_TMP" ]] && touch "$SSH_TMP"
[[ ! -f "$SSH_LOG" ]] && touch "$SSH_LOG"

# LOGGING (helper)
log_ssh() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$SSH_LOG"
}

# Quick SSH function
qssh() {
    local host="$1"
    if [[ -z $host ]]; then
        echo "Usage: qssh <user@host> [extra ssh options]"
        return 1
    fi

    local tmp_known_hosts
    tmp_known_hosts=$(mktemp) || { echo "Failed to create temp file"; return 1; }
    trap 'rm -f "$tmp_known_hosts"' EXIT

    ssh -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$tmp_known_hosts" \
        -i "${SSH_ID:-~/.ssh/id_rsa}" \
        -p "${SSH_PORT:-22}" \
        "$@"
}


# QUICK SCP WITH OPTIONAL ENCRYPTION (function)
# Usage: qscp <local_file> user@host:/remote/path [encrypt: yes/no]
qscp() {
    local src="$1"
    local dest="$2"
    local encrypt="${3:-yes}"

    if [[ "$encrypt" == "yes" ]]; then
        SSH_TMP="$(mktemp --suffix=.gpg)"
        if [[ -n "$GPG_KEY" ]]; then
            echo "🔐 Encrypting with GPG key: $GPG_KEY"
            gpg --yes --output "$SSH_TMP" --encrypt --recipient "$GPG_KEY" "$src"
        else
            echo "🔐 Encrypting symmetrically (AES256) — enter passphrase:"
            gpg --yes --cipher-algo AES256 --compress-algo 1 --symmetric --output "$SSH_TMP" "$src"
        fi
    fi

    scp -i "$SSH_ID" -P "$SSH_PORT" "$SSH_TMP" "$dest"
    [[ "$encrypt" == "yes" ]] && rm -f "$SSH_TMP"

    log_ssh "SCP: $src -> $dest (encrypt=$encrypt)"
}

# QUICK RSYNC WITH OPTIONAL ENCRYPTION (function)
qrsync() {
    local src="$1"
    local dest="$2"
    local encrypt="${3:-yes}"

    if [[ "$encrypt" == "yes" ]]; then
        local tmp_archive
        tmp_archive="$(mktemp --suffix=.tar.gz.gpg)"
        if [[ -n "$GPG_KEY" ]]; then
            echo "🔐 Archiving + encrypting with GPG key: $GPG_KEY"
            tar -czf - -C "$(dirname "$src")" "$(basename "$src")" |
                gpg --yes --output "$tmp_archive" --encrypt --recipient "$GPG_KEY"
        else
            echo "🔐 Archiving + encrypting symmetrically (AES256) — enter passphrase:"
            tar -czf - -C "$(dirname "$src")" "$(basename "$src")" |
                gpg --yes --cipher-algo AES256 --compress-algo 1 --symmetric --output "$tmp_archive"
        fi
        scp -i "$SSH_ID" -P "$SSH_PORT" "$tmp_archive" "$dest"
        rm -f "$tmp_archive"
    else
        rsync $RSYNC_FLAGS -e "ssh -i $SSH_ID -p $SSH_PORT" "$src" "$dest"
    fi

    log_ssh "Rsync: $src -> $dest (encrypt=$encrypt)"
}

# MOUNT/UNMOUNT (function)
qmount() {
    local remote="$1"
    sshfs -o IdentityFile="$SSH_ID" -p "$SSH_PORT" "$remote" "$SSH_MOUNT"
}

qunmount() {
    fusermount -u "$local_path" 2>/dev/null || umount "$SSH_MOUNT"
}

# WHO'S CONNECTED (function)
ssh_who() {
    lsof -iTCP -sTCP:ESTABLISHED -nP | grep ssh
}

# SYNC DIR (function)
sync_dir() {
    local remote="$1"
    local encrypt="${2:-yes}"

    qrsync "$SSH_TMP/" "$remote" "$encrypt"
    echo "Sync complete: $SSH_TMP -> $remote" >>"$SSH_LOG"
}

# QUICK PING (function)
ping_ssh() {
    ssh -o ConnectTimeout=5 -i "$SSH_ID" -p "$SSH_PORT" "$@" 'echo "Host reachable"'
}

# DECRYPT REMOTE GPG FILE (function)
# Usage: decrypt_remote user@host:/remote/file.gpg /local/dir
decrypt_remote() {
    local remote_file="$1"

    ssh -i "$SSH_ID" -p "$SSH_PORT" "${remote_file%%:*}" "cat ${remote_file#*:}" |
        gpg --decrypt -o "$SSH_TMP/$(basename "${remote_file%.gpg}")"

    log_ssh "Decrypted remote file $remote_file → $SSH_TMP"
}
