repository_is_ready() {
    local repository="$1"

    case "$repository" in
        tailscale)
            tailscale_repository_exists
            ;;
        *)
            error "Okänt repository: $repository"
            return 1
            ;;
    esac
}

add_tailscale_repository() {
    local keyring="/usr/share/keyrings/tailscale-archive-keyring.gpg"
    local list="/etc/apt/sources.list.d/tailscale.list"

    sudo mkdir -p --mode=0755 /usr/share/keyrings

    curl -fsSL \
        https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg |
        sudo tee "$keyring" >/dev/null

    curl -fsSL \
        https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list |
        sudo tee "$list" >/dev/null
}

TAILSCALE_REPOSITORY_FILE="${TAILSCALE_REPOSITORY_FILE:-/etc/apt/sources.list.d/tailscale.list}"

tailscale_repository_exists() {

    [[ -f "$TAILSCALE_REPOSITORY_FILE" ]]
}

ensure_tailscale_repository() {
    if tailscale_repository_exists
    then
        return 0
    fi

    add_tailscale_repository
}

ensure_repository() {
    local repository="$1"

    case "$repository" in
        tailscale)
            if ! tailscale_repository_exists
            then
                add_tailscale_repository
            fi
            ;;

        *)
            error "Okänt repository: $repository"
            return 1
            ;;
    esac
}

package_repository() {
    local package="$1"

    case "$package" in
        tailscale)
            printf '%s\n' "tailscale"
            ;;
        *)
            return 1
            ;;
    esac
}