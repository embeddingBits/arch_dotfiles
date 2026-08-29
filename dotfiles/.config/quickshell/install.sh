#!/usr/bin/env bash
# Nebula Shell — standalone installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/iamSt3el/Nebula/main/install.sh)
#        bash install.sh [--force] [--skip-sysupdate]
#
# Installs the Nebula shell only. It never edits your Hyprland config —
# autostart and keybind snippets live in config/hypr/ for you to copy.

cd "$(dirname "$0")" 2>/dev/null || true   # no-op when piped via curl
export base="$(pwd)"

# ── colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

RULE='──────────────────────────────────────────────────────────────'

STEP_N=0
TOTAL_STEPS=18
WARNINGS=()
START_TS=$SECONDS

ok()     { echo -e "   ${GREEN}✓${RESET} $*"; }
warn()   { echo -e "   ${YELLOW}▲${RESET} $*"; WARNINGS+=("$*"); }
info()   { echo -e "   ${DIM}· $*${RESET}"; }
step()   {
  STEP_N=$((STEP_N + 1))
  printf "\n${BOLD}${MAGENTA}%02d${RESET}${DIM}/%02d${RESET}  ${BOLD}%s${RESET}\n" \
    "$STEP_N" "$TOTAL_STEPS" "$*"
  echo -e "${DIM}${RULE}${RESET}"
}
banner() { echo -e "${BOLD}${CYAN}$*${RESET}"; }
die()    { echo -e "\n  ${RED}${BOLD}✗ FATAL${RESET}  ${RED}$*${RESET}\n" >&2; exit 1; }
has()    { command -v "$1" &>/dev/null; }

# ── XDG dirs ───────────────────────────────────────────────────────────────────
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ── constants ─────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/iamSt3el/Nebula.git"
INSTALL_DIR="$XDG_CONFIG_HOME/quickshell"
VENV_DIR="$XDG_STATE_HOME/quickshell/.venv"
PLUGIN_DIR="$INSTALL_DIR/plugins/WfRecorder"

# ── option defaults ───────────────────────────────────────────────────────────
ask=true
SKIP_SYSUPDATE=false

# ── parse flags ───────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    -f|--force)           ask=false ;;
    -s|--skip-sysupdate)  SKIP_SYSUPDATE=true ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "  -f, --force            Skip all confirmations"
      echo "  -s, --skip-sysupdate   Skip pacman -Syu"
      echo "  -h, --help             Show this help"
      exit 0 ;;
  esac
done

$SKIP_SYSUPDATE && TOTAL_STEPS=$((TOTAL_STEPS - 1))

# ── interactive wrapper (mirrors dots-hyprland's v()) ─────────────────────────
# Shows the command, optionally waits for confirmation, and handles failures.
v() {
  local execute=true
  if $ask; then
    echo -e "   ${DIM}${RULE}${RESET}"
    echo -e "   ${BOLD}run${RESET}  ${GREEN}$*${RESET}"
    while true; do
      echo -e "   ${DIM}[y] run    [s] skip    [e] exit    [!] run all without asking${RESET}"
      read -rp "   ❯ " p
      case $p in
        y|Y|"")  break ;;
        s|S)     execute=false; break ;;
        e|E)     die "Aborted by user." ;;
        "!")     ask=false; break ;;
        *)       echo -e "   ${DIM}enter y / s / e / !${RESET}" ;;
      esac
    done
  else
    echo -e "   ${DIM}❯ $*${RESET}"
  fi
  if $execute; then
    x "$@"
  else
    warn "Skipped: $*"
  fi
}

# ── error-handling executor (mirrors dots-hyprland's x()) ─────────────────────
x() {
  local status=0
  "$@" || status=$?
  while [[ $status -ne 0 ]]; do
    echo -e "   ${RED}✗ failed${RESET}  ${YELLOW}$*${RESET}"
    echo -e "   ${DIM}[r] retry    [i] ignore    [e] exit${RESET}"
    read -rp "   ❯ " p
    case $p in
      r|R|"") "$@" && status=0 || status=$? ;;
      i|I)    warn "Ignoring failure: $*"; return 0 ;;
      e|E)    die "Aborted." ;;
    esac
  done
}

