#!/usr/bin/env bash

parse_arguments() {

    local command=""
    local module=""
    local packages=""
    local modules=""


   while [[ $# -gt 0 ]] ; do

    case "$1" in

        --doctor)

            command="doctor"
            ;;

        --dry-run)

            DRY_RUN=true
            ;;

        --install)

            command="install"

            if [[ $# -gt 1 && "${2:0:1}" != "-" ]]; then
                module="$2"
                shift
            fi

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

    doctor)

        doctor
        ;;

    help)

        print_help
        ;;

    version)

        printf "%s\n" "$APP_VERSION"
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
        if [[ "${DRY_RUN:-false}" == true ]]; then
            warn "DRY RUN - inga paket kommer att installeras."
            echo
        fi

         if [[ -n "$module" ]]; then
            install_named_module "$module"
        else
            install_all_modules
        fi

        ;;

esac


info "Tid: ${SECONDS}s"
}
