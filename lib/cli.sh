#!/usr/bin/env bash

parse_arguments() {


# printf "DEBUG: argument = '%s'\n" "${1:-}"

    case "${1:-}" in

        "")
	   banner
	   check_environment
	   print_modules "$PACKAGE_DIR"
	   ;;

	--dry-run)
	    DRY_RUN=true
	    ;;

	--help|-h)

	    print_help
	    ;;

        --list)

            print_modules "$PACKAGE_DIR"
            ;;

        --summary)

            local modules
            local packages

            modules=$(count_modules "$PACKAGE_DIR")
            packages=$(count_all_packages "$PACKAGE_DIR")

            print_summary "$modules" "$packages"
            ;;

	--version)
    	    printf "%s\n" "$VERSION"
            ;;


	*)

	    error "Okänt argument: ${1:-}"
	    printf "Skriv '%s --help' för hjälp.\n" "$(basename "$0")"
	    exit 1
	    ;;

    esac
}
