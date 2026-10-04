#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly APP_VERSION="$(cat VERSION)"
readonly PACKAGE_DIR="$SCRIPT_DIR/packages"
readonly LIB_DIR="$SCRIPT_DIR/lib"

# Konstanter
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/exit_codes.sh"

# Bibliotek
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"
source "$SCRIPT_DIR/lib/update.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/install_core.sh"
source "$SCRIPT_DIR/lib/cli.sh"
source "$SCRIPT_DIR/lib/doctor.sh"
source "$SCRIPT_DIR/lib/system.sh"

main() {
    parse_arguments "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
