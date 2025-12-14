#*  ╔═════════════════════╗
#?      Secret Settings     
#*  ╚═════════════════════╝


#!      Secret Configurations
#? ================================
: "${SSH_DIR:=$HOME_DIR/.ssh}"  #? <=====   [expires: 2026-08-07]
: "${GPG_DIR:=$HOME_DIR/.gnupg}"  #? <===== [expires: N/A]

: "${SSH_LOG:=$SSH_DIR/ssh_helper.log}"
: "${SSH_TMP:=$SSH_DIR/.sync_tmp}"
: "${SSH_ID:=$SSH_DIR/id_rsa}"
: "${SSH_USER:=$USER}"
: "${SSH_PORT:=22}"