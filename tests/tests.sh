#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$0")/.."

run_named_module_test() {
    local output

    output=$(DRY_RUN=true bash -c 'source ./bootstrap.sh >/dev/null 2>&1; install_named_module multimedia' 2>&1)

    if [[ "$output" == *"name: command not found"* ]]; then
        echo "FAIL: install_named_module körde ett ogiltigt kommando"
        return 1
    fi

    echo "OK: install_named_module hanterar dry-run utan fel"
}

run_named_module_test
