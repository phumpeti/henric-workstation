#!/usr/bin/env bash

success_count=0
info_count=0
warning_count=0
error_count=0

banner() {

cat << EOF

Henric Workstation Bootstrap

Version $APP_VERSION

EOF
}

log() {

    local timestamp
    local level="$1"
    shift

    timestamp=$(date '+%F %T')

    case "$level" in

        FAIL)
            printf "[%s] %s-5s %s\n" "$timestamp" "$level" "$*" >&2
            ;;

        *)
            printf "[%s] %s-5a %s\n" "$timestamp" "$level" "$*" >&2
            ;;

    esac
}

info() {
    if [[ "$DOCTOR_MODE" == true ]]; then
        ((++info_count))
    fi
    log INFO "$@"
}

success() {
    if [[ "$DOCTOR_MODE" == true ]]; then
    ((++success_count))
    fi
    log " OK " "$@"
}

warn() {
    if [[ "$DOCTOR_MODE" == true ]]; then
    ((++warning_count))
    fi
    log WARN "$@"
}

error() {
    if [[ "$DOCTOR_MODE" == true ]]; then
    ((++error_count))
    fi
    log FAIL "$@"
}


check_environment() {

    info "Kontrollerar miljön..."

    local directories=(
        "$SCRIPT_DIR/packages"
        "$SCRIPT_DIR/lib"
        "$SCRIPT_DIR/config"
    )

    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            success "Hittade $(basename "$dir")/"
        else
            error "Saknar $(basename "$dir")/"
            exit "$EXIT_ENVIRONMENT"
        fi
    done

    echo
}


print_summary() {

    local modules
    local packages

    modules=$(count_modules "$PACKAGE_DIR")
    packages=$(count_all_packages "$PACKAGE_DIR")

    echo
    printf "%-20s %s\n" "Projektkatalog:" "$SCRIPT_DIR"
    printf "%-20s %d\n" "Moduler:" "$modules"
    printf "%-20s %d\n" "Paket:" "$packages"

}

print_help() {

cat <<EOF
Henric Workstation Bootstrap v$APP_VERSION

Användning:
    bootstrap.sh [alternativ]

Alternativ:

    --help         Visa denna hjälp

    --list         Visa alla moduler

    --summary      Visa sammanfattning

    --install      Installera alla moduler

    --doctor       Kontrollera systemet

    --update       Uppdatera systemet

EOF

}

section() {

    local title="$1"

    echo
    printf '%*s\n' 40 '' | tr ' ' '='
    echo "$title"
    printf '%*s\n' 40 '' | tr ' ' '='
}


check_commands() {

    local command

    for command in "$@"; do

        if command -v "$command" >/dev/null 2>&1; then
            success "$command"
        else
            error "$command"
            return 1
        fi

    done
}
