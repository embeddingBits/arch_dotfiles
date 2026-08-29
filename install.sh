#!/usr/bin/env bash
# install.sh - Reproducible Arch Linux bootstrap
#
# Stages:
#   1. System sync & update
#   2. Multilib repository (replaces Void non-free repos)
#   3. Package groups (from packages.lst)
#   4. systemd services (replaces runit)
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
# System services (systemd system units)
SERVICES=("NetworkManager" "bluetooth" "tailscaled")
# User services (systemd --user units)
USER_SERVICES=("pipewire" "pipewire-pulse" "wireplumber")
REMOVE_SERVICES=("dhcpcd")
USER_NAME="${SUDO_USER:-$(whoami)}"
# Packages that are AUR-only (need yay/paru)
AUR_PACKAGES=("nwg-look" "xwayland-satellite")

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

# ── Helpers ───────────────────────────────────────────────────────────────────
detect_aur_helper() {
    if command -v yay &>/dev/null; then
        echo "yay"
    elif command -v paru &>/dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

is_aur_package() {
    local pkg="$1"
    for aur in "${AUR_PACKAGES[@]}"; do
        [[ "$pkg" == "$aur" ]] && return 0
    done
    return 1
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
    pacman -Syu --noconfirm || warn "Sync/update completed with warnings"
    ok "System is up to date"
}

# ── Stage 2: Multilib repo ────────────────────────────────────────────────────
stage_repos() {
    info "Stage 2: Ensuring multilib repository"
    local pacman_conf="/etc/pacman.conf"

    if grep -q "^\[multilib\]" "$pacman_conf"; then
        ok "  [multilib] already enabled"
    elif grep -q "^\s*#\s*\[multilib\]" "$pacman_conf"; then
        info "  Enabling [multilib] in $pacman_conf"
        # Uncomment [multilib] and its Include line
        sed -i '/^#\[multilib\]/ s/^#//' "$pacman_conf"
        sed -i '/^\[multilib\]/ { n; s/^#//; }' "$pacman_conf"
        ok "  [multilib] enabled"
        info "  Refreshing package databases"
        pacman -Sy --noconfirm || warn "  pacman -Sy failed"
    else
        warn "  [multilib] section not found in $pacman_conf"
        info "  Appending [multilib] section"
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$pacman_conf"
        pacman -Sy --noconfirm || warn "  pacman -Sy failed"
        ok "  [multilib] appended and enabled"
    fi
}

# ── Stage 3: Package groups ───────────────────────────────────────────────────
stage_packages() {
    local groups=("$@")
    if [[ ${#groups[@]} -eq 0 ]]; then
        groups=("core" "network" "audio" "desktop" "tools" "app" "dev")
    fi

    local aur_helper
    aur_helper=$(detect_aur_helper)

    if [[ -n "$aur_helper" ]]; then
        info "  Using AUR helper: $aur_helper"
    else
        warn "  No AUR helper (yay/paru) found - AUR packages will be skipped"
        warn "  Install yay or paru to get: ${AUR_PACKAGES[*]}"
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

        # Separate repo vs AUR packages if helper available
        if [[ -n "$aur_helper" ]]; then
            # Try installing all with helper; handles both repo and AUR
            if ! $aur_helper -S --needed --noconfirm $pkgs; then
                warn "  Some packages in '$grp' failed to install (helper: $aur_helper)"
            fi
        else
            # Filter out AUR packages for plain pacman
            local repo_pkgs=""
            local aur_skipped=""
            for pkg in $pkgs; do
                if is_aur_package "$pkg"; then
                    aur_skipped+="$pkg "
                else
                    repo_pkgs+="$pkg "
                fi
            done
            if [[ -n "$aur_skipped" ]]; then
                warn "  Skipping AUR packages (no helper): $aur_skipped"
            fi
            if [[ -n "$repo_pkgs" ]]; then
                pacman -S --needed --noconfirm $repo_pkgs || warn "  Some packages in '$grp' failed to install"
            fi
        fi
        ok "  Group '$grp' done"
    done
}

# ── Stage 4: systemd services ─────────────────────────────────────────────────
stage_services() {
    info "Stage 4: Configuring systemd services"

    # Disable unwanted services
    for svc in "${REMOVE_SERVICES[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            systemctl disable "$svc" 2>/dev/null || warn "  Could not disable $svc"
            warn "  Disabled $svc service"
        fi
        if systemctl is-active "$svc" &>/dev/null; then
            systemctl stop "$svc" 2>/dev/null || true
        fi
    done

    # Enable required system services
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^${svc}.service"; then
            if systemctl is-enabled "$svc" &>/dev/null; then
                ok "  $svc already enabled"
            else
                systemctl enable "$svc" 2>/dev/null && ok "  $svc enabled" || warn "  Could not enable $svc"
            fi
            # Try to start if not active (non-fatal outside live system)
            systemctl start "$svc" 2>/dev/null || warn "  Could not start $svc (may require reboot)"
        else
            warn "  Service $svc not found, skipping (install its package first)"
        fi
    done

    # Enable user services (pipewire etc.) for the target user
    for svc in "${USER_SERVICES[@]}"; do
        # Check if unit exists system-wide
        if systemctl --user list-unit-files 2>/dev/null | grep -q "^${svc}.service"; then
            : # found via --user
        elif systemctl list-unit-files 2>/dev/null | grep -q "^${svc}.service"; then
            : # generic check
        else
            # Unit may be user-only; attempt anyway and warn on failure
            warn "  User service $svc unit not found yet, will try to enable anyway"
        fi

        if sudo -u "$USER_NAME" systemctl --user is-enabled "$svc" &>/dev/null; then
            ok "  $svc (user) already enabled for $USER_NAME"
        else
            if sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$(id -u "$USER_NAME")" systemctl --user enable "$svc" 2>/dev/null; then
                ok "  $svc (user) enabled for $USER_NAME"
            else
                warn "  Could not enable user service $svc for $USER_NAME (try after login: systemctl --user enable $svc)"
            fi
        fi
    done
}

# ── Stage 5: User groups ──────────────────────────────────────────────────────
stage_groups() {
    info "Stage 5: Adding user to required groups"
    # Arch-appropriate groups for Wayland/audio/video. Adjust as needed.
    local groups=("input" "video" "audio" "storage" "wheel" "network")
    for grp in "${groups[@]}"; do
        if getent group "$grp" &>/dev/null; then
            if id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$grp"; then
                ok "  $USER_NAME already in $grp"
            else
                usermod -aG "$grp" "$USER_NAME" 2>/dev/null && ok "  User added to $grp" || warn "  Could not add $USER_NAME to $grp"
            fi
        else
            warn "  Group $grp does not exist, skipping"
        fi
    done
}

# ── Stage 6: Stow dotfiles ────────────────────────────────────────────────────
stage_dotfiles() {
    info "Stage 6: Stowing dotfiles"
    command -v stow &>/dev/null || err "GNU Stow is not installed (pacman -S stow)"

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

    info "Starting Arch Linux reproducible bootstrap"
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
