#!/usr/bin/env bash

# Ansvar:
# - tillhandahålla installationskommandon
# - delegera modulinstallation till modulsystemet

install_all_modules() {
    process_modules "$PACKAGE_DIR" process_module
}

install_named_module() {

    local name="$1"
    local module

    module=$(find_module "$name")

    if [[ -z "$module" ]]; then
        error "Modulen '$name' finns inte."
        return "$EXIT_BAD_ARGUMENTS"
    fi

    process_module "$module"
}