#!/usr/bin/env bash


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
    log INFO "$@"
}

success() {
    log " OK " "$@"
}

warn() {
    log WARN "$@"
}

error() {
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

check_commands() {

    local commands=(
        bash
        git
        apt
    )

    for cmd in "${commands[@]}"; do

        if command -v "$cmd" >/dev/null 2>&1; then
            success "$cmd"
        else
            error "$cmd saknas"
            exit "$EXIT_BAD_ARGUMENTS"
        fi

    done
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
Henric Workstation Bootstrap v$VERSION

Användning:
    bootstrap.sh [alternativ]

Alternativ:

    --help         Visa denna hjälp

    --list         Visa alla moduler

    --summary      Visa sammanfattning

    --install      Installera alla moduler

    --doctor       Kontrollera systemet

    --update       Uppdatera systemet (kommer)

EOF

}

section() {

    local title="$1"

    echo
    printf '%*s\n' 40 '' | tr ' ' '='
    echo "$title"
    printf '%*s\n' 40 '' | tr ' ' '='
}



