#!/usr/bin/env bash

npm_prefix() {
    printf '%s\n' "$HOME/.local"
}

npm_bin_dir() {
    printf '%s\n' "$HOME/.local/bin"
}

npm_is_installed() {
    local package="$1"

    npm list \
        --prefix "$(npm_prefix)" \
        -g "$package" \
        --depth=0 >/dev/null 2>&1
}

npm_install() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: npm install --prefix "%s" -g %s\n' \
            "$(npm_prefix)" \
            "$*"
        return 0
    fi

    npm install \
        --prefix "$(npm_prefix)" \
        -g "$@"
}

npm_path_configured() {
    local bin_dir

    bin_dir=$(npm_bin_dir)

    [[ ":$PATH:" == *":$bin_dir:"* ]]
}

npm_update() {
    if [[ "${DRY_RUN:-false}" == true ]]
    then
        printf 'DRY RUN: npm update --prefix "%s" -g\n' "$(npm_prefix)"
        return 0
    fi

    npm update \
        --prefix "$(npm_prefix)" \
        -g
}
