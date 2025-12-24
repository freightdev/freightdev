#!  ╔═══════════════════════════════════════════╗
#?    Source Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝


#* Source Directory Files 
source() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        echo "[WARN] Directory not found: $dir"
        return 1
    fi

    for rf in "$dir"/*.zsh(N); do
        local basename="$(basename "$rf")"

        if [[ -f "$rf" && -r "$rf" \
            && ! " ${environment_files[@]} " == *" $basename "* \
            && ! " ${ignore_files[@]} " == *" $basename "* ]]; then
            ((LOADED_COUNT++))
            log_loading "[$LOADED_COUNT] $basename..."
            source "$rf"
        fi
    done
}