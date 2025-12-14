#! /usr/bin/env zsh
#  ╔═════════════════════════╗
#?   ZBox Bootstrap - v1.0.0
#  ╚═════════════════════════╝


#! --- Helpers --- !#
log_info()  { print -P "%F{blue}[INFO]%f $*"; }
log_warn()  { print -P "%F{yellow}[WARN]%f $*"; }
log_error() { print -P "%F{red}[ERROR]%f $*"; }
log_ok()    { print -P "%F{green}[OK]%f $*"; }


#! --- System Initiation --- !#
system_init() {
    log_info "#! === System Initiation Process === !#"

    # required baseline
    local required=(grep cut cat find wc git ssh gpg)
    local missing=()

    # check
    for tool in $required; do
        if ! command -v $tool >/dev/null 2>&1; then
            log_warn "Missing: $tool"
            missing+=$tool
        fi
    done

    if (( $#missing )); then
        log_info "Detected missing tools: $missing"

        # detect OS
        local os_type="unknown"
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            case "$ID" in
                arch|manjaro|endeavouros) os_type="arch" ;;
                debian|ubuntu|mint|pop)   os_type="debian" ;;
                alpine)                   os_type="alpine" ;;
                fedora|rhel|centos)       os_type="redhat" ;;
            esac
        fi

        log_info "Using package manager: $os_type"

        # try to install
        case "$os_type" in
            arch)   sudo pacman -Sy --noconfirm coreutils git gnupg openssh ;;
            debian) sudo apt update && sudo apt install -y coreutils git gnupg openssh-client ;;
            alpine) sudo apk add coreutils git gnupg openssh ;;
            redhat) sudo dnf install -y coreutils git gnupg openssh ;;
            *) log_error "Unsupported OS: manual install required for $missing"; return 1 ;;
        esac
    else
        log_ok "All required tools are present."
    fi

    # create zbox skeleton
    mkdir -p ~/.zbox/{bin,etc,var/logs,zboxxies}
    log_ok "ZBox directories initialized."
}
