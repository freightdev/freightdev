#!/bin/bash
# identify_package_manager.sh - Detect OS and package manager
# Returns: package_manager, os_type, os_version, install_cmd, update_cmd

identify_os() {
    local os_type=""
    local os_version=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
        
        # Check for specific distro
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            os_version="$ID"
        elif [ -f /etc/redhat-release ]; then
            os_version="rhel"
        elif [ -f /etc/debian_version ]; then
            os_version="debian"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
        os_version=$(sw_vers -productVersion)
        
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        os_type="windows"
        
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        os_type="freebsd"
    fi
    
    echo "$os_type:$os_version"
}

detect_package_manager() {
    local pkg_mgr=""
    local install_cmd=""
    local update_cmd=""
    local search_cmd=""
    local remove_cmd=""
    
    # Check in order of preference/commonality
    if command -v apt-get &> /dev/null; then
        pkg_mgr="apt"
        install_cmd="apt-get install -y"
        update_cmd="apt-get update && apt-get upgrade -y"
        search_cmd="apt-cache search"
        remove_cmd="apt-get remove -y"
        
    elif command -v apt &> /dev/null; then
        pkg_mgr="apt"
        install_cmd="apt install -y"
        update_cmd="apt update && apt upgrade -y"
        search_cmd="apt search"
        remove_cmd="apt remove -y"
        
    elif command -v dnf &> /dev/null; then
        pkg_mgr="dnf"
        install_cmd="dnf install -y"
        update_cmd="dnf upgrade -y"
        search_cmd="dnf search"
        remove_cmd="dnf remove -y"
        
    elif command -v yum &> /dev/null; then
        pkg_mgr="yum"
        install_cmd="yum install -y"
        update_cmd="yum update -y"
        search_cmd="yum search"
        remove_cmd="yum remove -y"
        
    elif command -v pacman &> /dev/null; then
        pkg_mgr="pacman"
        install_cmd="pacman -S --noconfirm"
        update_cmd="pacman -Syu --noconfirm"
        search_cmd="pacman -Ss"
        remove_cmd="pacman -R --noconfirm"
        
    elif command -v zypper &> /dev/null; then
        pkg_mgr="zypper"
        install_cmd="zypper install -y"
        update_cmd="zypper update -y"
        search_cmd="zypper search"
        remove_cmd="zypper remove -y"
        
    elif command -v brew &> /dev/null; then
        pkg_mgr="brew"
        install_cmd="brew install"
        update_cmd="brew update && brew upgrade"
        search_cmd="brew search"
        remove_cmd="brew uninstall"
        
    elif command -v port &> /dev/null; then
        pkg_mgr="macports"
        install_cmd="port install"
        update_cmd="port selfupdate && port upgrade outdated"
        search_cmd="port search"
        remove_cmd="port uninstall"
        
    elif command -v pkg &> /dev/null; then
        pkg_mgr="pkg"
        install_cmd="pkg install -y"
        update_cmd="pkg update && pkg upgrade -y"
        search_cmd="pkg search"
        remove_cmd="pkg delete -y"
        
    elif command -v apk &> /dev/null; then
        pkg_mgr="apk"
        install_cmd="apk add"
        update_cmd="apk update && apk upgrade"
        search_cmd="apk search"
        remove_cmd="apk del"
        
    elif command -v choco &> /dev/null; then
        pkg_mgr="chocolatey"
        install_cmd="choco install -y"
        update_cmd="choco upgrade all -y"
        search_cmd="choco search"
        remove_cmd="choco uninstall -y"
        
    elif command -v winget &> /dev/null; then
        pkg_mgr="winget"
        install_cmd="winget install"
        update_cmd="winget upgrade --all"
        search_cmd="winget search"
        remove_cmd="winget uninstall"
    fi
    
    echo "$pkg_mgr|$install_cmd|$update_cmd|$search_cmd|$remove_cmd"
}

# Check if we need sudo
needs_sudo() {
    local pkg_mgr="$1"
    
    # Brew and chocolatey don't need sudo
    if [[ "$pkg_mgr" == "brew" ]] || [[ "$pkg_mgr" == "chocolatey" ]] || [[ "$pkg_mgr" == "winget" ]]; then
        echo "no"
        return
    fi
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "no"
    else
        echo "yes"
    fi
}

# Main execution
main() {
    local format="${1:-env}"  # env, json, or shell
    
    # Get OS info
    local os_info=$(identify_os)
    local os_type=$(echo "$os_info" | cut -d':' -f1)
    local os_version=$(echo "$os_info" | cut -d':' -f2)
    
    # Get package manager info
    local pkg_info=$(detect_package_manager)
    local pkg_mgr=$(echo "$pkg_info" | cut -d'|' -f1)
    local install_cmd=$(echo "$pkg_info" | cut -d'|' -f2)
    local update_cmd=$(echo "$pkg_info" | cut -d'|' -f3)
    local search_cmd=$(echo "$pkg_info" | cut -d'|' -f4)
    local remove_cmd=$(echo "$pkg_info" | cut -d'|' -f5)
    
    # Check sudo requirement
    local sudo_required=$(needs_sudo "$pkg_mgr")
    local sudo_prefix=""
    [ "$sudo_required" = "yes" ] && sudo_prefix="sudo "
    
    # Output in requested format
    case "$format" in
        json)
            cat << EOF
{
  "os_type": "$os_type",
  "os_version": "$os_version",
  "package_manager": "$pkg_mgr",
  "install_command": "${sudo_prefix}${install_cmd}",
  "update_command": "${sudo_prefix}${update_cmd}",
  "search_command": "$search_cmd",
  "remove_command": "${sudo_prefix}${remove_cmd}",
  "needs_sudo": "$sudo_required"
}
EOF
            ;;
        shell)
            cat << EOF
PKG_MGR="$pkg_mgr"
OS_TYPE="$os_type"
OS_VERSION="$os_version"
INSTALL_CMD="${sudo_prefix}${install_cmd}"
UPDATE_CMD="${sudo_prefix}${update_cmd}"
SEARCH_CMD="$search_cmd"
REMOVE_CMD="${sudo_prefix}${remove_cmd}"
NEEDS_SUDO="$sudo_required"
EOF
            ;;
        env|*)
            echo "PKG_MGR=$pkg_mgr"
            echo "OS_TYPE=$os_type"
            echo "OS_VERSION=$os_version"
            echo "INSTALL_CMD=${sudo_prefix}${install_cmd}"
            echo "UPDATE_CMD=${sudo_prefix}${update_cmd}"
            echo "SEARCH_CMD=$search_cmd"
            echo "REMOVE_CMD=${sudo_prefix}${remove_cmd}"
            echo "NEEDS_SUDO=$sudo_required"
            ;;
    esac
}

# If sourced, export function; if executed, run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
