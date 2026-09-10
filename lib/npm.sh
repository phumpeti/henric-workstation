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
    npm install \
        --prefix "$(npm_prefix)" \
        -g "$@"
}

npm_path_configured() {
    local bin_dir

    bin_dir=$(npm_bin_dir)

    [[ ":$PATH:" == *":$bin_dir:"* ]]
}
