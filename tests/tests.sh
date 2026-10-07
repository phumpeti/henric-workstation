#!/usr/bin/env bash

set -Eeuo pipefail

declare -i TEST_NUMBER=0

next_test() {
    ((++TEST_NUMBER))
}

cd "$(dirname "$0")/.."

run_named_module_test() {
   next_test
    local output

    if output=$(DRY_RUN=true bash -c '
        source ./bootstrap.sh >/dev/null 2>&1
        set +e
        install_named_module media
    ' 2>&1)
    then
        :
    else
        echo "[$TEST_NUMBER] FAIL: install_named_module misslyckades"
        return 1
    fi

    if [[ "$output" == *"command not found"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module körde ett ogiltigt kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK install_named_module hanterar dry-run utan fel"
}



run_backend_function_test() {
    next_test
    local functions

    source ./bootstrap.sh >/dev/null 2>&1

    functions=$(get_backend_functions apt)

    if [[ "$functions" != $'apt_is_installed\napt_install' ]]
    then
        echo "[$TEST_NUMBER] FAIL: APT-backend returnerar fel funktioner"
        return 1
    fi

    functions=$(get_backend_functions flatpak)

    if [[ "$functions" != $'flatpak_is_installed\nflatpak_install' ]]
    then
        echo "[$TEST_NUMBER] FAIL: Flatpak-backend returnerar fel funktioner"
        return 1
    fi

    functions=$(get_backend_functions npm)

    if [[ "$functions" != $'npm_is_installed\nnpm_install' ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm-backend returnerar fel funktioner"
        return 1
    fi

    echo "[$TEST_NUMBER] OK get_backend_functions returnerar rätt funktioner"
}

run_get_backend_test() {
    next_test
    local result

    source ./lib/modules.sh

    result=$(get_backend "/tmp/packages/apt/01-test.txt")

    if [[ "$result" != "apt" ]]
    then
        echo "[$TEST_NUMBER] FAIL: get_backend returnerade '$result' för apt"
        return 1
    fi

    result=$(get_backend "/tmp/packages/flatpak/42-test.txt")

    if [[ "$result" != "flatpak" ]]
    then
        echo "[$TEST_NUMBER] FAIL: get_backend returnerade '$result' för flatpak"
        return 1
    fi

    result=$(get_backend "/tmp/packages/npm/99-test.txt")

    if [[ "$result" != "npm" ]]
    then
        echo "[$TEST_NUMBER] FAIL: get_backend returnerade '$result' för npm"
        return 1
    fi

    echo "[$TEST_NUMBER] OK get_backend identifierar backend korrekt"
}

run_supported_backend_test() {
    next_test
    source ./lib/modules.sh

    for backend in apt flatpak npm
    do
        if ! is_supported_backend "$backend"
        then
            echo "[$TEST_NUMBER] FAIL: $backend borde vara en stödd backend"
            return 1
        fi
    done

    for backend in unknown java docker
    do
        if is_supported_backend "$backend"
        then
            echo "[$TEST_NUMBER] FAIL: $backend borde inte vara en stödd backend"
            return 1
        fi
    done

    echo "[$TEST_NUMBER] OK is_supported_backend hanterar stödda och okända backends"
}

run_read_module_test() {
    next_test
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
        echo "[$TEST_NUMBER] FAIL: read_module filtrerar paketlistan fel"
        return 1
    fi

    echo "[$TEST_NUMBER] OK read_module läser paket och ignorerar tomma rader/kommentarer"
}

run_find_modules_test() {
    next_test
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
        echo "[$TEST_NUMBER] FAIL: find_modules hittade fel filer"
        return 1
    fi

    echo "[$TEST_NUMBER] OK find_modules hittar endast moduler på rätt nivå"
}

run_find_module_test() {
    next_test
    local test_dir
    local output
    local expected

    test_dir=$(mktemp -d)

    mkdir -p "$test_dir/apt" "$test_dir/flatpak"

    touch "$test_dir/apt/01-target.txt"
    touch "$test_dir/apt/02-target.txt"
    touch "$test_dir/apt/03-other.txt"
    touch "$test_dir/flatpak/01-target.txt"
    touch "$test_dir/flatpak/02-other.txt"

    output=$(bash -c '
        PACKAGE_DIR="$1"
        source ./lib/modules.sh
        find_module "missing" || true
    ' _ "$test_dir")

    if [[ -n "$output" ]]
    then
        rm -rf "$test_dir"
        echo "[$TEST_NUMBER] FAIL: find_module returnerade träff för okänd modul"
        return 1
    fi

    expected=$(
        printf '%s\n' \
            "$test_dir/apt/01-target.txt" \
            "$test_dir/apt/02-target.txt" \
            "$test_dir/flatpak/01-target.txt"
    )

    output=$(bash -c '
        PACKAGE_DIR="$1"
        source ./lib/modules.sh
        find_module "target"
    ' _ "$test_dir")

    rm -rf "$test_dir"

    if [[ "$output" != "$expected" ]]
    then
        echo "[$TEST_NUMBER] FAIL: find_module returnerade fel moduler"
        return 1
    fi

    echo "[$TEST_NUMBER] OK find_module hittar och sorterar moduler i alla backends"
}

run_count_modules_test() {
    next_test
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
        echo "[$TEST_NUMBER] FAIL: count_modules returnerade '$result', förväntade 4"
        return 1
    fi

    echo "[$TEST_NUMBER] OK count_modules räknar moduler korrekt"
}

run_process_modules_test() {
    next_test
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
        echo "[$TEST_NUMBER] FAIL: process_modules returnerade status $result"
        return 1
    fi

    if [[ "$output" != $'01-one.txt\n02-two.txt\n01-three.txt' ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_modules skickade fel moduler till callback"
        return 1
    fi

    echo "[$TEST_NUMBER] OK process_modules använder callback korrekt"
}

run_process_modules_failure_test() {
    next_test
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
        echo "[$TEST_NUMBER] FAIL: process_modules propagerade inte callback-felet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK process_modules propagerar callback-fel"
}

run_process_module_test() {
    next_test
    local test_dir
    local module
    local output
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    module="$test_dir/apt/01-test.txt"

    printf '%s\n' "paket-som-inte-finns" > "$module"

    if output=$(
        DRY_RUN=true \
        bash -c '
            source ./bootstrap.sh >/dev/null 2>&1
            set +e
            process_module "$1"
        ' -- "$module"
    )
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_module returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"Saknas: paket-som-inte-finns"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_module identifierade inte saknat paket"
        return 1
    fi

    if [[ "$output" != *"DRY RUN:"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_module körde inte dry-run"
        return 1
    fi

    echo "[$TEST_NUMBER] OK process_module hanterar saknat paket i dry-run"
}

run_count_all_packages_test() {
    next_test
    local test_dir
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/flatpak"

    cat > "$test_dir/apt/01-one.txt" <<'EOF'
git
curl
wget
EOF

    cat > "$test_dir/apt/02-two.txt" <<'EOF'
vim
htop
EOF

    cat > "$test_dir/flatpak/01-three.txt" <<'EOF'
org.gimp.GIMP
EOF

    cat > "$test_dir/flatpak/02-four.txt" <<'EOF'
# Detta är en kommentar

kdenlive
    # Indenterad kommentar
EOF

    result=$(count_all_packages "$test_dir")

    rm -rf "$test_dir"

    if [[ "$result" != "7" ]]
    then
        echo "[$TEST_NUMBER] FAIL: count_all_packages returnerade '$result', förväntade 6"
        return 1
    fi

    echo "[$TEST_NUMBER] OK count_all_packages räknar paket korrekt"
}

run_process_module_failure_test() {
    next_test
    local test_dir
    local module
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    module="$test_dir/apt/01-test.txt"

    printf '%s\n' "paket-som-inte-finns" > "$module"

    if (
        source ./bootstrap.sh >/dev/null 2>&1
        DRY_RUN=false
        apt_is_installed() {
            return 1
        }
        apt_install() {
            return 1
        }
        process_module "$module"
    )
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_module returnerade inte fel vid misslyckad installation"
        return 1
    fi

    echo "[$TEST_NUMBER] OK process_module returnerar fel vid misslyckad installation"
}



run_process_modules_unknown_backend_test() {
    next_test
    local test_dir
    local output
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/unknown"

    touch "$test_dir/apt/01-ok.txt"
    touch "$test_dir/unknown/01-ignored.txt"

    test_callback() {
        printf '%s\n' "$(basename "$1")"
        return 0
    }

    output=$(process_modules "$test_dir" test_callback 2>&1)
    result=$?

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_modules returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"01-ok.txt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_modules körde inte callback för giltig backend"
        return 1
    fi

    if [[ "$output" == *"01-ignored.txt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: process_modules körde callback för okänd backend"
        return 1
    fi

    echo "[$TEST_NUMBER] OK process_modules hoppar över okänd backend"
}

apt_install() {
    echo "TEST: APT_INSTALL"
    return 0
}

run_process_module_backend_test() {
    next_test
    local test_dir
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/flatpak"
    mkdir "$test_dir/npm"

    printf '%s\n' "test-package" \
        > "$test_dir/apt/01-test.txt"

    printf '%s\n' "test-app" \
        > "$test_dir/flatpak/01-test.txt"

    printf '%s\n' "test-npm-package" \
        > "$test_dir/npm/01-test.txt"

    source ./lib/modules.sh

apt_is_installed() {
    return 1
}

apt_install() {
    printf 'APT_INSTALL\n'
    return 0
}

flatpak_is_installed() {
    return 1
}

flatpak_install() {
    printf 'FLATPAK_INSTALL\n'
    return 0
}

npm_is_installed() {
    return 1
}

npm_install() {
    printf 'NPM_INSTALL\n'
    return 0
}

load_backends() {
    :
}

set +e

for backend in apt flatpak npm
do
    DRY_RUN=true process_module \
        "$test_dir/$backend/01-test.txt" \
        > "$test_dir/$backend-output.txt" 2>&1

    result=$?

    if [[ "$result" -ne 0 ]]
    then
        set -e
        rm -rf "$test_dir"
        echo "[$TEST_NUMBER] FAIL: process_module misslyckades för backend $backend"
        return 1
    fi
done

set -e

for backend in apt flatpak npm
do
    case "$backend" in
        apt)
            expected="APT_INSTALL"
            ;;
        flatpak)
            expected="FLATPAK_INSTALL"
            ;;
        npm)
            expected="NPM_INSTALL"
            ;;
    esac

    if ! grep -q "$expected" "$test_dir/$backend-output.txt"
    then
        rm -rf "$test_dir"
        echo "[$TEST_NUMBER] FAIL: process_module anropade inte $backend-backenden"
        return 1
    fi

done

rm -rf "$test_dir"

echo "[$TEST_NUMBER] OK process_module väljer rätt installationsbackend"
}

run_package_repository_test() {
    next_test
    local result

    source ./lib/repositories.sh

    result=$(package_repository tailscale)

    if [[ "$result" != "tailscale" ]]
    then
        echo "[$TEST_NUMBER] FAIL: package_repository identifierade inte Tailscale"
        return 1
    fi

    if package_repository git >/dev/null
    then
        echo "[$TEST_NUMBER] FAIL: git borde inte kräva externt repository"
        return 1
    fi

    echo "[$TEST_NUMBER] OK package_repository identifierar externa repositories"
}

run_ensure_repository_test() {
    next_test
    local output

    source ./lib/repositories.sh

    tailscale_repository_exists() {
        return 0
    }

    add_tailscale_repository() {
        printf 'ADD_TAILSCALE_REPOSITORY\n'
        return 0
    }

    output=$(ensure_repository tailscale)

    if [[ "$output" == *"ADD_TAILSCALE_REPOSITORY"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: befintligt repository skulle inte läggas till"
        return 1
    fi

    source ./lib/repositories.sh

    echo "[$TEST_NUMBER] OK ensure_repository lämnar befintligt repository orört"
}


run_ensure_repository_failure_test() {
    next_test

    local result

    source ./lib/repositories.sh

    tailscale_repository_exists() {
        return 1
    }

    add_tailscale_repository() {
        return 1
    }

    if ensure_repository tailscale
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: ensure_repository propagaterade inte repository-felet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK ensure_repository propagaterar repository-fel"
}


run_npm_helpers_test() {
    next_test
    local expected_prefix
    local expected_bin

    source ./lib/npm.sh

    expected_prefix="$HOME/.local"
    expected_bin="$HOME/.local/bin"

    if [[ "$(npm_prefix)" != "$expected_prefix" ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_prefix returnerade fel sökväg"
        return 1
    fi

    if [[ "$(npm_bin_dir)" != "$expected_bin" ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_bin_dir returnerade fel sökväg"
        return 1
    fi

    echo "[$TEST_NUMBER] OK npm hjälpfunktioner returnerar rätt sökvägar"
}
run_npm_path_test() {
    next_test
    local original_path="$PATH"
    local bin_dir

    source ./lib/npm.sh

    bin_dir=$(npm_bin_dir)

    PATH="/usr/bin:/bin"

    if npm_path_configured
    then
        echo "[$TEST_NUMBER] FAIL: npm bin borde saknas i PATH"
        PATH="$original_path"
        return 1
    fi

    PATH="/usr/bin:$bin_dir:/bin"

    if ! npm_path_configured
    then
        echo "[$TEST_NUMBER] FAIL: npm bin borde finnas i PATH"
        PATH="$original_path"
        return 1
    fi

    PATH="$original_path"

    echo "[$TEST_NUMBER] OK npm_path_configured hanterar PATH korrekt"
}

run_package_exists_test() {
    next_test
    source ./lib/packages.sh

    apt-cache() {
        case "$2" in
            existing-package)
                return 0
                ;;
            missing-package)
                return 1
                ;;
        esac
    }

    if ! package_exists existing-package
    then
        echo "[$TEST_NUMBER] FAIL: package_exists borde hitta paketet"
        return 1
    fi

    if package_exists missing-package
    then
        echo "[$TEST_NUMBER] FAIL: package_exists borde inte hitta paketet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK package_exists hanterar befintliga och saknade paket"
}

run_package_installed_test() {
    next_test
    source ./lib/packages.sh

    dpkg() {
        case "$2" in
            installed-package)
                return 0
                ;;
            missing-package)
                return 1
                ;;
        esac
    }

    if ! package_installed installed-package
    then
        echo "[$TEST_NUMBER] FAIL: package_installed borde hitta paketet"
        return 1
    fi

    if package_installed missing-package
    then
        echo "[$TEST_NUMBER] FAIL: package_installed borde inte hitta paketet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK package_installed hanterar befintliga och saknade paket"
}

run_verify_package_missing_test() {
    next_test
    local output
    local result

    source ./lib/packages.sh

    package_exists() {
        return 1
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(verify_package test-package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: verify_package borde returnera 1 för saknat paket"
        return 1
    fi

    if [[ "$output" != *"ERROR: test-package finns inte."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: verify_package rapporterade inte saknat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK verify_package hanterar saknat paket"
}

run_verify_package_not_installed_test() {
    next_test
    local output
    local result

    source ./lib/packages.sh

    package_exists() {
        return 0
    }

    package_installed() {
        return 1
    }

    warn() {
        printf 'WARN: %s\n' "$*"
    }

    if output=$(verify_package test-package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: verify_package borde returnera 0"
        return 1
    fi

    if [[ "$output" != *"WARN: test-package finns men är inte installerat."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: verify_package rapporterade inte ej installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK verify_package hanterar ej installerat paket"
}

run_print_summary_test() {
    next_test
    local output

    source ./lib/common.sh

    count_modules() {
        printf '12\n'
    }

    count_all_packages() {
        printf '69\n'
    }

    output=$(print_summary)

    if [[ "$output" != *"Moduler:             12"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_summary visade fel antal moduler"
        return 1
    fi

    if [[ "$output" != *"Paket:               69"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_summary visade fel antal paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK print_summary använder sammanräknade värden korrekt"
}

run_parse_arguments_version_test() {
    next_test
    local output
    local result
    local version

    if output=$(bash -c '
        source ./bootstrap.sh
        parse_arguments --version
    ' 2>&1)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: parse_arguments --version returnerade status $result"
        return 1
    fi

    version=$(printf '%s\n' "$output" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')

    if [[ "$version" != "$APP_VERSION" ]]
    then
        echo "[$TEST_NUMBER] FAIL: --version gav fel version: $version"
        return 1
    fi

    echo "[$TEST_NUMBER] OK parse_arguments hanterar --version"
}

run_parse_arguments_help_test() {
    next_test
    local output
    local result

    if output=$(bash -c '
        source ./bootstrap.sh
        parse_arguments --help
    ' 2>&1)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: parse_arguments --help returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"Henric Workstation Bootstrap v$APP_VERSION"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --help visade inte programversion"
        return 1
    fi

    if [[ "$output" != *"--install MODUL"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --help saknar information om modulinstallation"
        return 1
    fi

    if [[ "$output" != *"--dry-run"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --help saknar information om dry-run"
        return 1
    fi

    echo "[$TEST_NUMBER] OK parse_arguments hanterar --help"
}




run_verify_package_installed_test() {
    next_test
    local output
    local result

    source ./lib/packages.sh

    package_exists() {
        return 0
    }

    package_installed() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    if output=$(verify_package test-package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "$TEST_NUMBER] FAIL: verify_package borde returnera 0"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: test-package är installerat."* ]]
    then
        echo "$TEST_NUMBER] FAIL: verify_package rapporterade inte installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: verify_package hanterar installerat paket"
}

run_print_modules_test() {
    next_test

    local test_dir
    local output

    source ./lib/modules.sh

    test_dir=$(mktemp -d)

    mkdir "$test_dir/apt"
    mkdir "$test_dir/flatpak"

    printf '%s\n' \
        "package-one" \
        "package-two" \
        "package-three" \
        > "$test_dir/apt/01-one.txt"

    printf '%s\n' \
        "package-four" \
        "# ignored" \
        "" \
        "package-five" \
        > "$test_dir/flatpak/01-two.txt"

    output=$(print_modules "$test_dir")

    rm -rf "$test_dir"

    if [[ "$output" != *"APT"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules saknar APT"
        return 1
    fi

    if [[ "$output" != *"01-one.txt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules saknar 01-one.txt"
        return 1
    fi

    if [[ "$output" != *"( 3 paket)"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules räknade fel för 01-one.txt"
        return 1
    fi

    if [[ "$output" != *"FLATPAK"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules saknar FLATPAK"
        return 1
    fi

    if [[ "$output" != *"01-two.txt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules saknar 01-two.txt"
        return 1
    fi

    if [[ "$output" != *"( 2 paket)"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_modules räknade fel för 01-two.txt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: print_modules visar backends, moduler och paketantal"
}

run_parse_arguments_list_test() {
    next_test
    local output

    source ./lib/cli.sh

    print_modules() {
        printf 'PRINT_MODULES_CALLED\n'
    }

    output=$(parse_arguments --list)

    if [[ "$output" != *"PRINT_MODULES_CALLED"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --list anropade inte print_modules"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --list"
}

run_parse_arguments_summary_test() {
    next_test
    local output

    source ./lib/cli.sh

    count_modules() {
        printf '12\n'
    }

    count_all_packages() {
        printf '69\n'
    }

    print_summary() {
        printf 'PRINT_SUMMARY_CALLED\n'
    }

    output=$(parse_arguments --summary)

    if [[ "$output" != *"PRINT_SUMMARY_CALLED"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --summary anropade inte print_summary"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --summary"
}

run_parse_arguments_doctor_test() {
    next_test
    local output

    source ./lib/cli.sh

    doctor() {
        printf 'DOCTOR_CALLED\n'
    }

    output=$(parse_arguments --doctor)

    if [[ "$output" != *"DOCTOR_CALLED"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --doctor anropade inte doctor"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --doctor"
}

run_parse_arguments_install_all_test() {
    next_test
    local output

    source ./lib/cli.sh

    install_all_modules() {
        printf 'INSTALL_ALL_CALLED\n'
    }

    output=$(parse_arguments --install)

    if [[ "$output" != *"INSTALL_ALL_CALLED"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --install anropade inte install_all_modules"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --install"
}

run_parse_arguments_install_named_test() {
    next_test
    local output

    source ./lib/cli.sh

    install_named_module() {
        printf 'INSTALL_NAMED_CALLED: %s\n' "$1"
    }

    output=$(parse_arguments --install media)

    if [[ "$output" != *"INSTALL_NAMED_CALLED: media"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --install media anropade inte install_named_module korrekt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --install med modul"
}

run_parse_arguments_install_failure_test() {
    next_test

    local result

    source ./lib/cli.sh

    install_all_modules() {
        return 7
    }

    info() {
        :
    }

    if parse_arguments --install
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 7 ]]
    then
        echo "[$TEST_NUMBER] FAIL: --install returnerade status $result i stället för 7"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: --install propagerar felstatus"
}

run_parse_arguments_dry_run_test() {
    next_test
    local original_dry_run="${DRY_RUN-}"

    unset DRY_RUN

    install_all_modules() {
        printf 'INSTALL_ALL_CALLED\n'
    }

    parse_arguments --dry-run --install

    if [[ "${DRY_RUN:-false}" != true ]]
    then
        echo "[$TEST_NUMBER] FAIL: --dry-run satte inte DRY_RUN=true"
        [[ -n "$original_dry_run" ]] && DRY_RUN="$original_dry_run"
        return 1
    fi

    if [[ -n "$original_dry_run" ]]
    then
        DRY_RUN="$original_dry_run"
    else
        unset DRY_RUN
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments hanterar --dry-run"
}

run_parse_arguments_dry_run_named_module_test() {
    next_test

    local output
    local result

    if output=$(
        bash -c '
            source ./bootstrap.sh >/dev/null 2>&1

            find_module() {
                printf "%s\n" \
                    "/tmp/apt/03-development.txt" \
                    "/tmp/flatpak/01-development.txt" \
                    "/tmp/npm/01-development.txt"
            }

            process_module() {
                printf "PROCESS_MODULE: %s DRY_RUN=%s\n" "$1" "${DRY_RUN:-false}"
                return 0
            }

            parse_arguments --dry-run --install development
        ' 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: --dry-run --install development returnerade status $result"
        return 1
    fi

    local expected_output
    expected_output=$'PROCESS_MODULE: /tmp/apt/03-development.txt DRY_RUN=true\nPROCESS_MODULE: /tmp/flatpak/01-development.txt DRY_RUN=true\nPROCESS_MODULE: /tmp/npm/01-development.txt DRY_RUN=true'

    if [[ "$output" != *"$expected_output"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: --dry-run --install development behandlade inte alla moduler korrekt"
        echo "Fick:"
        printf '%s\n' "$output"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: --dry-run --install development hanterar flera moduler"
}


run_parse_arguments_invalid_test() {
    next_test
    local output
    local result

    if output=$(
        bash -c '
            source ./bootstrap.sh >/dev/null 2>&1

            error() {
                printf "ERROR: %s\n" "$*"
            }

            parse_arguments --banana
        ' 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: okänt argument gav status $result"
        return 1
    fi

    if [[ "$output" != *"ERROR: Okänt argument: --banana"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: okänt argument rapporterades inte korrekt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments avvisar okänt argument"
}

run_parse_arguments_multiple_commands_test() {
    next_test
    local output
    local result

    if output=$(
        bash -c '
            source ./bootstrap.sh >/dev/null 2>&1

            error() {
                printf "ERROR: %s\n" "$*"
            }

            parse_arguments --doctor --update
        ' 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -eq 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flera huvudkommandon accepterades"
        return 1
    fi

    if [[ "$output" != *"ERROR:"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: inget felmeddelande visades"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: parse_arguments avvisar flera huvudkommandon"
}

run_parse_arguments_install_update_test() {
    next_test
    local output
    local result

    if output=$(
        bash -c '
            source ./bootstrap.sh >/dev/null 2>&1

            error() {
                printf "ERROR: %s\n" "$*"
            }

            parse_arguments --install development --update
        ' 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -eq 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: --install och --update accepterades samtidigt"
        return 1
    fi

    if [[ "$output" != *"ERROR:"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: inget felmeddelande visades"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: --install och --update avvisas tillsammans"
}



run_check_file_test() {
    next_test

    local test_file
    local output
    local result

    source ./lib/doctor.sh

    test_file=$(mktemp)

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_file "$test_file")
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        rm -f "$test_file"
        echo "[$TEST_NUMBER] FAIL: check_file misslyckades för befintlig fil"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: $(basename "$test_file")"* ]]
    then
        rm -f "$test_file"
        echo "[$TEST_NUMBER] FAIL: check_file rapporterade inte befintlig fil"
        return 1
    fi

    rm -f "$test_file"

    set +e
    output=$(check_file "$test_file")
    result=$?
    set -e

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_file borde returnera 1 för saknad fil"
        return 1
    fi

    if [[ "$output" != *"ERROR: Saknar $(basename "$test_file")"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_file rapporterade inte saknad fil"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_file hanterar befintlig och saknad fil"
}

run_check_directory_test() {
    next_test

    local test_dir
    local output
    local result

    source ./lib/doctor.sh

    test_dir=$(mktemp -d)

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_directory "$test_dir")
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        rm -rf "$test_dir"
        echo "[$TEST_NUMBER] FAIL: check_directory misslyckades för befintlig katalog"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: $(basename "$test_dir")/"* ]]
    then
        rm -rf "$test_dir"
        echo "[$TEST_NUMBER] FAIL: check_directory rapporterade inte befintlig katalog"
        return 1
    fi

    rm -rf "$test_dir"

    set +e
    output=$(check_directory "$test_dir")
    result=$?
    set -e

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_directory borde returnera 1 för saknad katalog"
        return 1
    fi

    if [[ "$output" != *"ERROR: Saknar $(basename "$test_dir")/"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_directory rapporterade inte saknad katalog"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_directory hanterar befintlig och saknad katalog"
}

run_check_project_test() {
    next_test

    local output
    local result

    source ./lib/doctor.sh

    check_file() {
        printf 'CHECK_FILE: %s\n' "$1"
        return 0
    }

    check_directory() {
        printf 'CHECK_DIRECTORY: %s\n' "$1"
        return 0
    }

    section() {
        :
    }

    output=$(check_project)

    if [[ "$output" != *"CHECK_FILE: $SCRIPT_DIR/VERSION"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: VERSION kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"CHECK_FILE: $SCRIPT_DIR/CHANGELOG.md"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: CHANGELOG.md kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"CHECK_FILE: $SCRIPT_DIR/bootstrap.sh"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: bootstrap.sh kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"CHECK_FILE: $SCRIPT_DIR/README.md"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: README.md kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"CHECK_DIRECTORY: $SCRIPT_DIR/packages"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: packages kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"CHECK_DIRECTORY: $SCRIPT_DIR/lib"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: lib kontrollerades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_project kontrollerar projektstrukturen"
}

run_doctor_test() {
    next_test
    local output

    source ./lib/doctor.sh

    banner() {
        printf 'banner\n'
    }

    section() {
        printf 'section\n'
    }

    check_os() {
        printf 'check_os\n'
    }

    check_architecture() {
        printf 'check_architecture\n'
    }

    check_sudo() {
        printf 'check_sudo\n'
    }

    check_network() {
        printf 'check_network\n'
    }

    check_package_manager() {
        printf 'check_package_manager\n'
    }

    check_required_commands() {
        printf 'check_required_commands\n'
    }

    check_project() {
        printf 'check_project\n'
    }

    print_doctor_summary() {
        printf 'print_doctor_summary\n'
    }

    output=$(doctor)

    if [[ "$output" != $'banner\nsection\ncheck_os\ncheck_architecture\ncheck_sudo\ncheck_network\ncheck_package_manager\ncheck_required_commands\ncheck_project\nprint_doctor_summary' ]]
    then
        echo "[$TEST_NUMBER] FAIL: doctor körde kontrollerna i fel ordning"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: doctor kör kontrollerna i rätt ordning"
}

run_check_environment_test() {
    next_test

    local test_dir
    local output
    local result

    test_dir=$(mktemp -d)

    mkdir "$test_dir/packages"
    mkdir "$test_dir/lib"

    if output=$(
        bash -c '
            set -Eeuo pipefail

            SCRIPT_DIR="$1"
            EXIT_ENVIRONMENT=42

            source ./lib/common.sh

            info() {
                :
            }

            success() {
                printf "SUCCESS: %s\n" "$*"
            }

            error() {
                printf "ERROR: %s\n" "$*"
            }

            check_environment
        ' -- "$test_dir" 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_environment returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: Hittade packages/"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: packages kontrollerades inte"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: Hittade lib/"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: lib kontrollerades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_environment hittar projektkatalogerna"
}

run_check_environment_failure_test() {
    next_test

    local test_dir
    local output
    local result

    local original_path="$PATH"

    test_dir=$(mktemp -d)

    mkdir "$test_dir/packages"

    # lib saknas med flit

    if output=$(
        bash -c '
            set -Eeuo pipefail

            SCRIPT_DIR="$1"
            EXIT_ENVIRONMENT=42

            source ./lib/common.sh

            info() {
                :
            }

            success() {
                printf "SUCCESS: %s\n" "$*"
            }

            error() {
                printf "ERROR: %s\n" "$*"
            }

            check_environment
        ' -- "$test_dir" 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 42 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_environment returnerade status $result"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_environment hanterar saknad katalog"
}

run_check_commands_test() {
    next_test

    local test_dir
    local original_path="$PATH"
    local output

    source ./lib/common.sh

    test_dir=$(mktemp -d)

    printf '#!/bin/sh\nexit 0\n' > "$test_dir/bash"
    printf '#!/bin/sh\nexit 0\n' > "$test_dir/git"
    printf '#!/bin/sh\nexit 0\n' > "$test_dir/apt"

    chmod +x "$test_dir/bash"
    chmod +x "$test_dir/git"
    chmod +x "$test_dir/apt"

    PATH="$test_dir"

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    output=$(check_commands bash git apt)

    PATH="$original_path"
    rm -rf "$test_dir"

    if [[ "$output" != *"SUCCESS: bash"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: bash rapporterades inte som tillgängligt"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: git"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: git rapporterades inte som tillgängligt"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: apt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt rapporterades inte som tillgängligt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_commands hittar alla nödvändiga kommandon"
}

run_check_commands_failure_test() {
    next_test

    local test_dir
    local original_path="$PATH"
    local output
    local result

    source ./lib/common.sh

    test_dir=$(mktemp -d)

    printf '#!/bin/sh\nexit 0\n' > "$test_dir/bash"
    printf '#!/bin/sh\nexit 0\n' > "$test_dir/git"

    chmod +x "$test_dir/bash" "$test_dir/git"

    PATH="$test_dir"

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    set +e
    output=$(check_commands bash git apt)
    result=$?
    set -e

    PATH="$original_path"
    rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_commands borde returnera 1"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: bash"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: bash rapporterades inte korrekt"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: git"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: git rapporterades inte korrekt"
        return 1
    fi

    if [[ "$output" != *"ERROR: apt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt rapporterades inte som saknat"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_commands hanterar saknat kommando"
}

run_check_package_manager_test() {
    next_test

    local output

    source ./lib/system.sh

    section() {
        :
    }

    check_commands() {
        printf 'CHECK_COMMANDS: %s\n' "$*"
        return 0
    }

    output=$(check_package_manager)

    if [[ "$output" != *"CHECK_COMMANDS:"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_package_manager anropade inte check_commands"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_package_manager använder check_commands"
}

run_check_required_commands_test() {
    next_test

    local output

    source ./lib/system.sh

    section() {
        :
    }

    check_commands() {
        printf 'CHECK_COMMANDS: %s\n' "$*"
        return 0
    }

    output=$(check_required_commands)

    if [[ "$output" != *"CHECK_COMMANDS:"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_required_commands anropade inte check_commands"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_required_commands använder check_commands"
}

run_print_doctor_summary_test() {
    next_test

    local output
    local original_doctor_mode

    source ./lib/system.sh

    original_doctor_mode="${DOCTOR_MODE:-false}"

    success_count=5
    info_count=3
    warning_count=1
    error_count=0
    DOCTOR_MODE=true

    section() {
        :
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    output=$(print_doctor_summary)

    DOCTOR_MODE="$original_doctor_mode"

    if [[ ! "$output" =~ Successful:[[:space:]]+5 ]]
    then
        echo "[$TEST_NUMBER] FAIL: fel antal Successful"
        return 1
    fi

    if [[ ! "$output" =~ Information:[[:space:]]+3 ]]
    then
        echo "[$TEST_NUMBER] FAIL: fel antal Information"
        return 1
    fi

    if [[ ! "$output" =~ Warnings:[[:space:]]+1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: fel antal Warnings"
        return 1
    fi

    if [[ ! "$output" =~ Errors:[[:space:]]+0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: fel antal Errors"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: System ready for installation."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: lyckat system rapporterades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: print_doctor_summary rapporterar lyckad diagnos"
}

run_print_doctor_summary_failure_test() {
    next_test

    local output

    source ./lib/system.sh

    success_count=5
    info_count=3
    warning_count=1
    error_count=2
    DOCTOR_MODE=true

    section() {
        :
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(print_doctor_summary)
        then
        result=0
        else
        result=$?
    fi

    if [[ "$output" != *"ERROR: Problems detected."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_doctor_summary rapporterade inte problem"
        return 1
    fi

    if [[ "$output" =~ "SUCCESS: System ready for installation." ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_doctor_summary rapporterade systemet som redo trots fel"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: print_doctor_summary hanterar diagnostik med fel"
}

run_check_os_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    OS_ID="debian"
    OS_NAME="Test Debian"

    section() {
        :
    }

    detect_system() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_os)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_os misslyckades för Debian"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: Test Debian"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_os rapporterade inte rätt OS"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_os hanterar Debian"
}

run_check_os_detection_failure_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    section() {
        :
    }

    detect_system() {
        return 1
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_os)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_os borde returnera 1 när detect_system misslyckas"
        return 1
    fi

    if [[ ! "$output" =~ Kan[[:space:]]+inte[[:space:]]+identifiera[[:space:]]+operativsystem ]]
then
    echo "[$TEST_NUMBER] FAIL: check_os rapporterade inte identifieringsfelet"
    return 1
fi

    echo "[$TEST_NUMBER] OK: check_os hanterar misslyckad identifiering"
}

run_check_os_wrong_os_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    OS_ID="ubuntu"
    OS_NAME="Ubuntu"

    section() {
        :
    }

    detect_system() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_os)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_os borde returnera 1 för icke-Debian"
        return 1
    fi

    if [[ ! "$output" =~ Endast[[:space:]]+Debian[[:space:]]+stöds ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_os rapporterade inte felaktigt operativsystem"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_os avvisar icke-Debian"
}

run_check_architecture_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    CPU_ARCH="x86_64"

    section() {
        :
    }

    detect_system() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    warn() {
        printf 'WARN: %s\n' "$*"
    }

    if output=$(check_architecture)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_architecture misslyckades för x86_64"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: Architecture: x86_64"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: x86_64 rapporterades inte korrekt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_architecture hanterar x86_64"
}

run_check_architecture_unsupported_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    CPU_ARCH="arm64"

    detect_system() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    warn() {
        printf 'WARN: %s\n' "$*"
    }

    if output=$(check_architecture)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_architecture borde returnera 1 för unsupported arkitektur"
        return 1
    fi

    if [[ "$output" != *"WARN: Architecture arm64 is not supported."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: unsupported arkitektur rapporterades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_architecture avvisar unsupported arkitektur"
}

run_check_architecture_detection_failure_test() {
    next_test

    local result

    source ./lib/system.sh

    detect_system() {
        return 1
    }

    if check_architecture
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_architecture borde returnera 1 när detect_system misslyckas"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_architecture hanterar misslyckad systemidentifiering"
}

run_check_sudo_test() {
    next_test

    local output

    source ./lib/system.sh

    section() {
        :
    }

    command() {
        return 0
    }

    id() {
        printf 'henric sudo users\n'
    }

    grep() {
        return 0
    }

    sudo() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    info() {
        printf 'INFO: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    output=$(USER=henric check_sudo)

    if [[ "$output" != *"SUCCESS: sudo installed"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: sudo rapporterades inte som installerat"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: User belongs to sudo group."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: sudo-gruppmedlemskap rapporterades inte"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: sudo session active."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: aktiv sudo-session rapporterades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_sudo hanterar fungerande sudo-miljö"
}

run_check_sudo_missing_test() {
    next_test

    local test_dir
    local output
    local result

    test_dir=$(mktemp -d)

    if output=$(
        PATH="$test_dir"
        /bin/bash -c '
            source ./lib/system.sh

            section() {
                :
            }

            error() {
                printf "ERROR: %s\n" "$*"
            }

            check_sudo
        ' 2>&1
    )
    then
        result=0
    else
        result=$?
    fi

    /usr/bin/rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo borde returnera 1 när sudo saknas"
        return 1
    fi

    if [[ "$output" != *"ERROR: sudo is not installed."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo rapporterade inte saknat sudo"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_sudo hanterar saknat sudo"
}

run_check_sudo_group_failure_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    section() {
        :
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    command() {
        return 0
    }

    id() {
        printf 'henric users\n'
    }

    grep() {
        return 1
    }

    if output=$(check_sudo)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo borde returnera 1 utan sudo-grupp"
        return 1
    fi

    if [[ "$output" != *"ERROR: User is not a member of the sudo group."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo rapporterade inte saknad sudo-grupp"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_sudo hanterar användare utan sudo-grupp"
}

run_check_sudo_password_required_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    section() {
        :
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    info() {
        printf 'INFO: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    command() {
        return 0
    }

    id() {
        printf 'henric sudo users\n'
    }

    grep() {
        return 0
    }

    sudo() {
        return 1
    }

    if output=$(check_sudo)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo borde returnera 0 när lösenord krävs"
        return 1
    fi

    if [[ "$output" != *"INFO: sudo password required."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_sudo rapporterade inte att lösenord krävs"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_sudo hanterar krav på sudo-lösenord"
}


run_check_network_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    section() {
        :
    }

    ping() {
        return 0
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_network)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_network misslyckades trots lyckad ping"
        return 1
    fi

    if [[ "$output" != *"SUCCESS: Internet connection"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_network rapporterade inte fungerande nätverk"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_network hanterar fungerande nätverk"
}

run_check_network_failure_test() {
    next_test

    local output
    local result

    source ./lib/system.sh

    section() {
        :
    }

    ping() {
        return 1
    }

    success() {
        printf 'SUCCESS: %s\n' "$*"
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(check_network)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_network borde returnera 1 när ping misslyckas"
        return 1
    fi

    if [[ "$output" != *"ERROR: No Internet connection"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: check_network rapporterade inte saknad nätverksanslutning"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: check_network hanterar saknad nätverksanslutning"
}


run_detect_system_test() {
    next_test

    local test_dir
    local os_release
    local result

    source ./lib/system.sh

    test_dir=$(mktemp -d)
    os_release="$test_dir/os-release"

    cat > "$os_release" <<'EOF'
ID=debian
VERSION_ID="13"
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
VERSION_CODENAME=trixie
EOF

    OS_RELEASE_FILE="$os_release"

    uname() {
        printf 'x86_64\n'
    }

    if detect_system
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: detect_system misslyckades"
        return 1
    fi

    if [[ "$OS_ID" != "debian" ]]
    then
        echo "[$TEST_NUMBER] FAIL: OS_ID blev '$OS_ID'"
        return 1
    fi

    if [[ "$OS_VERSION" != "13" ]]
    then
        echo "[$TEST_NUMBER] FAIL: OS_VERSION blev '$OS_VERSION'"
        return 1
    fi

    if [[ "$OS_NAME" != "Debian GNU/Linux 13 (trixie)" ]]
    then
        echo "[$TEST_NUMBER] FAIL: OS_NAME blev '$OS_NAME'"
        return 1
    fi

    if [[ "$OS_CODENAME" != "trixie" ]]
    then
        echo "[$TEST_NUMBER] FAIL: OS_CODENAME blev '$OS_CODENAME'"
        return 1
    fi

    if [[ "$CPU_ARCH" != "x86_64" ]]
    then
        echo "[$TEST_NUMBER] FAIL: CPU_ARCH blev '$CPU_ARCH'"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: detect_system läser systeminformation korrekt"
}

run_detect_system_missing_file_test() {
    next_test

    local test_dir
    local result

    source ./lib/system.sh

    test_dir=$(mktemp -d)
    OS_RELEASE_FILE="$test_dir/missing-os-release"

    if detect_system
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: detect_system borde returnera 1 när os-release saknas"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: detect_system hanterar saknad os-release"
}

run_section_test() {
    next_test

    local output

    source ./lib/common.sh

    output=$(section "Test Section")

    if [[ "$output" != *"Test Section"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: section visade inte rubriken"
        return 1
    fi

    if [[ "$output" != *"========================================"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: section saknar avgränsare"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: section formaterar rubrik korrekt"
}

run_log_test() {
    next_test

    local output

    source ./lib/common.sh

    output=$(log INFO "testmeddelande" 2>&1)

    if [[ "$output" != *"INFO-5a testmeddelande"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: log formaterade INFO fel"
        return 1
    fi

    output=$(log FAIL "testfel" 2>&1)

    if [[ "$output" != *"FAIL-5s testfel"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: log formaterade FAIL fel"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: log formaterar INFO och FAIL korrekt"
}
run_info_test() {
    next_test

    local output_file
    local original_doctor_mode="${DOCTOR_MODE:-false}"
    local original_info_count="$info_count"

    source ./lib/common.sh

    output_file=$(mktemp)

    log() {
        printf 'LOG: %s %s\n' "$1" "$2"
    }

    DOCTOR_MODE=true
    info_count=0

    info "testmeddelande" > "$output_file"

    if ! grep -q 'LOG: INFO testmeddelande' "$output_file"
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        info_count="$original_info_count"
        echo "[$TEST_NUMBER] FAIL: info skickade inte INFO till log"
        return 1
    fi

    if [[ "$info_count" -ne 1 ]]
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        info_count="$original_info_count"
        echo "[$TEST_NUMBER] FAIL: info ökade inte info_count"
        return 1
    fi

    rm -f "$output_file"
    DOCTOR_MODE="$original_doctor_mode"
    info_count="$original_info_count"

    echo "[$TEST_NUMBER] OK: info loggar INFO och räknar diagnostik"
}

run_success_test() {
    next_test

    local output_file
    local original_doctor_mode="${DOCTOR_MODE:-false}"
    local original_success_count="$success_count"

    source ./lib/common.sh

    output_file=$(mktemp)

    log() {
        printf 'LOG: %s %s\n' "$1" "$2"
    }

    DOCTOR_MODE=true
    success_count=0

    success "testmeddelande" > "$output_file"

    if ! grep -q 'LOG:  OK  testmeddelande' "$output_file"
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        success_count="$original_success_count"
        echo "[$TEST_NUMBER] FAIL: success skickade inte rätt nivå till log"
        return 1
    fi

    if [[ "$success_count" -ne 1 ]]
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        success_count="$original_success_count"
        echo "[$TEST_NUMBER] FAIL: success ökade inte success_count"
        return 1
    fi

    rm -f "$output_file"
    DOCTOR_MODE="$original_doctor_mode"
    success_count="$original_success_count"

    echo "[$TEST_NUMBER] OK: success loggar och räknar diagnostik"
}

run_warn_test() {
    next_test

    local output_file
    local original_doctor_mode="${DOCTOR_MODE:-false}"
    local original_warning_count="$warning_count"

    source ./lib/common.sh

    output_file=$(mktemp)

    log() {
        printf 'LOG: %s %s\n' "$1" "$2"
    }

    DOCTOR_MODE=true
    warning_count=0

    warn "testmeddelande" > "$output_file"

    if ! grep -q 'LOG: WARN testmeddelande' "$output_file"
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        warning_count="$original_warning_count"
        echo "[$TEST_NUMBER] FAIL: warn skickade inte WARN till log"
        return 1
    fi

    if [[ "$warning_count" -ne 1 ]]
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        warning_count="$original_warning_count"
        echo "[$TEST_NUMBER] FAIL: warn ökade inte warning_count"
        return 1
    fi

    rm -f "$output_file"
    DOCTOR_MODE="$original_doctor_mode"
    warning_count="$original_warning_count"

    echo "[$TEST_NUMBER] OK: warn loggar och räknar diagnostik"
}

run_error_test() {
    next_test

    local output_file
    local original_doctor_mode="${DOCTOR_MODE:-false}"
    local original_error_count="$error_count"

    source ./lib/common.sh

    output_file=$(mktemp)

    log() {
        printf 'LOG: %s %s\n' "$1" "$2"
    }

    DOCTOR_MODE=true
    error_count=0

    error "testmeddelande" > "$output_file"

    if ! grep -q 'LOG: FAIL testmeddelande' "$output_file"
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        error_count="$original_error_count"
        echo "[$TEST_NUMBER] FAIL: error skickade inte FAIL till log"
        return 1
    fi

    if [[ "$error_count" -ne 1 ]]
    then
        rm -f "$output_file"
        DOCTOR_MODE="$original_doctor_mode"
        error_count="$original_error_count"
        echo "[$TEST_NUMBER] FAIL: error ökade inte error_count"
        return 1
    fi

    rm -f "$output_file"
    DOCTOR_MODE="$original_doctor_mode"
    error_count="$original_error_count"

    echo "[$TEST_NUMBER] OK: error loggar och räknar diagnostik"
}

run_banner_test() {
    next_test

    local output
    local expected_version

    expected_version="$APP_VERSION"

    output=$(banner)

    if [[ "$output" != *"Henric Workstation Bootstrap"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: banner saknar projektnamn"
        return 1
    fi

    if [[ "$output" != *"Version $expected_version"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: banner visar fel version"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: banner visar projektnamn och version"
}


run_install_named_module_missing_test() {
    next_test

    local output
    local result

    source ./lib/install_core.sh

    find_module() {
        return 1
    }

    error() {
        printf 'ERROR: %s\n' "$*"
    }

    if output=$(install_named_module nonexistent)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne "$EXIT_BAD_ARGUMENTS" ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module gav fel status $result"
        return 1
    fi

    if [[ "$output" != *"ERROR: Modulen 'nonexistent' finns inte."* ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module rapporterade inte saknad modul"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module hanterar saknad modul"
}

run_install_named_module_missing_set_e_test() {
    next_test

    local result

    if bash -c '
        set -Eeuo pipefail

        source ./lib/exit_codes.sh
        source ./lib/install_core.sh

        find_module() {
            return 1
        }

        error() {
            printf "ERROR: %s\n" "$*"
        }

        install_named_module nonexistent
    '
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne "$EXIT_BAD_ARGUMENTS" ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module gav fel status under set -e: $result"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module hanterar saknad modul under set -e"
}

run_install_named_module_test() {
    next_test

    local output
    local result

    source ./lib/install_core.sh

    find_module() {
        printf '/tmp/05-media.txt\n'
    }

    process_module() {
        printf 'PROCESS_MODULE: %s\n' "$1"
        return 0
    }

    if output=$(install_named_module media)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module misslyckades för befintlig modul"
        return 1
    fi

    if [[ "$output" != *"PROCESS_MODULE: /tmp/05-media.txt"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module skickade inte rätt modul till process_module"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module hanterar befintlig modul"
}

run_install_named_module_multiple_test() {
    next_test

    local output
    local result

    source ./lib/install_core.sh

    find_module() {
        printf '%s\n' \
            '/tmp/apt/03-development.txt' \
            '/tmp/flatpak/01-development.txt' \
            '/tmp/npm/01-development.txt'
    }

    process_module() {
        printf 'PROCESS_MODULE: %s\n' "$1"
        return 0
    }

    if output=$(install_named_module development)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module misslyckades med flera matchande moduler"
        return 1
    fi

    local expected_output

    expected_output=$'PROCESS_MODULE: /tmp/apt/03-development.txt\nPROCESS_MODULE: /tmp/flatpak/01-development.txt\nPROCESS_MODULE: /tmp/npm/01-development.txt'

    if [[ "$output" != "$expected_output" ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module behandlade inte modulerna i rätt ordning"
        echo "Förväntat:"
        printf '%s\n' "$expected_output"
        echo "Fick:"
        printf '%s\n' "$output"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module hanterar flera matchande moduler"
}

run_install_named_module_middle_failure_test() {
    next_test

    local output
    local result

    source ./lib/install_core.sh

    find_module() {
        printf '%s\n' \
            '/tmp/apt/03-development.txt' \
            '/tmp/flatpak/01-development.txt' \
            '/tmp/npm/01-development.txt'
    }

    process_module() {
        printf 'PROCESS_MODULE: %s\n' "$1"

        if [[ "$1" == '/tmp/flatpak/01-development.txt' ]]
        then
            return 1
        fi

        return 0
    }

    if output=$(install_named_module development)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module returnerade inte 1 efter modulfelet"
        return 1
    fi

    local expected_output
    expected_output=$'PROCESS_MODULE: /tmp/apt/03-development.txt\nPROCESS_MODULE: /tmp/flatpak/01-development.txt\nPROCESS_MODULE: /tmp/npm/01-development.txt'

    if [[ "$output" != "$expected_output" ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module fortsatte inte efter modulfelet"
        echo "Förväntat:"
        printf '%s\n' "$expected_output"
        echo "Fick:"
        printf '%s\n' "$output"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module fortsätter efter modulfel"
}

run_install_named_module_failure_test() {
    next_test

    local result

    source ./lib/install_core.sh

    find_module() {
        printf '/tmp/05-media.txt\n'
    }

    process_module() {
        return 1
    }

    if install_named_module media
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_named_module propagaterade inte fel från process_module"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_named_module propagaterar fel"
}


run_install_all_modules_test() {
    next_test

    local output

    source ./lib/install_core.sh

    process_modules() {
        printf 'PROCESS_MODULES: %s | %s\n' "$1" "$2"
        return 0
    }

    output=$(install_all_modules)

    if [[ "$output" != *"PROCESS_MODULES: $PACKAGE_DIR | process_module"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_all_modules anropade inte process_modules korrekt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_all_modules använder process_modules korrekt"
}

run_install_all_modules_failure_test() {
    next_test

    local result

    source ./lib/install_core.sh

    process_modules() {
        return 1
    }

    if install_all_modules
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: install_all_modules propagaterade inte fel från process_modules"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: install_all_modules propagaterar fel"
}



run_load_backends_test() {
    next_test

    source ./lib/modules.sh

    load_backends

    if ! declare -F apt_is_installed >/dev/null
    then
        echo "[$TEST_NUMBER] FAIL: apt-backenden laddades inte"
        return 1
    fi

    if ! declare -F flatpak_is_installed >/dev/null
    then
        echo "[$TEST_NUMBER] FAIL: flatpak-backenden laddades inte"
        return 1
    fi

    if ! declare -F npm_is_installed >/dev/null
    then
        echo "[$TEST_NUMBER] FAIL: npm-backenden laddades inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: load_backends laddar alla backends"
}

run_apt_is_installed_test() {
    next_test

    local result

    source ./lib/apt.sh

    dpkg-query() {
        printf 'install ok installed\n'
        return 0
    }

    grep() {
        return 0
    }

    if apt_is_installed test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_is_installed borde hitta installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_is_installed hittar installerat paket"
}

run_apt_install_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/apt.sh

    DRY_RUN=true

    if output=$(apt_install test-package)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_install dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: apt-get install -y test-package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_install skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_install hanterar dry-run"
}

run_apt_install_test() {
    next_test

    local output
    local result

    source ./lib/apt.sh

    DRY_RUN=false

    sudo() {
        printf 'SUDO: %s\n' "$*"
        return 0
    }

    apt-get() {
        printf 'APT_GET: %s\n' "$*"
        return 0
    }

    if output=$(apt_install test-package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_install misslyckades"
        return 1
    fi

    if [[ "$output" != *"SUDO: apt-get install -y test-package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_install byggde fel installationskommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_install hanterar riktig installationsväg"
}

run_apt_install_failure_test() {
    next_test

    local result

    source ./lib/apt.sh

    DRY_RUN=false

    sudo() {
        printf 'SUDO: %s\n' "$*"
        return 1
    }

    if apt_install test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_install propagaterade inte installationsfelet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_install propagaterar installationsfel"
}


run_flatpak_is_installed_test() {
    next_test

    local result

    source ./lib/flatpak.sh

    flatpak() {
        return 0
    }

    if flatpak_is_installed test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_is_installed borde hitta installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_is_installed hittar installerat paket"
}

run_flatpak_is_installed_failure_test() {
    next_test

    local result

    source ./lib/flatpak.sh

    flatpak() {
        return 1
    }

    if flatpak_is_installed test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_is_installed borde returnera 1 för ej installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_is_installed hanterar ej installerat paket"
}

run_flatpak_install_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/flatpak.sh

    DRY_RUN=true

    if output=$(flatpak_install test-package)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_install dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: flatpak install -y flathub test-package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_install skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_install hanterar dry-run"
}

run_flatpak_install_test() {
    next_test

    local output
    local result

    source ./lib/flatpak.sh

    DRY_RUN=false

    flatpak() {
        printf 'FLATPAK: %s\n' "$*"
        return 0
    }

    if output=$(flatpak_install test.package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_install misslyckades"
        return 1
    fi

    if [[ "$output" != *"FLATPAK: install -y flathub test.package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_install byggde fel installationskommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_install hanterar riktig installationsväg"
}

run_flatpak_install_failure_test() {
    next_test

    local result

    source ./lib/flatpak.sh

    DRY_RUN=false

    flatpak() {
        return 1
    }

    if flatpak_install test.package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_install propagaterade inte installationsfelet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_install propagaterar installationsfel"
}


run_npm_is_installed_test() {
    next_test

    local result

    source ./lib/npm.sh

    npm() {
        return 0
    }

    if npm_is_installed test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_is_installed borde hitta installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_is_installed hittar installerat paket"
}

run_npm_is_installed_failure_test() {
    next_test

    local result

    source ./lib/npm.sh

    npm() {
        return 1
    }

    if npm_is_installed test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_is_installed borde returnera 1 för ej installerat paket"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_is_installed hanterar ej installerat paket"
}

run_npm_install_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/npm.sh

    DRY_RUN=true

    if output=$(npm_install test-package)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: npm install --prefix \"$HOME/.local\" -g test-package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_install hanterar dry-run"
}

run_npm_install_test() {
    next_test

    local output
    local result

    source ./lib/npm.sh

    DRY_RUN=false

    npm() {
        printf 'NPM: %s\n' "$*"
        return 0
    }

    if output=$(npm_install test-package)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install misslyckades"
        return 1
    fi

    if [[ "$output" != *"NPM: install"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install anropade inte npm install"
        return 1
    fi

    if [[ "$output" != *"--prefix"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install saknar --prefix"
        return 1
    fi

    if [[ "$output" != *"-g test-package"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install skickade inte paketet korrekt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_install hanterar riktig installationsväg"
}

run_npm_install_failure_test() {
    next_test

    local result

    source ./lib/npm.sh

    DRY_RUN=false

    npm() {
        return 1
    }

    if npm_install test-package
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_install propagaterade inte installationsfelet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_install propagaterar installationsfel"
}


run_tailscale_repository_exists_test() {
    next_test

    local test_dir
    local repository_file
    local result

    source ./lib/repositories.sh

    test_dir=$(mktemp -d)
    repository_file="$test_dir/tailscale.list"

    touch "$repository_file"

    TAILSCALE_REPOSITORY_FILE="$repository_file"

    if tailscale_repository_exists
    then
        result=0
    else
        result=$?
    fi

    rm -rf "$test_dir"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: tailscale_repository_exists hittade inte repository-filen"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: tailscale_repository_exists hittar befintligt repository"
}

run_tailscale_repository_exists_failure_test() {
    next_test

    local test_dir
    local output
    local result

    test_dir=$(mktemp -d)

    if output=$(
        /bin/bash -c '
            source ./lib/repositories.sh

            TAILSCALE_REPOSITORY_FILE="$1"

            tailscale_repository_exists
        ' -- "$test_dir/tailscale.list"
    )
    then
        result=0
    else
        result=$?
    fi

    /usr/bin/rm -rf "$test_dir"

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: tailscale_repository_exists borde returnera 1 när repository-filen saknas"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: tailscale_repository_exists hanterar saknad repository-fil"
}

run_ensure_tailscale_repository_test() {
    next_test

    local output
    local result

    source ./lib/repositories.sh

    tailscale_repository_exists() {
        return 1
    }

    add_tailscale_repository() {
        printf 'ADD_TAILSCALE_REPOSITORY\n'
        return 0
    }

    if output=$(ensure_tailscale_repository)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: ensure_tailscale_repository misslyckades när repository saknas"
        return 1
    fi

    if [[ "$output" != *"ADD_TAILSCALE_REPOSITORY"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: ensure_tailscale_repository lade inte till repositoryt"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: ensure_tailscale_repository lägger till saknat repository"
}

run_ensure_tailscale_repository_failure_test() {
    next_test

    local result

    source ./lib/repositories.sh

    tailscale_repository_exists() {
        return 1
    }

    add_tailscale_repository() {
        return 1
    }

    if ensure_tailscale_repository
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: ensure_tailscale_repository propagaterade inte repository-felet"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: ensure_tailscale_repository propagaterar repository-fel"
}


run_ensure_tailscale_repository_exists_test() {
    next_test

    local output
    local result

    source ./lib/repositories.sh

    tailscale_repository_exists() {
        return 0
    }

    add_tailscale_repository() {
        printf 'ADD_TAILSCALE_REPOSITORY\n'
        return 0
    }

    if output=$(ensure_tailscale_repository)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: ensure_tailscale_repository misslyckades för befintligt repository"
        return 1
    fi

    if [[ "$output" == *"ADD_TAILSCALE_REPOSITORY"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: befintligt repository skulle inte läggas till"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: ensure_tailscale_repository lämnar befintligt repository orört"
}

run_print_help_test() {
    next_test

    local output
    local expected_version

    expected_version=$(cat VERSION)
    output=$(print_help)


    if [[ ! "$output" =~ Henric[[:space:]]+Workstation[[:space:]]+Bootstrap ]]
    then
        echo "[$TEST_NUMBER] FAIL: print_help saknar projektnamn"
        return 1
    fi

    if [[ "$output" != *"v$expected_version"* ]]
    then
    echo "[$TEST_NUMBER] FAIL: print_help visar fel version"
    return 1
    fi

    for option in --help --list --summary --install --doctor --update
    do
        if [[ "$output" != *"$option"* ]]
        then
            echo "[$TEST_NUMBER] FAIL: print_help saknar $option"
            return 1
        fi
    done

    echo "[$TEST_NUMBER] OK: print_help visar hjälptext och alternativ"
}

run_apt_update_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/apt.sh

    DRY_RUN=true

    if output=$(apt_update)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: apt-get update && apt-get upgrade -y"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_update hanterar dry-run"
}

run_apt_update_test() {
    next_test

    local output
    local result

    source ./lib/apt.sh

    DRY_RUN=false

    sudo() {
        printf 'SUDO: %s\n' "$*"
        return 0
    }

    if output=$(apt_update)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update misslyckades"
        return 1
    fi

    if [[ "$output" != $'SUDO: apt-get update\nSUDO: apt-get upgrade -y' ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update anropade inte rätt kommandon i rätt ordning"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_update hanterar riktig uppdateringsväg"
}

run_apt_update_failure_test() {
    next_test

    local output
    local result

    source ./lib/apt.sh

    DRY_RUN=false

    sudo() {
        printf 'SUDO: %s\n' "$*"

        if [[ "$2" == "update" ]]
        then
            return 1
        fi

        return 0
    }

    set +e
    output=$(apt_update)
    result=$?
    set -e

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update borde returnera 1 när update misslyckas"
        return 1
    fi

    if [[ "$output" != *"SUDO: apt-get update"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update körde inte apt-get update"
        return 1
    fi

    if [[ "$output" == *"SUDO: apt-get upgrade -y"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt-get upgrade kördes trots misslyckad update"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_update stoppar vid misslyckad update"
}

run_apt_update_upgrade_failure_test() {
    next_test

    local output
    local result

    source ./lib/apt.sh

    DRY_RUN=false

    sudo() {
        printf 'SUDO: %s\n' "$*"

        if [[ "$2" == "upgrade" ]]
        then
            return 1
        fi

        return 0
    }

    set +e
    output=$(apt_update)
    result=$?
    set -e

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt_update borde returnera 1 när upgrade misslyckas"
        return 1
    fi

    if [[ "$output" != *"SUDO: apt-get update"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt-get update kördes inte"
        return 1
    fi

    if [[ "$output" != *"SUDO: apt-get upgrade -y"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: apt-get upgrade kördes inte"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: apt_update propagerar fel från upgrade"
}

run_flatpak_update_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/flatpak.sh

    DRY_RUN=true

    if output=$(flatpak_update)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: flatpak update -y"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_update hanterar dry-run"
}

run_flatpak_update_test() {
    next_test

    local output
    local result

    source ./lib/flatpak.sh

    DRY_RUN=false

    flatpak() {
        printf 'FLATPAK: %s\n' "$*"
        return 0
    }

    if output=$(flatpak_update)
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update misslyckades"
        return 1
    fi

    if [[ "$output" != "FLATPAK: update -y" ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update anropade fel kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_update hanterar riktig uppdateringsväg"
}

run_flatpak_update_failure_test() {
    next_test

    local output
    local result

    source ./lib/flatpak.sh

    DRY_RUN=false

    flatpak() {
        printf 'FLATPAK: %s\n' "$*"
        return 1
    }

    set +e
    output=$(flatpak_update)
    result=$?
    set -e

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update borde returnera 1 när uppdateringen misslyckas"
        return 1
    fi

    if [[ "$output" != "FLATPAK: update -y" ]]
    then
        echo "[$TEST_NUMBER] FAIL: flatpak_update anropade inte rätt kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: flatpak_update propagerar uppdateringsfel"
}

run_npm_update_dry_run_test() {
    next_test

    local output
    local result
    local original_dry_run="${DRY_RUN:-false}"

    source ./lib/npm.sh

    DRY_RUN=true

    if output=$(npm_update)
    then
        result=0
    else
        result=$?
    fi

    DRY_RUN="$original_dry_run"

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_update dry-run returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"DRY RUN: npm update --prefix \"$HOME/.local\" -g"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_update skrev ut fel dry-run-kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_update hanterar dry-run"
}

run_npm_update_test() {
    next_test

    local output
    local result

    source ./lib/npm.sh

    npm() {
        echo "STUB: npm $*"
    }

    if output=$(npm_update)
    then
        result=0
    else
        result=$?
    fi

    unset -f npm

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_update returnerade status $result"
        return 1
    fi

    if [[ "$output" != *"STUB: npm update --prefix $HOME/.local -g"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_update anropade fel kommando"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_update hanterar riktig uppdateringsväg"
}

run_npm_update_failure_test() {
    next_test

    local result

    source ./lib/npm.sh

    npm() {
        return 42
    }

    if npm_update
    then
        result=0
    else
        result=$?
    fi

    unset -f npm

    if [[ "$result" -ne 42 ]]
    then
        echo "[$TEST_NUMBER] FAIL: npm_update returnerade status $result istället för 42"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: npm_update propagerar uppdateringsfel"
}

run_main_update_failure_test() {
    next_test

    local output
    local result

    if output=$(bash -c '
    source ./bootstrap.sh

    update_system() {
        return 7
    }

    main --update
    ' 2>&1)
    then
    result=0
    else
    result=$?
    fi

    if [[ "$result" -ne 7 ]]
    then
        echo "[$TEST_NUMBER] FAIL: main returnerade status $result i stället för 7"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: main propagerar felstatus från --update"
}

run_update_system_test() {
    next_test

    local output
    local result

    apt_update() {
        echo "STUB: apt_update"
    }

    flatpak_update() {
        echo "STUB: flatpak_update"
    }

    npm_update() {
        echo "STUB: npm_update"
    }

    load_backends() {
        return 0
    }

    source ./lib/update.sh

    if output=$(update_system)
    then
        result=0
    else
        result=$?
    fi

    unset -f apt_update flatpak_update npm_update

    if [[ "$result" -ne 0 ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system returnerade status $result"
        return 1
    fi

    if [[ "$output" != $'STUB: apt_update\nSTUB: flatpak_update\nSTUB: npm_update' ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system anropade inte backenderna i rätt ordning"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: update_system anropar alla backends i rätt ordning"
}

run_update_system_failure_test() {
    next_test

    local output
    local result

    apt_update() {
        echo "STUB: apt_update"
        return 1
    }

    flatpak_update() {
        echo "STUB: flatpak_update"
    }

    npm_update() {
        echo "STUB: npm_update"
    }

    load_backends() {
        return 0
    }

    source ./lib/update.sh

    if output=$(update_system)
    then
        result=0
    else
        result=$?
    fi

    unset -f apt_update flatpak_update npm_update

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system returnerade status $result istället för 1"
        return 1
    fi

    if [[ "$output" != *"STUB: flatpak_update"* ||
          "$output" != *"STUB: npm_update"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system fortsatte inte med alla backends"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: update_system fortsätter efter backend-fel"
}

run_update_system_middle_failure_test() {
    next_test

    local output
    local result

    apt_update() {
        echo "STUB: apt_update"
    }

    flatpak_update() {
        echo "STUB: flatpak_update"
        return 1
    }

    npm_update() {
        echo "STUB: npm_update"
    }

    load_backends() {
        return 0
    }

    source ./lib/update.sh

    if output=$(update_system)
    then
        result=0
    else
        result=$?
    fi

    unset -f apt_update flatpak_update npm_update

    if [[ "$result" -ne 1 ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system returnerade status $result istället för 1"
        return 1
    fi

    if [[ "$output" != *"STUB: apt_update"* ||
          "$output" != *"STUB: flatpak_update"* ||
          "$output" != *"STUB: npm_update"* ]]
    then
        echo "[$TEST_NUMBER] FAIL: update_system fortsatte inte efter Flatpak-fel"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: update_system fortsätter efter fel i mellanbackend"
}

run_parse_arguments_update_failure_test() {
    next_test

    source ./lib/cli.sh

    update_system() {
        return 7
    }

    info() {
        :
    }

    local result

    if parse_arguments --update
    then
        result=0
    else
        result=$?
    fi

    if [[ "$result" -ne 7 ]]
    then
        echo "[$TEST_NUMBER] FAIL: --update returnerade status $result i stället för 7"
        return 1
    fi

    echo "[$TEST_NUMBER] OK: --update propagerar felstatus"
}




run_named_module_test
run_backend_function_test
run_get_backend_test
run_supported_backend_test
run_read_module_test
run_find_modules_test
run_find_module_test
run_count_modules_test
run_process_modules_test
run_process_modules_failure_test
run_process_module_test
run_process_module_failure_test
run_count_all_packages_test
run_process_modules_unknown_backend_test
run_process_module_backend_test
run_package_repository_test
run_ensure_repository_test
run_ensure_repository_failure_test
run_npm_helpers_test
run_npm_path_test
run_package_exists_test
run_package_installed_test
run_verify_package_missing_test
run_verify_package_not_installed_test
run_print_summary_test
run_parse_arguments_version_test
run_parse_arguments_help_test
run_verify_package_installed_test
run_print_modules_test
run_parse_arguments_list_test
run_parse_arguments_summary_test
run_parse_arguments_doctor_test
run_parse_arguments_install_all_test
run_parse_arguments_install_named_test
run_parse_arguments_install_failure_test
run_parse_arguments_dry_run_test
run_parse_arguments_dry_run_named_module_test
run_parse_arguments_invalid_test
run_parse_arguments_multiple_commands_test
run_check_file_test
run_check_directory_test
run_check_project_test
run_doctor_test
run_check_environment_test
run_check_environment_failure_test
run_check_commands_test
run_check_commands_failure_test
run_check_package_manager_test
run_check_required_commands_test
run_print_doctor_summary_test
run_print_doctor_summary_failure_test
run_check_os_test
run_check_os_detection_failure_test
run_check_os_wrong_os_test
run_check_architecture_test
run_check_architecture_unsupported_test
run_check_architecture_detection_failure_test
run_check_sudo_test
run_check_sudo_missing_test
run_check_sudo_group_failure_test
run_check_sudo_password_required_test
run_check_network_test
run_check_network_failure_test
run_detect_system_test
run_detect_system_missing_file_test
run_section_test
run_log_test
run_info_test
run_success_test
run_warn_test
run_error_test
run_banner_test
run_install_named_module_missing_test
run_install_named_module_missing_set_e_test
run_install_named_module_test
run_install_named_module_multiple_test
run_install_named_module_middle_failure_test
run_install_named_module_failure_test
run_install_all_modules_test
run_install_all_modules_failure_test
run_load_backends_test
run_apt_is_installed_test
run_apt_install_dry_run_test
run_apt_install_test
run_apt_install_failure_test
run_flatpak_is_installed_test
run_flatpak_is_installed_failure_test
run_flatpak_install_dry_run_test
run_flatpak_install_test
run_flatpak_install_failure_test
run_npm_is_installed_test
run_npm_is_installed_failure_test
run_npm_install_dry_run_test
run_npm_install_test
run_npm_install_failure_test
run_tailscale_repository_exists_test
run_tailscale_repository_exists_failure_test
run_ensure_tailscale_repository_test
run_ensure_tailscale_repository_failure_test
run_ensure_tailscale_repository_exists_test
run_print_help_test
run_apt_update_dry_run_test
run_apt_update_test
run_apt_update_failure_test
run_apt_update_upgrade_failure_test
run_flatpak_update_dry_run_test
run_flatpak_update_test
run_flatpak_update_failure_test
run_npm_update_dry_run_test
run_npm_update_test
run_npm_update_failure_test
run_main_update_failure_test
run_update_system_test
run_update_system_failure_test
run_update_system_middle_failure_test
run_parse_arguments_update_failure_test
run_parse_arguments_install_update_test