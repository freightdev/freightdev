#!  ╔═══════════════════════════════════════════╗
#?    Backup Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Defaults (override by loading custom env if needed)
: "${BACKUP_DIR:=$HOME/data/backups}"
: "${BACKUP_LOG:=$BACKUP_DIR/.backup.logs}"
: "${GPG_KEY:=$HOME/.gnupg}"                 # custom gpg key

# ----------------------------------------
# Logging
# ----------------------------------------
log_backup() {
    print -r -- "$(date +"%Y-%m-%d %H:%M:%S") - $1" >>"$BACKUP_LOG"
}

# ----------------------------------------
# Backup Helper
# Usage: backup <source> [dest_dir] [encrypt: yes/no]
# ----------------------------------------
backup() {
    local source=$1
    local dest_dir=${2:-$BACKUP_DIR}
    local encrypt=${3:-yes}

    [[ -z $source ]] && print -u2 "Error: no source provided" && return 1
    [[ ! -e $source ]] && print -u2 "Error: source not found: $source" && return 1
    
    mkdir -p "$BACKUP_DIR"

    local base_name=${source:t}
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file=$dest_dir/${base_name}-backup-${timestamp}.tar.gz

    # Create archive
    tar -czf "$backup_file" -C "${source:h}" "$base_name" || {
        print -u2 "Error: tar failed"
        return 1
    }

    # Encrypt if requested
    if [[ $encrypt == (yes|y|true) ]]; then
        local enc_file=${backup_file}.gpg
        if [[ -n $GPG_KEY ]]; then
            gpg --yes --output "$enc_file" --encrypt --recipient "$GPG_KEY" "$backup_file" || return 1
        else
            gpg --yes --symmetric --cipher-algo AES256 --output "$enc_file" "$backup_file" || return 1
        fi
        rm -f -- "$backup_file"
        backup_file=$enc_file
    fi

    log_backup "Backup created: $backup_file"
    print "✅ Backup created: $backup_file"
}

# ----------------------------------------
# Recover Helper
# Usage: recover <backup_file> [dest_dir]
# ----------------------------------------
recover() {
    local backup_file=$1
    local dest_dir=${2:-$PWD}

    [[ -z $backup_file ]] && print -u2 "Error: no backup file provided" && return 1
    [[ ! -f $backup_file ]] && print -u2 "Error: file not found: $backup_file" && return 1

    mkdir -p "$dest_dir"

    if [[ $backup_file == *.gpg ]]; then
        gpg --quiet --decrypt "$backup_file" | tar -xzf - -C "$dest_dir" || return 1
    else
        tar -xzf "$backup_file" -C "$dest_dir" || return 1
    fi

    log_backup "Backup recovered: $backup_file → $dest_dir"
    print "✅ Backup recovered: $backup_file → $dest_dir"
}

# ----------------------------------------
# List backups Helper
# Usage: list_backup [dir]
# ----------------------------------------
list_backup() {
    local dir=${1:-$BACKUP_DIR}
    [[ ! -d $dir ]] && print "No backups found in $dir" && return 1
    ls -1 -- "$dir"
}
