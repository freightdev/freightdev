#!  ╔════════════════════════════════════════════╗
#?    History Helpers - Environment Source (Zsh)  
#!  ╚════════════════════════════════════════════╝

# History cleanup
history_cleanup() {
    local tmpfile=$(mktemp)
    tac "$HISTFILE" | awk '!seen[$0]++' | tac >"$tmpfile" && mv "$tmpfile" "$HISTFILE"
    echo "History cleaned: $(wc -l <"$HISTFILE") unique entries"
}

# History statistics
history_stats() {
    echo "History file: $HISTFILE"
    echo "Total entries: $(wc -l <"$HISTFILE")"
    echo "Most used commands:"
    history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
}

# History backup
history_backup() {
    local backup_file="${HISTFILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HISTFILE" "$backup_file"
    echo "History backed up to: $backup_file"
}
