#!/bin/zsh

BACKUP_DIR=~/backups
mkdir -p $BACKUP_DIR

main=(~/main ~/main/_index.main ~/main/...me ~/main/.env ~/main/dev)

for repo in $main; do
    name=$(basename $repo)
    tar -czf - $repo | gpg --cipher-algo AES256 --compress-algo 1 --symmetric --output $BACKUP_DIR/${name}-backup-$(date +%Y%m%d).tar.gz.gpg
done
