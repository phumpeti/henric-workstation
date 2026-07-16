#!/usr/bin/env bash

# packages.sh
#
# Ansvar:
# - Läsa paket ur moduler
# - Verifiera paket
# - Hantera paketinformation
#
# Hanterar inte CLI eller loggning.

##################################################
# Module functions
##################################################

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

##################################################
# Package verification
##################################################

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



