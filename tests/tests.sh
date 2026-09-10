#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$0")/.."

run_named_module_test() {
    local output

    if output=$(DRY_RUN=true bash -c '
        source ./bootstrap.sh >/dev/null 2>&1
        set +e
        install_named_module media
    ' 2>&1)
    then
        :
    else
        echo "FAIL: install_named_module misslyckades"
        return 1
    fi

    if [[ "$output" == *"command not found"* ]]
    then
        echo "FAIL: install_named_module körde ett ogiltigt kommando"
        return 1
    fi

    echo "OK: install_named_module hanterar dry-run utan fel"
}



run_backend_function_test() {
    local functions

    source ./bootstrap.sh >/dev/null 2>&1

    functions=$(get_backend_functions apt)

    if [[ "$functions" != $'apt_is_installed\napt_install' ]]
    then
        echo "FAIL: APT-backend returnerar fel funktioner"
        return 1
    fi

    functions=$(get_backend_functions flatpak)

    if [[ "$functions" != $'flatpak_is_installed\nflatpak_install' ]]
    then
        echo "FAIL: Flatpak-backend returnerar fel funktioner"
        return 1
    fi

    functions=$(get_backend_functions npm)

    if [[ "$functions" != $'npm_is_installed\nnpm_install' ]]
    then
        echo "FAIL: npm-backend returnerar fel funktioner"
        return 1
    fi

    echo "OK: get_backend_functions returnerar rätt funktioner"
}

run_named_module_test
run_backend_function_test
