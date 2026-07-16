#!/usr/bin/env bash

# install.sh
#
# Ansvar:
# - installera moduler
# - installera paket
#
# Installerar bara.

declare -i installed_count=0
declare -i skipped_count=0
declare -i dry_run_count=0
declare -i failed_count=0

install_all_modules() {

    while IFS= read -r module
    do

        install_module "$module"
        print_install_status "$status"

    done < <(find_modules "$PACKAGE_DIR")

}

install_module() {

    local module="$1"
    local total
    local current=0
    local package
    local status

    total=$(count_packages "$module")

    section "Installerar modul: $(basename "$module" .txt)"

    while IFS= read -r package
    do
        ((current++))

        printf "[%02d/%02d] %-30s" \
            "$current" \
            "$total" \
            "$package"

        install_package "$package"
        status=$?
        print_install_status "$status"

    done < <(read_module "$module")
}

print_install_status() {

    local status="$1"

    case "$status" in

        "$STATUS_OK")
            ((installed_count++))
            echo " [ OK ]"
            ;;

        "$STATUS_ALREADY_INSTALLED")
            ((skipped_count++))
            echo " [SKIP]"
            ;;

        "$STATUS_DRY_RUN")
            ((dry_run_count++))
            echo " [DRY ]"
            ;;

        "$STATUS_FAILED")
            ((failed_count++))
            echo " [FAIL]"
            ;;

    esac
}


install_package() {

    local package="$1"

    if ! package_exists "$package"; then
        return 30
    fi

    if package_installed "$package"; then
        return 10
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 20
    fi

    if install_with_apt "$package"; then
        return 0
    fi

    return 30
}

install_with_apt() {

    local package="$1"

    sudo apt install -y "$package"
}

print_install_summary() {

    echo
    echo "========================================"
    echo "Installation klar"
    echo "========================================"
    echo
    printf "Installerade:        %d\n" "$installed_count"
    printf "Redan installerade: %d\n" "$skipped_count"
    printf "Dry run:            %d\n" "$dry_run_count"
    printf "Misslyckades:       %d\n" "$failed_count"
}
