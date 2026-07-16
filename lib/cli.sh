#!/usr/bin/env bash

parse_arguments() {

    local command=""
    local module packages

# printf "DEBUG: argument = '%s'\n" "${1:-}"

   while [[ $# -gt 0 ]] ; do

    case "$1" in

        --dry-run)

            DRY_RUN=true
            ;;

        --install)

            command="install"
            ;;

        --summary)

            command="summary"
            ;;

        --list)

            command="list"
            ;;

        --help|-h)

            command="help"
            ;;

        --version)

            command="version"
            ;;

        *)

            error "Okänt argument: $1"
            exit 1
            ;;

    esac

    shift

done

case "$command" in

    "")

        banner
        check_environment
        print_modules "$PACKAGE_DIR"
        ;;

    help)

        print_help
        ;;

    version)

        printf "%s\n" "$VERSION"
        ;;

    list)

        print_modules "$PACKAGE_DIR"
        ;;

    summary)

        local modules
        local packages

        modules=$(count_modules "$PACKAGE_DIR")
        packages=$(count_all_packages "$PACKAGE_DIR")

        print_summary "$modules" "$packages"
        ;;

    install)

        if [[ "$DRY_RUN" == true ]]; then
            warn "DRY RUN - inga paket kommer att installeras."
            echo
        fi

        install_all_modules
        ;;

esac
}
