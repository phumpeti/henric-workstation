#!/usr/bin/env bash


count_modules() {

    local package_dir="$1"

    find_modules "$package_dir" | wc -l

}


find_modules() {

    local package_dir="$1"

    find "$package_dir" \
        -maxdepth 1 \
        -name "*.txt" \
        | sort
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
