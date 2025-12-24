#!  ╔════════════════════════════════════════════╗
#?    Archive Helpers - Environment Source (Zsh)  
#!  ╚════════════════════════════════════════════╝

# Defaults (override by loading custom env if needed)
: "${ARCHIVE_DIR:=$HOME/data/archives}"
: "${ARCHIVE_LOG:=$ARCHIVE_LOG/.archive.logs}"
: "${GPG_KEYS:=$HOME/.gnupg}"         # custom gpg keys
: "${COMPRESS_FORMAT:=tar.gz}"        # default format
: "${COMPRESS_LEVEL:=6}"              # default compression level

# ----------------------------------------
# Logging
# ----------------------------------------
log_archive() {
    print -r -- "$(date +"%Y-%m-%d %H:%M:%S") - $1" >>"$ARCHIVE_LOG"
}

# ----------------------------------------
# Compress a directory or file
# Usage: compress <source> [destination] [format] [encrypt: yes/no]
# ----------------------------------------
compress() {
    local src=$1
    local fmt=${3:-$COMPRESS_FORMAT}
    local dest=${2:-$ARCHIVE_DIR/${src:t}.${fmt}}
    local encrypt=${4:-no}
    
    mkdir -p "$ARCHIVE_DIR"

    [[ -z $src ]] && print -u2 "Error: no source provided" && return 1
    [[ ! -e $src ]] && print -u2 "Error: source not found: $src" && return 1

    case $fmt in
        tar.gz) tar -czf "$dest" -C "${src:h}" "${src:t}" ;;
        tar.xz) tar -cJf "$dest" -C "${src:h}" "${src:t}" ;;
        zip)    zip -qr -"${COMPRESS_LEVEL}" "$dest" "$src" ;;
        7z)     7z a -mx="$COMPRESS_LEVEL" "$dest" "$src" >/dev/null ;;
        *)
        print -u2 "Error: unknown format: $fmt"
        return 1
        ;;
    esac

    if [[ $encrypt == (yes|[Yy]|true) ]]; then
        local enc_file=${dest}.gpg
        if [[ -n $GPG_KEY ]]; then
            gpg --yes --output "$enc_file" --encrypt --recipient "$GPG_KEY" "$dest" || return 1
        else
            gpg --yes --symmetric --cipher-algo AES256 --output "$enc_file" "$dest" || return 1
        fi
        rm -f -- "$dest"
        dest=$enc_file
    fi

    log_archive "Compressed $src → $dest"
    print "✅ Compressed $src → $dest"
}

# ----------------------------------------
# Extract an archive
# Usage: extract <archive> [destination] [decrypt: yes/no]
# ----------------------------------------
extract() {
    local archive=$1
    local dest=${2:-${archive:h}}
    local decrypt=${3:-no}

    [[ -z $archive ]] && print -u2 "Error: no archive provided" && return 1
    [[ ! -f $archive ]] && print -u2 "Error: archive not found: $archive" && return 1

    mkdir -p "$dest"

    if [[ $decrypt == (yes|[Yy]|true) && $archive == *.gpg ]]; then
        local decrypted=$dest/${archive:t:r}
        gpg --yes --output "$decrypted" --decrypt "$archive" || return 1
        archive=$decrypted
    fi

    case $archive in
        *.tar.bz2|*.tbz2) tar -xjf "$archive" -C "$dest" ;;
        *.tar.gz|*.tgz)   tar -xzf "$archive" -C "$dest" ;;
        *.tar.xz|*.txz)   tar -xJf "$archive" -C "$dest" ;;
        *.tar)            tar -xf "$archive" -C "$dest" ;;
        *.zip)            unzip -q "$archive" -d "$dest" ;;
        *.7z)             7z x "$archive" -o"$dest" >/dev/null ;;
        *.gz)             gunzip -k -f "$archive" ;;
        *.xz)             unxz -k -f "$archive" ;;
        *.rar)            unrar e -inul "$archive" "$dest" ;;
        *.Z)              uncompress "$archive" ;;
        *.exe)            cabextract -d "$dest" "$archive" ;;
        *)
        print -u2 "Error: unsupported archive type: $archive"
        return 1
        ;;
    esac

    log_archive "Extracted $archive → $dest"
    print "✅ Extracted $archive → $dest"
}

# ----------------------------------------
# List archive contents
# Usage: list_archive <archive>
# ----------------------------------------
list_archive() {
    local archive=$1
    [[ -z $archive ]] && print -u2 "Error: no archive provided" && return 1
    [[ ! -f $archive ]] && print -u2 "Error: archive not found: $archive" && return 1

    case $archive in
        *.tar.gz|*.tgz) tar -tzf "$archive" ;;
        *.tar.xz|*.txz) tar -tJf "$archive" ;;
        *.tar.bz2|*.tbz2) tar -tjf "$archive" ;;
        *.zip) unzip -l "$archive" ;;
        *.7z) 7z l "$archive" ;;
        *)
        print -u2 "Error: unsupported archive type for listing: $archive"
        return 1
        ;;
    esac
}
