#!/usr/bin/env bash

OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

detect_system() {

    [[ -f "$OS_RELEASE_FILE" ]] || return 1

    source "$OS_RELEASE_FILE"

    CPU_ARCH="$(uname -m)"
    OS_ID="$ID"
    OS_VERSION="$VERSION_ID"
    OS_NAME="$PRETTY_NAME"
    OS_CODENAME="$VERSION_CODENAME"

    return 0
}


check_os() {
    section " Operating system"
    detect_system || {
        error " Kan inte identifiera operativsystem ." 
        return 1
    }
    
    if [[ "$OS_ID" != "debian" ]]; then
        error "Endast Debian stöds (hittade "$OS_ID")."
        return 1
    fi
    
    success "$OS_NAME"
    return 0 
}


check_architecture() {

    detect_system || return 1

    case "$CPU_ARCH" in
        x86_64)
            success "Architecture: $CPU_ARCH"
            ;;
        *)
            warn "Architecture $CPU_ARCH is not supported."
            return 1
            ;;
    esac
}

check_sudo() {
    section "Sudo"
    # Finns sudo?
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is not installed."
        return 1
    fi

    success "sudo installed"

    # Är användaren medlem?
    if ! id -nG "$USER" | grep -qw sudo; then
        error "User is not a member of the sudo group."
        return 1
    fi

    success "User belongs to sudo group."

    # Finns en aktiv session?
    if sudo -n true >/dev/null 2>&1; then
        success "sudo session active."
    else
        info "sudo password required."
    fi
}

check_network() {
    section "Network"
    if ping -c1 -W2 deb.debian.org >/dev/null 2>&1; then
        success "Internet connection"
        return 0
    fi

    error "No Internet connection"
        return 1
}

check_package_manager() {
    section "Checking package manager..."
    check_commands "${PACKAGE_MANAGER_COMMANDS[@]}"
}

check_required_commands() {
    section "Checking required commands..."
    check_commands "${REQUIRED_COMMANDS[@]}"
}

print_doctor_summary() {

section "Summary"

printf "%-20s %d\n" "Successful:" "$success_count"
printf "%-20s %d\n" "Information:" "$info_count"
printf "%-20s %d\n" "Warnings:" "$warning_count"
printf "%-20s %d\n" "Errors:" "$error_count"

    if (( error_count == 0 )); then
        success "System ready for installation."
    else
        error "Problems detected."
    fi
DOCTOR_MODE=false    
}
