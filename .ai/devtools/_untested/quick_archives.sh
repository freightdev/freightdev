#!/bin/zsh

# Ensure archives directory exists
mkdir -p ~/archives

# Create plain tar.gz archives in ~/archives
tar -czf ~/archives/source-v3-backup-$(date +%Y%m%d).tar.gz ~/source-v3
