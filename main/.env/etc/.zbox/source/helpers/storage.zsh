#!  ╔════════════════════════════════════════════╗
#?    Storage Helpers - Environment Source (Zsh)  
#!  ╚════════════════════════════════════════════╝

disk_usage() {
    local opt="$1"
    case "$opt" in
        -t|--total)
            echo "=== Total Disk Usage ==="
            df -h --total
            ;;
        -d|--dir)
            echo "=== Directory Disk Usage ==="
            if compgen -G "*" > /dev/null; then
                du -sh * 2>/dev/null | sort -hr
            else
                echo "No files or directories found in current directory"
            fi
            ;;
        *)
            echo "Usage: disk_usage [-t|--total] [-d|--dir]"
            return 1
            ;;
    esac

    echo
    echo "Scan completed at: $(date "+%d-%m-%Y %H:%M:%S")"
}
