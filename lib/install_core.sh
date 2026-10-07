#!/usr/bin/env bash

# Ansvar:
# - tillhandahålla installationskommandon
# - delegera modulinstallation till modulsystemet

install_all_modules() {
    process_modules "$PACKAGE_DIR" process_module
}

install_named_module() {
    local name="$1"
    local modules
    local module
    local status=0

    modules=$(find_module "$name") || true

    if [[ -z "$modules" ]]; then
        error "Modulen '$name' finns inte."
        return "$EXIT_BAD_ARGUMENTS"
    fi

    while IFS= read -r module
    do
        if ! process_module "$module"; then
            status=1
        fi
    done <<< "$modules"

    return "$status"
}
