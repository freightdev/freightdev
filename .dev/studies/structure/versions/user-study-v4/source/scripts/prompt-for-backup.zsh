#!       Prompt for Backups
# ================================
prompt "Would you like to backup $(basename "$ENV_DIR")? (y/N) " CONFIRM
if [[ "$CONFIRM" == [yY] ]]; then
    mkdir -p "$(dirname "${ENV_DIR}-${TS}")"
    cp -r "$ENV_DIR" "${ENV_DIR}-${TS}"
    log_set "Backup created at $(dirname "$ENV_DIR-$TS")"
else
    log_warn "Skipped backup generator..."
fi