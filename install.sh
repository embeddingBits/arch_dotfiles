#!/usr/bin/env bash
# install.sh - Reproducible Void Linux bootstrap
#
# Stages:
#   1. System sync & update
#   2. Non-free repositories
#   3. Package groups (from packages.lst)
#   4. Runit services
#   5. User groups
#   6. GNU Stow dotfiles
#
# Usage:
#   ./install.sh            - full install (stages 1-6)
#   ./install.sh --groups   - list available package groups
#   ./install.sh --group dev,tools - install only specific groups
#   ./install.sh --help     - show this message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_FILE="${SCRIPT_DIR}/packages.lst"
STOW_DIRS=("dotfiles" "emacs" "nvim-config")
SERVICES=("NetworkManager" "pipewire" "pipewire-pulse" "elogind")
REMOVE_SERVICES=("dhcpcd")
USER_NAME="${SUDO_USER:-$(whoami)}"

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
    while IFS= read -r line; do
        case "$line" in
            '#!/usr/bin/env bash') continue ;;
            '# install.sh'*) printf '%s\n' "${line#'#' }" ;;
            '#') printf '\n' ;;
            '#'*) printf '%s\n' "${line#'#' }" ;;
            'set -'*) break ;;
        esac
    done < "$0"
    exit 0
}

# ── Logging ───────────────────────────────────────────────────────────────────
info()  { printf "\033[1;34m[+] %s\033[0m\n" "$*"; }
ok()    { printf "\033[1;32m[✓] %s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m[!] %s\033[0m\n" "$*" >&2; }
err()   { printf "\033[1;31m[✗] %s\033[0m\n" "$*" >&2; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
require_root() {
    [[ $EUID -eq 0 ]] && return 0
    if command -v sudo &>/dev/null; then
        exec sudo "$0" "$@"
    fi
    err "This script must be run as root (no sudo available)"
}

# ── Package file parsing ──────────────────────────────────────────────────────
parse_packages() {
    local group="${1:-}"
    [[ -f "$PACKAGE_FILE" ]] || err "packages.lst not found at $PACKAGE_FILE"

    if [[ -n "$group" ]]; then
        awk -v g="$group" '
            /^@/   { current = substr($0, 2) }
            /^@/ && current == g { found = 1; next }
            /^@/ && found         { exit }
            found && /^[^#]/ && NF { print $1 }
        ' "$PACKAGE_FILE"
    else
        awk '/^@/{g=substr($0,2); next} /^[^#]/ && NF{print $1}' "$PACKAGE_FILE"
    fi
}

list_groups() {
    info "Available package groups:"
    awk '/^@/{print "  " substr($0,2)}' "$PACKAGE_FILE"
    exit 0
}

# ── Stage 1: System update ────────────────────────────────────────────────────
stage_sync() {
    info "Stage 1: Synchronising repositories and updating system"
    xbps-install -Syu || warn "Sync/update completed with warnings"
    ok "System is up to date"
}

# ── Stage 2: Non-free repos ───────────────────────────────────────────────────
stage_repos() {
    info "Stage 2: Ensuring non-free repositories"
    local repos
    repos=$(parse_packages repos)
    for pkg in $repos; do
        if xbps-query "$pkg" &>/dev/null; then
            ok "  $pkg already installed"
        else
            xbps-install -y "$pkg"
            ok "  $pkg installed"
        fi
    done
}

# ── Stage 3: Package groups ───────────────────────────────────────────────────
stage_packages() {
    local groups=("$@")
    if [[ ${#groups[@]} -eq 0 ]]; then
        groups=("core" "network" "desktop" "tools" "app" "dev")
    fi

    info "Stage 3: Installing package groups: ${groups[*]}"
    for grp in "${groups[@]}"; do
        local pkgs
        pkgs=$(parse_packages "$grp" | tr '\n' ' ')
        if [[ -z "$pkgs" ]]; then
            warn "  Group '$grp' is empty or not found, skipping"
            continue
        fi
        info "  Installing group: $grp"
        xbps-install -y $pkgs || warn "  Some packages in '$grp' failed to install"
        ok "  Group '$grp' done"
    done
}

# ── Stage 4: Runit services ───────────────────────────────────────────────────
stage_services() {
    info "Stage 4: Configuring runit services"
    mkdir -p /etc/sv

    # Remove unwanted services
    for svc in "${REMOVE_SERVICES[@]}"; do
        local target="/var/service/$svc"
        if [[ -L "$target" ]] || [[ -d "$target" ]]; then
            rm -rf "$target"
            warn "  Removed $svc service"
        fi
    done

    # Enable required services
    for svc in "${SERVICES[@]}"; do
        local source="/etc/sv/$svc"
        local target="/var/service/$svc"
        if [[ ! -d "$source" ]]; then
            warn "  Service definition $source not found, skipping"
            continue
        fi
        if [[ -L "$target" ]]; then
            ok "  $svc already enabled"
        else
            ln -s "$source" "$target"
            ok "  $svc enabled"
        fi
    done
}

# ── Stage 5: User groups ──────────────────────────────────────────────────────
stage_groups() {
    info "Stage 5: Adding user to required groups"
    local groups=("_pipewire" "pulse" "pulse-access")
    for grp in "${groups[@]}"; do
        if getent group "$grp" &>/dev/null; then
            usermod -aG "$grp" "$USER_NAME" 2>/dev/null || warn "  Could not add $USER_NAME to $grp"
            ok "  User added to $grp"
        else
            warn "  Group $grp does not exist, skipping"
        fi
    done
}

# ── Stage 6: Stow dotfiles ────────────────────────────────────────────────────
stage_dotfiles() {
    info "Stage 6: Stowing dotfiles"
    command -v stow &>/dev/null || err "GNU Stow is not installed"

    for dir in "${STOW_DIRS[@]}"; do
        local target="${SCRIPT_DIR}/${dir}"
        if [[ ! -d "$target" ]]; then
            warn "  Stow directory $dir not found, skipping"
            continue
        fi

        pushd "$SCRIPT_DIR" >/dev/null
        if stow -R "$dir" 2>/dev/null; then
            ok "  Stowed $dir"
        else
            warn "  Conflicts may exist in $dir (try: stow -D $dir && stow $dir)"
        fi
        popd >/dev/null
    done
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local mode="full"
    local groups=()

    case "${1:-}" in
        --help|-h)    usage ;;
        --groups)     list_groups ;;
        --group)
            shift
            IFS=',' read -ra groups <<< "${1:-}"
            [[ ${#groups[@]} -eq 0 ]] && err "No groups specified (comma-separated)"
            mode="partial"
            ;;
        "")           mode="full" ;;
        *)
            err "Unknown option: $1 (use --help for usage)"
            ;;
    esac

    require_root "$@"

    info "Starting Void Linux reproducible bootstrap"
    echo "  User:        $USER_NAME"
    echo "  Mode:        $mode"
    echo "  Package file: $PACKAGE_FILE"
    echo ""

    stage_sync
    stage_repos
    stage_services
    stage_groups

    if [[ "$mode" == "full" ]]; then
        stage_packages
        stage_dotfiles
    else
        stage_packages "${groups[@]}"
    fi

    echo ""
    ok "All stages complete"
}

main "$@"
