#!/usr/bin/env bash

flatpak_is_installed() {
    local package="$1"

    flatpak info "$package" >/dev/null 2>&1
}

flatpak_install() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: flatpak install -y flathub %s\n' "$*"
        return 0
    fi

    flatpak install -y flathub "$@"
}

flatpak_update() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: flatpak update -y\n'
        return 0
    fi

    flatpak update -y
}