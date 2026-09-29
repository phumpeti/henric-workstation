#!/usr/bin/env bash

apt_is_installed() {

    local package="$1"

    dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
        grep -q "install ok installed"
}

apt_install() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: apt-get install -y %s\n' "$*"
        return 0
    fi

    sudo apt-get install -y "$@"
}

apt_update() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: apt-get update && apt-get upgrade -y\n'
        return 0
    fi

    sudo apt-get update &&
        sudo apt-get upgrade -y
}