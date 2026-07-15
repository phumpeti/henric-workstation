#!/usr/bin/env bash

# modules.sh
#
# Ansvar:
# - Hitta moduler
# - Räkna moduler
# - Skriva ut moduler
#
# Hanterar aldrig paket.

find_modules() {

    local PACKAGE_DIR="$1"

    find "$PACKAGE_DIR" \
        -maxdepth 1 \
        -type f \
        -name "*.txt" \
        | sort
}

count_modules() {

    local package_dir="$1"

    find_modules "$package_dir" | wc -l

}

install_module() {

    local module="$1"

    while read -r package
    do

        install_package "$package"

    done < <(read_module "$module")

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

    done < <(find_modules "$PACKAGE_DIR")

}

install_all_modules() {

    while read -r module
    do

        install_module "$module"

    done < <(find_modules "$PACKAGE_DIR")

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
