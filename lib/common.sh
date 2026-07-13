#!/usr/bin/env bash


banner() {

cat << EOF

Henric Workstation Bootstrap

Version $VERSION

EOF
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
            exit 1
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
            exit 1
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

    --install      Installera alla moduler (kommer)

    --doctor       Kontrollera systemet (kommer)

    --update       Uppdatera systemet (kommer)

EOF

}



info() {
    printf "[INFO] %s\n" "$*"
}

success() {
    printf "[ OK ] %s\n" "$*"
}

warn() {
    printf "[WARN] %s\n" "$*"
}

error() {
    printf "[FAIL] %s\n" "$*" >&2
}
success() {
    printf "[ OK ] %s\n" "$*"
}

fail() {
    printf "[FAIL] %s\n" "$*" >&2
}
