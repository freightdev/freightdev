#!/bin/zsh

# Ensure archives directory exists
mkdir -p ~/backup/archives

# Create plain tar.gz archives in ~/archives
tar -czf ~/backup/archives/main-backup-$(date +%Y%m%d).tar.gz ~/main
tar -czf ~/backup/archives/.zshrc.d-backup-$(date +%Y%m%d).tar.gz ~/.zshrc.d