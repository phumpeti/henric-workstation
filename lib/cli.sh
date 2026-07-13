parse_arguments() {

    case "${1:-}" in

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

        *)

            banner
            check_environment
            print_modules "$PACKAGE_DIR"
            ;;

	*)
	    error "Okänt argument: $1"
	    echo
	    print_help
	    exit 1
	    ;;

    esac

}