# ── guard: no sudo / root ─────────────────────────────────────────────────────
[[ "$(whoami)" == "root" ]] && die "Run as your normal user, NOT as root or with sudo."

# ── banner ────────────────────────────────────────────────────────────────────
clear
banner "
  ███╗   ██╗███████╗██████╗ ██╗   ██╗██╗      █████╗
  ████╗  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔══██╗
  ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║     ███████║
  ██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║██║     ██╔══██║
  ██║ ╚████║███████╗██████╔╝╚██████╔╝███████╗██║  ██║
  ╚═╝  ╚═══╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝
"
echo -e "  ${DIM}a dreamy desktop shell for Hyprland, built with Quickshell${RESET}"
echo ""
echo -e "  ${DIM}repo${RESET}    ${CYAN}${REPO_URL}${RESET}"
echo -e "  ${DIM}target${RESET}  ${CYAN}${INSTALL_DIR}${RESET}"
echo -e "  ${DIM}venv${RESET}    ${CYAN}${VENV_DIR}${RESET}"
echo ""
echo -e "  ${DIM}This installs the shell only — it will not touch your Hyprland config.${RESET}"
echo -e "  ${DIM}Autostart and keybind snippets are in config/hypr/ for you to copy.${RESET}"
echo ""

# ── sanity: must be Arch ──────────────────────────────────────────────────────
has pacman || die "pacman not found — this installer is for Arch Linux only."

# ── offer backup ──────────────────────────────────────────────────────────────
step "Backup (optional)"
echo -e "  Would you like to back up ${CYAN}~/.config${RESET} and ${CYAN}~/.local${RESET} before we start? [y/N]"
read -rp "   ❯ " bk
case $bk in
  y|Y)
    BACKUP_DIR="$HOME/nebula-backup-$(date +%Y%m%d-%H%M%S)"
    info "Backing up to $BACKUP_DIR ..."
    rsync -a --info=progress2 "$XDG_CONFIG_HOME/" "$BACKUP_DIR/config/"
    rsync -a --info=progress2 "$HOME/.local/"     "$BACKUP_DIR/local/"
    ok "Backup complete"
    ;;
  *) info "Skipping backup" ;;
esac

# ── base tools ────────────────────────────────────────────────────────────────
step "Base tools"
has git || v sudo pacman -S --needed --noconfirm git
has rsync || v sudo pacman -S --needed --noconfirm rsync
ok "git, rsync"

if ! has hyprland; then
  warn "Hyprland not found. You should have a running Hyprland session before launching Nebula."
fi

# ── system update ─────────────────────────────────────────────────────────────
if ! $SKIP_SYSUPDATE; then
  step "System update"
  v sudo pacman -Syu
fi

# ── AUR helper ────────────────────────────────────────────────────────────────
step "AUR helper"
AUR_HELPER=""
for h in yay paru; do has "$h" && { AUR_HELPER="$h"; break; }; done

if [[ -z "$AUR_HELPER" ]]; then
  warn "No AUR helper found — installing yay-bin..."
  v sudo pacman -S --needed --noconfirm base-devel
  tmpdir=$(mktemp -d)
  v git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && x makepkg -si --noconfirm)
  rm -rf "$tmpdir"
  AUR_HELPER="yay"
fi
ok "AUR helper: $AUR_HELPER"

# ── clone / update repo ───────────────────────────────────────────────────────
step "Nebula source"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  warn "$INSTALL_DIR already exists."
  echo -e "  Update to latest? [y/N]"
  read -rp "   ❯ " upd
  if [[ "${upd,,}" == "y" ]]; then
    v git -C "$INSTALL_DIR" pull --ff-only
  else
    ok "Keeping existing install"
  fi
else
  if [[ -d "$INSTALL_DIR" ]]; then
    warn "$INSTALL_DIR exists but is not a git repo."
    echo -e "  Back it up and replace? [y/N]"
    read -rp "   ❯ " rep
    [[ "${rep,,}" == "y" ]] || die "Move or delete $INSTALL_DIR and re-run."
    mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
    ok "Backed up"
  fi
  v git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── pacman packages ───────────────────────────────────────────────────────────
