#!/usr/bin/env bash

# modules.sh
#
# Ansvar:
# - Hitta moduler
# - Räkna moduler
# - Skriva ut moduler
#
# Hanterar aldrig paket.

find_module() {
    local name="$1"
    local backend_dir

    while IFS= read -r backend_dir
    do
        find_modules "$backend_dir" |
            grep -E "/[0-9]+-${name}\.txt$"

    done < <(
        find "$PACKAGE_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d |
            sort
    )
}

find_modules() {

    local package_dir="$1"

    find "$package_dir" \
        -maxdepth 1 \
        -type f \
        -name "*.txt" \
        | sort
}

count_modules() {
    local package_dir="$1"
    local backend_dir
    local total=0

    while IFS= read -r backend_dir
    do
        (( total += $(find_modules "$backend_dir" | wc -l) ))
    done < <(
        find "$package_dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d |
        sort
    )

    echo "$total"
}


print_modules() {

    local package_dir="$1"

    while read -r module
    do
        local count

        count=$(count_packages "$module")

        printf "✓ %-25s (%2d paket)\n" \
            "$(basename "$module")" \
            "$count"

    done < <(find_modules "$package_dir")

}

test_read_module() {

    printf "Testar read_module... "

    if [[ $(read_module packages/01-base.txt | wc -l) -eq 16 ]]
    then
        success "OK"
    else
        error "FAIL"
    fi

}

read_module() {
    local module="$1"

    while IFS= read -r package
    do
        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^[[:space:]]*# ]] && continue

        printf '%s\n' "$package"
    done < "$module"
}

process_module() {
    local module="$1"
    local backend
    local -a backend_functions
    local -a missing_packages=()

    load_backends

    backend=$(get_backend "$module")

   mapfile -t backend_functions < <(get_backend_functions "$backend")

    if (( ${#backend_functions[@]} != 2 ))
    then
        error "Felaktigt antal backend-funktioner för: $backend"
        return 1
    fi

    printf 'Kontrollfunktion: %s\n' "${backend_functions[0]}"
    printf 'Installationsfunktion: %s\n' "${backend_functions[1]}"

    if ! declare -F "${backend_functions[0]}" >/dev/null
    then
        error "Kontrollfunktionen saknas: ${backend_functions[0]}"
        return 1
    fi

    if ! declare -F "${backend_functions[1]}" >/dev/null
    then
        error "Installationsfunktionen saknas: ${backend_functions[1]}"
        return 1
    fi

    printf 'Modul: %s\n' "$(basename "$module")"
    printf 'Backend: %s\n' "$backend"

    while IFS= read -r package
    do
        if "${backend_functions[0]}" "$package"
        then
            printf 'Installerat: %s\n' "$package"
        else
            printf 'Saknas: %s\n' "$package"
            missing_packages+=("$package")
        fi
    done < <(read_module "$module")

    printf '\nSaknade paket: %d\n' "${#missing_packages[@]}"

if [[ "${DRY_RUN:-false}" != true ]]
then
    for package in "${missing_packages[@]}"
    do
        repository=$(package_repository "$package") || true

        if [[ -n "$repository" ]]
        then
            if ! ensure_repository "$repository"
            then
                error "Kunde inte förbereda repository: $repository"
                return 1
            fi
        fi
    done
fi

if (( ${#missing_packages[@]} > 0 ))
then
    if ! "${backend_functions[1]}" "${missing_packages[@]}"
    then
        error "Installation misslyckades för modul: $(basename "$module")"
        return 1
    fi
fi

return 0
}

process_modules() {
    local package_dir="$1"
    local callback="$2"
    local backend_dir
    local status=0


    while IFS= read -r backend_dir
    do
        backend=$(basename "$backend_dir")

        if ! is_supported_backend "$backend"
        then
            warn "Hoppar över okänd backend: $backend"
            continue
        fi

        while IFS= read -r module
        do
            if ! "$callback" "$module"
            then
                status=1
            fi
        done < <(find_modules "$backend_dir")

    done < <(
        find "$package_dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d |
            sort
    )

    return "$status"
}


get_backend() {
    local module="$1"

    basename "$(dirname "$module")"
}

get_backend_functions() {
    local backend="$1"

    case "$backend" in
        apt)
            printf '%s\n' "apt_is_installed"
            printf '%s\n' "apt_install"
            ;;

        flatpak)
            printf '%s\n' "flatpak_is_installed"
            printf '%s\n' "flatpak_install"
            ;;
        npm)
            printf '%s\n' "npm_is_installed"
            printf '%s\n' "npm_install"
            ;;
        *)
            error "Okänd backend: $backend"
            return 1
            ;;
    esac
}

is_supported_backend() {
    local backend="$1"

    case "$backend" in
        apt|flatpak|npm)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

load_backends() {
    source "$SCRIPT_DIR/lib/apt.sh"
    source "$SCRIPT_DIR/lib/flatpak.sh"
    source "$SCRIPT_DIR/lib/npm.sh"
}