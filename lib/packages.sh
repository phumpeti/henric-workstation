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

count_all_packages() {
    local package_dir="$1"
    local backend_dir
    local module
    local total=0
    local count

    while IFS= read -r backend_dir
    do
        while IFS= read -r module
        do
            count=$(grep -v '^[[:space:]]*$' "$module" |
                    grep -v '^[[:space:]]*#' |
                    wc -l)

            (( total += count ))
        done < <(find_modules "$backend_dir")

    done < <(
        find "$package_dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d |
            sort
    )

    echo "$total"
}



