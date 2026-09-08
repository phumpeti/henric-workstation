#!/usr/bin/env bash

flatpak_is_installed() {
    local package="$1"

    flatpak info "$package" >/dev/null 2>&1
}

flatpak_install() {
    flatpak install -y flathub "$@"
}