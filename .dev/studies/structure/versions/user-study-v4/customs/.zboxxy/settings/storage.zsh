#*  ╔═══════════════════╗
#?      Storage Settings     
#*  ╚═══════════════════╝

#!     STORAGE CONFIGURATIONS
# ================================
: "${ARC_DIR:=$DATA_DIR/archives}"
: "${BAK_DIR:=$DATA_DIR/backups}"
: "${SRC_DIR:=$DATA_DIR/sources}"
: "${LOG_DIR:=$DATA_DIR/logs}"
: "${LOG_ARC:=$DATA_DIR/.archive.log}"
: "${LOG_BAK:=$DATA_DIR/.backup.logs}"
: "${COMPRESS_FORMAT:=tar.gz}"  #? <===== Options: tar.gz, tar.xz, zip, 7z
: "${COMPRESS_LEVEL:=9}"  #? <=====       Compression level (1-9)