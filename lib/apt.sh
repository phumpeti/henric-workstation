#!/usr/bin/env bash

apt_is_installed() {

    local package="$1"

    dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
        grep -q "install ok installed"
}

apt_install() {
    sudo apt-get install -y "$@"
}