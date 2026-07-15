#!/usr/bin/env bash

# packages.sh
#
# Ansvar:
# - Läsa paket ur moduler
# - Verifiera paket
# - Hantera paketinformation
#
# Hanterar inte CLI eller loggning.

read_module() {

    local module="$1"

    if [[ ! -f "$module" ]]; then
        error "Modulen '$module' finns inte."
        return 1
    fi

    while IFS= read -r package
    do
        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^[[:space:]]*# ]] && continue

        printf "%s\n" "$package"

    done < "$module"

}

count_packages() {

    local module="$1"

    grep -v '^[[:space:]]*$' "$module" \
        | grep -v '^#' \
        | wc -l

}

count_all_packages() {

    local package_dir="$1"
    local total=0

    while read -r module
    do
        (( total += $(count_packages "$module") ))

    done < <(find_modules "$package_dir")

    echo "$total"
}

package_exists() {

    local package="$1"

    if apt-cache show "$package" >/dev/null 2>&1; then
	return 0
    else
	return 1
    fi

}

package_installed() {

    dpkg -s "$1" >/dev/null 2>&1

}

verify_package() {

    local package="$1"

    if ! package_exists "$package"; then

        error "$package finns inte."

        return 1

    fi

    if package_installed "$package"; then

        success "$package är installerat."

    else

        warn "$package finns men är inte installerat."

    fi

}

install_with_apt() {

    local package="$1"

    sudo apt install -y "$package"
}

install_package() {

    local package="$1"

# Finns paketet?
    package_exists "$package" || {

        error "Paketet '$package' finns inte."
        return 1

    }

# Redan installerat?
    package_installed "$package" && {

        info "$package är redan installerat."
        return 0

    }
# Möjlighet att göra en torrkörning

    if [[ "$DRY_RUN" == true ]]; then
        info "Skulle installera: $package"
        return 0
    fi

    info "Installerar $package..."

# Installera paketet
    install_with_apt "$package"

if install_with_apt "$package"; then

    success "$package installerades."

else

    error "Kunde inte installera $package."

    return 1

fi

}

install_module() {

    local module="$1"

    info "Installerar modul $(basename "$module")"

    while IFS= read -r package
    do
        install_package "$package"

    done < <(read_module "$module")

}





