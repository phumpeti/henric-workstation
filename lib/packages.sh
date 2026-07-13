#!/bin/bash

install_package() {

    local package="$1"

    info "Installerar $package..."

#    sudo apt install -y "$package"

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
