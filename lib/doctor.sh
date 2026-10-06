#!/usr/bin/env bash

DOCTOR_MODE=true

doctor() {

    banner

    section "Running diagnostics..."
    check_os
    check_architecture
    check_sudo
    check_network
    check_package_manager
    check_required_commands
    check_project
    print_doctor_summary
}

check_file() {

    local file="$1"

    if [[ -f "$file" ]]; then
        success "$(basename "$file")"
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

    section "Checking necessary files and directories" 

    check_file "$SCRIPT_DIR/VERSION"
    check_file "$SCRIPT_DIR/CHANGELOG.md"
    check_file "$SCRIPT_DIR/bootstrap.sh"
    check_file "$SCRIPT_DIR/README.md"

    check_directory "$SCRIPT_DIR/packages"
    check_directory "$SCRIPT_DIR/lib"
}
