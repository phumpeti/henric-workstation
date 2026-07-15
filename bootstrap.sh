#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="$(<"$SCRIPT_DIR/VERSION")"

readonly PACKAGE_DIR="$SCRIPT_DIR/packages"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly CONFIG_DIR="$SCRIPT_DIR/config"

source "$CONFIG_DIR/environment.conf"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/cli.sh"

readonly LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"

readonly LOG_FILE="$LOG_DIR/bootstrap-$(date +%F).log"

main() {
	parse_arguments "$@"
}

main "$@"
