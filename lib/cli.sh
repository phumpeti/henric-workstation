#!/usr/bin/env bash

parse_arguments() {

    local command=""
    local module=""
    local command_set=false



   while [[ $# -gt 0 ]] ; do

    case "$1" in

        --doctor)

    if [[ "$command_set" == true ]]; then
        error "Flera huvudkommandon angavs: $command och doctor"
        return 1
    fi

    command="doctor"
    command_set=true
    ;;

        --dry-run)

            DRY_RUN=true
            ;;

        --update)
            if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och update"
                return 1
            fi

            command="update"
            command_set=true
            ;;

        --install)

             if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och install"
                return 1
            fi

            command="install"
            command_set=true

            if [[ $# -gt 1 && "${2:0:1}" != "-" ]]; then
                module="$2"
                shift
            fi

    ;;

        --summary)


             if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och summary"
                return 1
            fi

            command="summary"
            command_set=true

    ;;

        --list)

               if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och list"
                return 1
            fi

            command="list"
            command_set=true
            ;;

        --help|-h)

               if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och help"
                return 1
            fi

            command="help"
            command_set=true
            ;;

        --version)

               if [[ "$command_set" == true ]]; then
                error "Flera huvudkommandon angavs: $command och version"
                return 1
            fi

            command="version"
            command_set=true
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

    update)
        if [[ "${DRY_RUN:-false}" == true ]]; then
            warn "DRY RUN - inga uppdateringar kommer att utföras."
            echo
        fi

        update_system
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

local command_status=$?

info "Tid: ${SECONDS}s"

return "$command_status"
}