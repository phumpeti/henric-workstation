#!/usr/bin/env bash

set -Eeuo pipefail

readonly VERSION="0.4.0"

source config/environment.conf

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_DIR="$SCRIPT_DIR/packages"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/modules.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/cli.sh" 

main() {
	parse_arguments "$@"
}

main "$@"
