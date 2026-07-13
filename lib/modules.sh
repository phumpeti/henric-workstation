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

read_module() {

    local module="$1"

    while read -r package
    do
        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^# ]] && continue

        printf "%s\n" "$package"

    done < "$module"
}

install_module() {

    local module="$1"

    while read -r package
    do

        install_package "$package"

    done < <(read_module "$module")

}

install_all_modules() {

    while read -r module
    do

        install_module "$module"

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
