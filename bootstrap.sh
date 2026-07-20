#!/usr/bin/env bash

set -Eeuo pipefail

readonly START_TIME=$SECONDS

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="$(<"$SCRIPT_DIR/VERSION")"

readonly PACKAGE_DIR="$SCRIPT_DIR/packages"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly CONFIG_DIR="$SCRIPT_DIR/config"

# Konfiguration
source "$CONFIG_DIR/environment.conf"

# Konstanter
source "$SCRIPT_DIR/lib/constants.sh"
source "$SCRIPT_DIR/lib/exit_codes.sh"

# Bibliotek
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/install.sh"
source "$SCRIPT_DIR/lib/cli.sh"
source "$SCRIPT_DIR/lib/doctor.sh"


readonly LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"

readonly LOG_FILE="$LOG_DIR/bootstrap-$(date +%F).log"

main() {

	parse_arguments "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
