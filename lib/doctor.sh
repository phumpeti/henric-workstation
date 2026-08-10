#!/usr/bin/env bash

passed_checks=0
info_checks=0
warning_checks=0
failed_checks=0


doctor() {

    banner

    info "Running diagnostics..."
    echo
    check_os
    check_architecture
    check_sudo
    check_network
    check_package_manager
    check_required_commands
}



run_check() {

    local check="$1"

    if "$check"; then
        ((doctor_ok++))
    else
        ((doctor_failed++))
    fi

}

check_shellcheck() {

    command -v shellcheck >/dev/null 2>&1

}

check_file() {

    local file="$1"

    if [[ -f "$file" ]]; then
        success "$(basename "$file")"
        (( passed_checks++))
    else
        error "Saknar $(basename "$file")"
        return 1
    fi

}

check_directory() {

    local dir="$1"

    if [[ -d "$dir" ]]; then
        success "$(basename "$dir")/"
    else
        error "Saknar $(basename "$dir")/"
        return 1
    fi

}

check_project() {

    check_file "$SCRIPT_DIR/VERSION"
    check_file "$SCRIPT_DIR/CHANGELOG.md"
    check_file "$SCRIPT_DIR/bootstrap.sh"

    check_directory "$SCRIPT_DIR/packages"
    check_directory "$SCRIPT_DIR/lib"
    check_directory "$SCRIPT_DIR/config"
}
