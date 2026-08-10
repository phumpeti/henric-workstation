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

    find_modules "$PACKAGE_DIR" |
        grep -E "/[0-9]+-${name}\.txt$"
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

    find_modules "$package_dir" | wc -l

}

process_modules() {

    local callback="$1"

    while IFS= read -r module
    do
        "$callback" "$module"

    done < <(find_modules "$PACKAGE_DIR")

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


