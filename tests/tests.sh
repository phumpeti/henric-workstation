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

run_get_backend_test() {
    local result

    source ./lib/modules.sh

    result=$(get_backend "/tmp/packages/apt/01-test.txt")

    if [[ "$result" != "apt" ]]
    then
        echo "FAIL: get_backend returnerade '$result' för apt"
        return 1
    fi

    result=$(get_backend "/tmp/packages/flatpak/42-test.txt")

    if [[ "$result" != "flatpak" ]]
    then
        echo "FAIL: get_backend returnerade '$result' för flatpak"
        return 1
    fi

    result=$(get_backend "/tmp/packages/npm/99-test.txt")

    if [[ "$result" != "npm" ]]
    then
        echo "FAIL: get_backend returnerade '$result' för npm"
        return 1
    fi

    echo "OK: get_backend identifierar backend korrekt"
}

run_supported_backend_test() {
    source ./lib/modules.sh

    for backend in apt flatpak npm
    do
        if ! is_supported_backend "$backend"
        then
            echo "FAIL: $backend borde vara en stödd backend"
            return 1
        fi
    done

    for backend in unknown java docker
    do
        if is_supported_backend "$backend"
        then
            echo "FAIL: $backend borde inte vara en stödd backend"
            return 1
        fi
    done

    echo "OK: is_supported_backend hanterar stödda och okända backends"
}

run_read_module_test() {
    local test_file
    local output

    test_file=$(mktemp)

    cat > "$test_file" <<'EOF'
git

# Kommentar
curl
    # Indragen kommentar

wget
EOF

    output=$(read_module "$test_file")

    rm "$test_file"

    if [[ "$output" != $'git\ncurl\nwget' ]]
    then
        echo "FAIL: read_module filtrerar paketlistan fel"
        return 1
    fi

    echo "OK: read_module läser paket och ignorerar tomma rader/kommentarer"
}

run_find_modules_test() {
    local test_dir
    local output
    local files

    test_dir=$(mktemp -d)

    touch "$test_dir/01-first.txt"
    touch "$test_dir/02-second.txt"
    mkdir "$test_dir/subdir"
    touch "$test_dir/subdir/03-hidden.txt"

    output=$(find_modules "$test_dir")

    files=$(basename -a $output)

    rm -rf "$test_dir"

    if [[ "$files" != $'01-first.txt\n02-second.txt' ]]
    then
        echo "FAIL: find_modules hittade fel filer"
        return 1
    fi

    echo "OK: find_modules hittar endast moduler på rätt nivå"
}

run_count_modules_test() {
    local test_dir
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/flatpak"

    touch "$test_dir/apt/01-one.txt"
    touch "$test_dir/apt/02-two.txt"
    touch "$test_dir/apt/03-three.txt"

    touch "$test_dir/flatpak/01-four.txt"

    result=$(count_modules "$test_dir")

    rm -rf "$test_dir"

    if [[ "$result" != "4" ]]
    then
        echo "FAIL: count_modules returnerade '$result', förväntade 4"
        return 1
    fi

    echo "OK: count_modules räknar moduler korrekt"
}

run_process_modules_test() {
    local test_dir
    local output
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/flatpak"

    touch "$test_dir/apt/01-one.txt"
    touch "$test_dir/apt/02-two.txt"
    touch "$test_dir/flatpak/01-three.txt"

    test_callback() {
        printf '%s\n' "$(basename "$1")"
        return 0
    }

    output=$(process_modules "$test_dir" test_callback)
    result=$?

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "FAIL: process_modules returnerade status $result"
        return 1
    fi

    if [[ "$output" != $'01-one.txt\n02-two.txt\n01-three.txt' ]]
    then
        echo "FAIL: process_modules skickade fel moduler till callback"
        return 1
    fi

    echo "OK: process_modules använder callback korrekt"
}

run_process_modules_failure_test() {
    local test_dir
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    touch "$test_dir/apt/01-ok.txt"
    touch "$test_dir/apt/02-fail.txt"

    test_callback() {
        local module="$1"

        if [[ "$(basename "$module")" == "02-fail.txt" ]]
        then
            return 1
        fi

        return 0
    }

    set +e
    process_modules "$test_dir" test_callback
    result=$?
    set -e

    rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "FAIL: process_modules propagerade inte callback-felet"
        return 1
    fi

    echo "OK: process_modules propagerar callback-fel"
}

run_process_module_test() {
    local test_dir
    local module
    local output
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    module="$test_dir/apt/01-test.txt"

    cat > "$module" <<'EOF'
paket-som-inte-finns
EOF

    set +e
   output=$(
    DRY_RUN=true \
    bash -c '
        source ./bootstrap.sh >/dev/null 2>&1
        source ./lib/repositories.sh
        process_module "$1"
    ' -- "$module"
    )
    result=$?
    set -e

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "FAIL: process_module returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"Backend: apt"* ]]
    then
        echo "FAIL: process_module identifierade inte APT"
        return 1
    fi

    if [[ "$output" != *"Saknas: paket-som-inte-finns"* ]]
    then
        echo "FAIL: process_module identifierade inte saknat paket"
        return 1
    fi

    if [[ "$output" != *"DRY RUN:"* ]]
    then
        echo "FAIL: process_module körde inte dry-run"
        return 1
    fi

    echo "OK: process_module hanterar saknat paket i dry-run"
}


run_named_module_test
run_backend_function_test
run_get_backend_test
run_supported_backend_test
run_read_module_test
run_find_modules_test
run_count_modules_test
run_process_modules_test
run_process_modules_failure_test
run_process_module_test