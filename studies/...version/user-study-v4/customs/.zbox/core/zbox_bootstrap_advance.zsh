#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝

source zbox_system_init.zsh
source zbox_git_repos.zsh
source zbox_git_repos.zsh

#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- Main Loader --- !#
bootstrap() {
    #* --- Parse flags before the case statement --- *#
    FORCE_YES=false
    INTERACTIVE=false
    
    while [[ "$1" == -* ]]; do
        case "$1" in
            --force|-f) FORCE_YES=true; shift ;;
            --interactive|-i) INTERACTIVE=true; shift ;;
            --help|-h) 
                cat <<EOF
Usage: main [options] [command]

Options:
    -f, --force        Force yes to all prompts (non-interactive)
    -i, --interactive  Enable interactive mode
    -h, --help         Show this help message

Commands:
    setup              Run all components (init, repo, env) [default]
    init               Run system initialization only
    repo               Run git repository cloning only
    envs               Run environment loading only

Examples:
    main                    # Run all components interactively
    main --force setup      # Run all components non-interactively
    main -i init            # Run only system init interactively
    main --force repo       # Run only repo cloning non-interactively
EOF
                return 0
                ;;
            --) shift; break ;;  # End of options
            -*) 
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done
    
    # Export variables so subfunctions can access them
    export FORCE_YES INTERACTIVE
    
    case "${1:-setup}" in
        setup|"") 
            log_info "Running complete setup: system initialization, git repos, and environment loading"
            system_init && git_repos && load_envs
            ;;
        init) 
            log_info "Running system initialization only"
            system_init
            ;;
        repo) 
            log_info "Running git repository operations only"
            git_repos
            ;;
        envs) 
            log_info "Running environment loading only"
            load_envs
            ;;
        *) 
            echo "Error: Unknown command '$1'" >&2
            echo "Use 'main --help' for usage information" >&2
            return 1
            ;;
    esac
}
