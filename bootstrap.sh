#!/usr/bin/env bash

set -Eeuo pipefail

readonly VERSION="0.2.0"

source config/environment.conf

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_DIR="$SCRIPT_DIR/packages"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"
source "$SCRIPT_DIR/lib/packages.sh"

main() {

    banner

    check_environment

    print_modules "$PACKAGE_DIR"

    local modules
    local packages

    modules=$(count_modules "$PACKAGE_DIR")
    packages=$(count_all_packages "$PACKAGE_DIR")

    print_summary "$modules" "$packages"

    info "Bootstrap klar."
}
main "$@"
