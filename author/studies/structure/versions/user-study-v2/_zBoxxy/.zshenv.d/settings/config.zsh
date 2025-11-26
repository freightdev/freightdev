#!  ╔══════════════════════════════════════════╗
#?    Config Settings - Environment Source (Zsh)  
#!  ╚══════════════════════════════════════════╝


#* ==== MAIN PATHS/SETTINGS ==== *#
: "${HOME_DIR:=$HOME}"
: "${MAIN_DIR:=$HOME_DIR/main}"
: "${VENV_DIR:=$MAIN_DIR/venv}"
: "${DATA_DIR:=$MAIN_DIR/data}"


#* ==== ENV PATHS/SETTINGS ==== *#
: "${ENV_DIR:=$VENV_DIR/.zshenv.d}"
: "${ENV_SRC:=$HOME_DIR/.zshrc}"


#* ==== DATA PATHS/SETTINGS ==== *#
: "${ARC_DIR:=$DATA_DIR/archives}"
: "${BAK_DIR:=$DATA_DIR/backups}"
: "${SRC_DIR:=$DATA_DIR/resources}"
: "${LOG_DIR:=$DATA_DIR/journals}"

: "${LOG_ARC:=$LOG_DIR/.archive.log}"
: "${LOG_BAK:=$LOG_DIR/.backup.logs}"

: "${COMPRESS_FORMAT:=tar.gz}"               # Options: tar.gz, tar.xz, zip, 7z
: "${COMPRESS_LEVEL:=9}"                     # Compression level (1-9)

#* ==== LOG PATHS/SETTINGS ==== *#
: "${BAK_LOG:=$LOG_DIR/.backup.logs}"

#* ==== NETWORK PATHS/SETTINGS ==== *#
: "${HTTP_PROXY="http://127.0.0.1:3128"}"
: "${HTTPS_PROXY="https://127.0.0.1:3128"}"
: "${NO_PROXY="localhost,127.0.0.1"}"



: "${COMPRESS_FORMAT:=tar.gz}"               # Options: tar.gz, tar.xz, zip, 7z
: "${COMPRESS_LEVEL:=9}"                     # Compression level (1-9)



#* ==== SECURE PATHS/SETTINGS ==== *#
: "${SSH_KEY:=$HOME/.ssh}"                    # [expires: 2026-08-07]
: "${GPG_KEY:=$HOME/.gnupg}"                  # [expires: N/A]
: "${SSH_LOG:=$HOME/.ssh/ssh_helper.log}"
: "${SSH_TMP:=$HOME/.ssh/.sync_tmp}"
: "${SSH_ID:=$HOME/.ssh/id_rsa}"
: "${SSH_USER:=$USER}"
: "${SSH_PORT:=22}"


