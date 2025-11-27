#!/bin/zsh

# Ensure archives directory exists
mkdir -p ~/archives

# Create plain tar.gz archives in ~/archives
tar -czf ~/archives/repos-backup-$(date +%Y%m%d).tar.gz ~/repos
tar -czf ~/archives/_meta.repos-backup-$(date +%Y%m%d).tar.gz ~/repos/_meta.repos
tar -czf ~/archives/...me-backup-$(date +%Y%m%d).tar.gz ~/repos/...me
tar -czf ~/archives/.env-backup-$(date +%Y%m%d).tar.gz ~/repos/.env
tar -czf ~/archives/dev-backup-$(date +%Y%m%d).tar.gz ~/repos/dev