step "Pacman packages"
PACMAN_PKGS=(
  hyprland pipewire wireplumber networkmanager
  bluez bluez-utils upower
  python grim wf-recorder swappy wl-clipboard
  cava brightnessctl curl unzip
  qt6-base qt6-declarative qt6-wayland qt6-svg qt6-multimedia
  libpipewire libqalculate
  gcc cmake extra-cmake-modules
)
v sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# ── uv (fast Python package manager) ─────────────────────────────────────────
step "uv (Python toolchain)"
if ! has uv; then
  info "Installing uv (direct binary download — avoids installer script hang)..."
  _UV_ARCH="$(uname -m)-unknown-linux-gnu"
  _UV_TMP="/tmp/uv-${_UV_ARCH}.tar.gz"
  mkdir -p "$HOME/.local/bin"
  curl -LsSf \
    "https://github.com/astral-sh/uv/releases/latest/download/uv-${_UV_ARCH}.tar.gz" \
    -o "$_UV_TMP"
  tar -xzf "$_UV_TMP" -C /tmp/
  install -m755 "/tmp/uv-${_UV_ARCH}/uv"  "$HOME/.local/bin/uv"
  install -m755 "/tmp/uv-${_UV_ARCH}/uvx" "$HOME/.local/bin/uvx"
  rm -rf "$_UV_TMP" "/tmp/uv-${_UV_ARCH}"
  export PATH="$HOME/.local/bin:$PATH"
fi
ok "uv: $(uv --version 2>/dev/null || echo 'installed')"

# ── AUR packages ──────────────────────────────────────────────────────────────
step "AUR packages"
AUR_PKGS=(
  quickshell-git grimblast-git cliphist
  matugen-bin
  ttf-material-symbols-variable-git
)
AUR_PKGS_OPT=(hyprlock hypridle)

if $ask; then
  for pkg in "${AUR_PKGS[@]}"; do v "$AUR_HELPER" -S --needed "$pkg"; done
else
  v "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

info "Installing optional packages (hyprlock, hypridle)..."
if $ask; then
  for pkg in "${AUR_PKGS_OPT[@]}"; do v "$AUR_HELPER" -S --needed "$pkg" || true; done
else
  "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS_OPT[@]}" || warn "Some optional AUR packages failed (hyprlock, hypridle)"
fi

# awww-git is a Rust crate — limit parallel jobs to avoid OOM in low-RAM systems
step "awww-git (Rust — limited parallelism)"
info "Building awww-git with CARGO_BUILD_JOBS=2 to avoid OOM..."
if $ask; then
  v env CARGO_BUILD_JOBS=2 "$AUR_HELPER" -S --needed awww-git
else
  env CARGO_BUILD_JOBS=2 "$AUR_HELPER" -S --needed --noconfirm awww-git \
    || warn "awww-git failed — retry manually: CARGO_BUILD_JOBS=1 $AUR_HELPER -S awww-git"
fi

# ttf-rubik AUR package is broken (bad PKGBUILD glob); download font directly instead
step "Rubik font (direct download)"
FONTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
mkdir -p "$FONTS_DIR"
if fc-list | grep -qi "Rubik"; then
  ok "Rubik font already installed"
