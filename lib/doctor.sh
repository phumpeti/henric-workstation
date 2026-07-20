#!/usr/bin/env bash

doctor() {

    banner

    info "Running diagnostics..."
    echo

    check_project
    check_environment
    check_commands
    check_shellcheck

    check_network

    check_apt

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
