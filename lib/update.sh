#!/usr/bin/env bash

# Ansvar:
# - samordna uppdateringar för samtliga backends

update_system() {
    local failed=0

    load_backends || return 1

    if ! apt_update
    then
        error "APT-uppdateringen misslyckades."
        failed=1
    fi

    if ! flatpak_update
    then
        error "Flatpak-uppdateringen misslyckades."
        failed=1
    fi

    if ! npm_update
    then
        error "npm-uppdateringen misslyckades."
        failed=1
    fi

    return "$failed"
}