else
  info "Downloading Rubik variable font from Google Fonts..."
  curl -L --fail \
    "https://github.com/googlefonts/rubik/releases/latest/download/Rubik.zip" \
    -o /tmp/nebula-rubik.zip \
    && unzip -o /tmp/nebula-rubik.zip "fonts/variable/*.ttf" -d /tmp/nebula-rubik/ \
    && cp /tmp/nebula-rubik/fonts/variable/*.ttf "$FONTS_DIR/" \
    && fc-cache -f "$FONTS_DIR" \
    && ok "Rubik font installed to $FONTS_DIR" \
    || warn "Rubik font download failed — install ttf-rubik manually later"
  rm -rf /tmp/nebula-rubik.zip /tmp/nebula-rubik/
fi

# ── Python venv via uv ────────────────────────────────────────────────────────
step "Python environment"
mkdir -p "$(dirname "$VENV_DIR")"
v uv venv --prompt nebula "$VENV_DIR" -p 3.12
if [[ -f "$INSTALL_DIR/scripts/requirements.txt" ]]; then
  v uv pip install -r "$INSTALL_DIR/scripts/requirements.txt" --python "$VENV_DIR/bin/python"
else
  v uv pip install materialyoucolor requests Pillow --python "$VENV_DIR/bin/python"
fi
ok "Python venv ready at $VENV_DIR"

# ── Emoji data for the launcher's `:` mode ────────────────────────────────────
step "Emoji data"
if [[ -f "$INSTALL_DIR/scripts/gen_emoji.py" ]]; then
  v python3 "$INSTALL_DIR/scripts/gen_emoji.py" \
    && ok "Emoji index written to assets/emoji.json" \
    || warn "Emoji index failed — launcher ':' mode will be empty until you run scripts/gen_emoji.py"
else
  warn "No scripts/gen_emoji.py — skipping (launcher ':' mode will be empty)"
fi

# ── WfRecorder plugin ─────────────────────────────────────────────────────────
step "WfRecorder plugin"
if [[ -f "$PLUGIN_DIR/build.sh" ]]; then
  v sudo pacman -S --needed --noconfirm cmake extra-cmake-modules
  v bash "$PLUGIN_DIR/build.sh"
  ok "Plugin built"
else
  warn "No build.sh at $PLUGIN_DIR — skipping (screen recording may not work)"
fi

# ── wallpaper directory ───────────────────────────────────────────────────────
step "Wallpaper directory"
WALLPAPER_DIR="$HOME/wallpaper"
[[ -d "$WALLPAPER_DIR" ]] || { mkdir -p "$WALLPAPER_DIR"; ok "Created $WALLPAPER_DIR"; }
ok "Wallpapers → $WALLPAPER_DIR"

# ── services ──────────────────────────────────────────────────────────────────
step "Systemd services"
for svc in pipewire wireplumber; do
  systemctl --user enable --now "$svc" 2>/dev/null && ok "$svc (user)" || warn "Could not enable $svc"
done
for svc in NetworkManager bluetooth upower; do
  sudo systemctl enable --now "$svc" 2>/dev/null && ok "$svc (system)" || warn "Could not enable $svc"
done

# ── user groups ───────────────────────────────────────────────────────────────
step "User groups"
v sudo usermod -aG video,input "$(whoami)"

# ── NEBULA_VENV env var + QML_IMPORT_PATH ─────────────────────────────────────
step "Shell environment"

ENV_BLOCK="
# Nebula shell
export NEBULA_VENV=\"$VENV_DIR\"
export QML_IMPORT_PATH=\"\$HOME/.local/lib/qt6/qml:\${QML_IMPORT_PATH:-}\"
"

patch_profile() {
  local file="$1"
  [[ -f "$file" ]] || return
  if grep -q "NEBULA_VENV" "$file"; then
    ok "Already patched: $file"
  else
    echo "$ENV_BLOCK" >> "$file"
    ok "Patched: $file"
  fi
}

patch_profile "$HOME/.bashrc"
patch_profile "$HOME/.zshrc"
patch_profile "$HOME/.profile"

FISH_CONF="$XDG_CONFIG_HOME/fish/config.fish"
if [[ -f "$FISH_CONF" ]] && ! grep -q "NEBULA_VENV" "$FISH_CONF"; then
  {
    echo ""
    echo "# Nebula shell"
    echo "set -gx NEBULA_VENV \"$VENV_DIR\""
    echo "set -gx QML_IMPORT_PATH \"\$HOME/.local/lib/qt6/qml\" \$QML_IMPORT_PATH"
  } >> "$FISH_CONF"
  ok "Patched: $FISH_CONF"
fi

# ── matugen templates ─────────────────────────────────────────────────────────
step "matugen templates"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
MATUGEN_TPL_SRC="$INSTALL_DIR/config/matugen/templates"
MATUGEN_TPL_DST="$MATUGEN_DIR/templates"

mkdir -p "$MATUGEN_TPL_DST"
# rsync --update: never overwrites a destination file that is newer
rsync -av --update "$MATUGEN_TPL_SRC/quickshell-colors.json"       "$MATUGEN_TPL_DST/"
rsync -av --update "$MATUGEN_TPL_SRC/quickshell-music-colors.json" "$MATUGEN_TPL_DST/"
rsync -av --update "$MATUGEN_TPL_SRC/hyprland-colors.conf"         "$MATUGEN_TPL_DST/"
ok "Templates copied to $MATUGEN_TPL_DST"

# Patch ~/.config/matugen/config.toml — add the [templates.quickshell*] blocks
# if they aren't already present, leaving all other user entries untouched.
MATUGEN_CONF="$MATUGEN_DIR/config.toml"
if [[ ! -f "$MATUGEN_CONF" ]]; then
  cat > "$MATUGEN_CONF" <<'TOML'
[config]
version_check = false
TOML
  ok "Created $MATUGEN_CONF"
fi

patch_toml() {
  local key="$1" block="$2"
  if grep -q "\[templates\.${key}\]" "$MATUGEN_CONF"; then
    ok "matugen config: [templates.$key] already present"
  else
    echo "" >> "$MATUGEN_CONF"
    echo "$block" >> "$MATUGEN_CONF"
    ok "matugen config: added [templates.$key]"
  fi
}

patch_toml "quickshell" \
"[templates.quickshell]
input_path  = '~/.config/matugen/templates/quickshell-colors.json'
output_path = '~/.cache/quickshell/colors.json'"

patch_toml "quickshell_music" \
"[templates.quickshell_music]
input_path  = '~/.config/matugen/templates/quickshell-music-colors.json'
output_path = '~/.cache/quickshell/music_colors.json'"

patch_toml "hyprland" \
"[templates.hyprland]
input_path  = '~/.config/matugen/templates/hyprland-colors.conf'
output_path = '~/.config/hypr/colors.conf'
post_hook   = 'hyprctl reload'"

# ── done ──────────────────────────────────────────────────────────────────────
ELAPSED=$((SECONDS - START_TS))

echo ""
echo -e "${GREEN}${BOLD}  ✓  Nebula installed${RESET}  ${DIM}in $((ELAPSED / 60))m $((ELAPSED % 60))s${RESET}"
echo -e "${DIM}  ${RULE}${RESET}"
echo ""
echo -e "  ${BOLD}launch${RESET}      ${CYAN}QSG_RENDER_LOOP=threaded quickshell${RESET}"
echo -e "  ${BOLD}wallpapers${RESET}  ${CYAN}~/wallpaper/${RESET}"
echo -e "  ${BOLD}colors${RESET}      ${CYAN}matugen image <path-to-wallpaper>${RESET}"
echo ""
echo -e "  ${DIM}Reload your shell (or log out and back in) to pick up NEBULA_VENV${RESET}"
echo -e "  ${DIM}and QML_IMPORT_PATH.${RESET}"
echo ""
echo -e "${DIM}  ${RULE}${RESET}"
echo -e "  ${BOLD}Hyprland setup is up to you.${RESET} ${DIM}Nothing here touched your config.${RESET}"
echo ""
echo -e "  ${DIM}autostart + keybinds${RESET}  ${CYAN}$INSTALL_DIR/config/hypr/${RESET}"
echo -e "  ${DIM}classic .conf users${RESET}   ${CYAN}config/hypr/nebula.conf${RESET}"
echo ""
echo -e "  ${DIM}At minimum, add to your Hyprland config:${RESET}"
echo -e "    ${CYAN}exec-once = awww-daemon${RESET}"
echo -e "    ${CYAN}exec-once = wl-paste --watch cliphist store${RESET}"
echo -e "    ${CYAN}exec-once = QSG_RENDER_LOOP=threaded quickshell${RESET}"
echo ""

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo -e "${DIM}  ${RULE}${RESET}"
  echo -e "  ${YELLOW}${BOLD}${#WARNINGS[@]} warning(s) during install${RESET}"
  echo ""
  for w in "${WARNINGS[@]}"; do
    echo -e "   ${YELLOW}▲${RESET} ${DIM}${w}${RESET}"
  done
  echo ""
fi
