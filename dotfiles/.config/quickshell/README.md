<div align="center">

# Nebula

*A dreamy desktop shell for Hyprland, built with Quickshell*

<br/>

[![Stars](https://img.shields.io/github/stars/iamSt3el/Nebula?style=for-the-badge&logo=starship&color=8B5CF6&labelColor=1a1a2e)](https://github.com/iamSt3el/Nebula/stargazers)
[![License](https://img.shields.io/badge/license-GPL%20v3-6D28D9?style=for-the-badge&labelColor=1a1a2e)](LICENSE)
[![Quickshell](https://img.shields.io/badge/built%20with-Quickshell-a78bfa?style=for-the-badge&labelColor=1a1a2e)](https://quickshell.outfoxxed.me)

[![Watch the tour](https://img.shields.io/badge/▶%20Watch%20the%20tour-YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white&labelColor=1a1a2e)](https://youtu.be/bYuwrP-WTCs)

<br/>

<img src="assets/showcase/dashboard.png" alt="Nebula dashboard" width="100%"/>

<sub><b>Dashboard</b> — sliders, quick toggles, power profiles, grouped notification shade</sub>

<br/><br/>

<img src="assets/showcase/widgets.png" alt="Nebula widget screen" width="100%"/>

<sub><b>Widget screen</b> — everything themed from the wallpaper</sub>

</div>

---

## Features

**Shell** — bar (pill or full-width, plus a slim secondary bar for other monitors),
dashboard, Android-style grouped notification shade, workspace overview, dock with
hover previews, brightness/volume OSD, lock screen, session menu, and an optional
[greetd](https://sr.ht/~kennylevinsen/greetd/) login greeter (`greeter.qml`).

**Launcher** — one window, five modes by prefix:

| Prefix | Mode | Example |
|--------|------|---------|
| *(none)* | Apps — fuzzy search, pinning, categories | `firefox` |
| `=` | Calculator + units (libqalculate) | `100 usd to inr` |
| `>` | Shell command | `>systemctl suspend` |
| `:` | Emoji picker | `:fire` |
| `w` | Window switcher | `w term` |

**Widgets** — a full-screen canvas you arrange yourself: analog and digital clocks,
date cards, weather, system and network monitors, battery, temperature, media
players, CAVA spectrum, sticky notes, tasks, pomodoro, RSS, moon phase, sun arc.

**Tools**

- **Material You theming** — colours extracted from the wallpaper by
  `scripts/gen_colors.py` (Python `materialyoucolor`, cached); other apps can pick
  up the same palette, see [theming other apps](#theming-other-apps)
- **AI assistant** — chat panel that drives a real [claude.ai](https://claude.ai)
  session through a bundled browser extension, with optional voice dictation ([setup](#ai-setup))
- **Nebula Drop** — phone ↔ PC file transfer over Wi-Fi: the shell serves a
  token-scoped page and shows a QR code, no app on the phone
- **Clipboard manager** (cliphist, with image previews) · **Screenshots**
  (grimblast + swappy) · **Screen recording** (native wf-recorder plugin, live pill)
- **Wallpaper selector** — local folders or [Wallhaven](https://wallhaven.cc) search, animated transitions via awww
- **Storage** — a treemap of your disk, scanned live
- **Calendar holidays** — auto-detected from your timezone, no account needed
- **Game mode**, cheat sheet, music visualizer
- **Settings panel** — Theme, Appearance, Sound, Media, Networking, Bluetooth,
  Notifications, Weather, Widgets, Sleep, Storage, AI, About

---

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/iamSt3el/Nebula/master/install.sh)
```

Arch only (uses `pacman`). The script installs `yay` if needed, pulls every pacman
and AUR package, clones Nebula to `~/.config/quickshell`, creates the Python venv at
`~/.local/state/quickshell/.venv`, fetches the Rubik font, builds the emoji index and
the WfRecorder plugin, enables the pipewire / NetworkManager / bluetooth / upower
services, and exports `NEBULA_VENV` + `QML_IMPORT_PATH` in your shell profile.

Flags: `-f` skips confirmations, `-s` skips `pacman -Syu`.

> [!IMPORTANT]
> **The installer never touches your Hyprland config.** Autostart and keybinds are
> yours to wire up.

### Hyprland setup

Nebula is only the shell. It does not ship, generate, or edit your Hyprland config —
add the autostart and environment lines yourself:

```ini
exec-once = awww-daemon
exec-once = wl-paste --watch cliphist store
exec-once = QSG_RENDER_LOOP=threaded quickshell

env = QML_IMPORT_PATH,$HOME/.local/lib/qt6/qml
env = NEBULA_VENV,$HOME/.local/state/quickshell/.venv
```

On Hyprland >= 0.55 with a Lua config, the same thing:

```lua
hl.exec_cmd("awww-daemon")
hl.exec_cmd("wl-paste --watch cliphist store")
hl.exec_cmd("QSG_RENDER_LOOP=threaded quickshell")

hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")
hl.env("NEBULA_VENV",     os.getenv("HOME") .. "/.local/state/quickshell/.venv")
```

### Keybindings

Nebula registers these global shortcuts. Bind whatever keys you like to them —
`quickshell:<name>` — from your own config:

| Shortcut | Opens |
|----------|-------|
| `appLauncher` | App launcher |
| `overview` | Workspace overview |
| `clipboard` | Clipboard history |
| `wallpaperLauncher` | Wallpaper selector |
| `toolsWidget` | Tools / widget screen |
| `filedrop` | Nebula Drop |
| `ai` · `aiHistory` | AI panel, chat history |
| `settingOpen` | Settings |
| `cheatsheet` | Keybinding cheat sheet |
| `welcome` | First-run setup screen |
| `lock` · `shutdown` | Lock screen, session menu |
| `brightnessIncrease` · `brightnessDecrease` | Brightness OSD |

```lua
hl.bind("SUPER + CTRL + RETURN", hl.dsp.global("quickshell:appLauncher"))
hl.bind("SUPER + L",             hl.dsp.global("quickshell:lock"), { locked = true })
```

`{ locked = true }` lets a bind fire on the lock screen. `hyprland.conf` syntax is
`bind = SUPER, V, global, quickshell:clipboard`; a full set is listed in
[`config/hypr/nebula.conf`](config/hypr/nebula.conf). The dashboard, notification
shade, and weather panel open from the bar, not by shortcut.

---

## Dependencies

Handled by the installer; the full lists live at the top of
[`install.sh`](install.sh). In short: `quickshell-git`, `hyprland`, Qt 6
(base / declarative / wayland / svg / multimedia), pipewire + wireplumber,
networkmanager, bluez, upower, `awww-git`, `grimblast-git`, `swappy`,
`wf-recorder`, `wl-clipboard`, `cliphist`, `cava`, `brightnessctl`, `libqalculate`,
`matugen-bin`, `ttf-material-symbols-variable-git`, and a toolchain
(`gcc` `cmake` `extra-cmake-modules`) for the recorder plugin. `ddcutil`
(external-monitor brightness) and `hyprlock` / `hypridle` are optional. Nebula Drop
also needs `qrencode`, which the installer does not yet pull in — `pacman -S qrencode`.

Python lives outside the repo, found via `NEBULA_VENV`:

```bash
uv venv --prompt nebula ~/.local/state/quickshell/.venv -p 3.12
uv pip install materialyoucolor requests Pillow \
  --python ~/.local/state/quickshell/.venv/bin/python
```

Add `faster-whisper` only if you want voice dictation.

From a clone, by hand: `bash plugins/WfRecorder/build.sh`, export those two
variables, then `QSG_RENDER_LOOP=threaded quickshell`.

---

## AI setup

The AI panel calls no API — it drives a real [claude.ai](https://claude.ai) session
in your browser, so it uses your existing subscription and needs no key. Build the
bridge extension and load it via *Install Add-on From File*:

```bash
bash ~/.config/quickshell/extension/build.sh
```

> [!IMPORTANT]
> [Zen](https://zen-browser.app) is required — the extension is unsigned, which Zen
> allows with `xpinstall.signatures.required=false`, but stock Firefox does not.

---

## Theming other apps

The shell always writes its own palette to `~/.cache/quickshell/colors.json`. It can
also render that palette into other apps' config files — but **Nebula ships none of
those configs and will not create them.** Each target is opt-in and silently skipped
unless *both* sides already exist:

1. a matugen-style template at `~/.config/matugen/templates/<name>`, and
2. the output file's parent directory

The templates `scripts/gen_colors.py` looks for, and where each lands:

| Template | Written to |
|----------|------------|
| `btop.theme` | `~/.config/btop/themes/matugen.theme` |
| `kitty-colors.conf` | `~/.config/kitty/colors.conf` |
| `gtk-colors.css` · `gtk4-colors.css` | `~/.config/gtk-3.0/gtk.css` · `gtk-4.0/gtk.css` |
| `qt-colors.conf` | `~/.config/qt5ct` · `qt6ct/colors/matugen.conf` |
| `colors.css` | `~/.config/waybar/colors.css` · `nwg-dock-hyprland/colors.css` |
| `hyprland-colors.conf` | `~/.config/hypr/colors.conf` (then `hyprctl reload`) |
| `tmux-colors.conf` · `starship.toml` · `pywalfox-colors.json` | `~/.config/tmux/colors.conf` · `~/.config/starship.toml` · `~/.cache/wal/colors.json` |

Only the Hyprland one ships, in [`config/matugen/templates/`](config/matugen/templates/)
(next to the shell's own two); write the rest yourself in matugen syntax, and include
the generated file from the app's own config (`include colors.conf` in `kitty.conf`, `@import "colors.css"` in
waybar, `source = colors.conf` in `hyprland.conf`, and so on). Anything else — nvim,
your own tools — can just read `colors.json` directly.

---

## Configuration

Everything lives in the built-in **Settings panel**, stored at
`~/.cache/quickshell/settings.json`. Wallhaven search needs an API key, set there.

---

## Credits

[end_4](https://github.com/end-4) — inspiration, Quickshell patterns, and
[rounded-polygon-qmljs](https://github.com/end-4/rounded-polygon-qmljs) ·
[soramane](https://github.com/soramanew) — design inspiration ·
[outfoxxed](https://outfoxxed.me/) — creator of [Quickshell](https://quickshell.outfoxxed.me)

## License

[GNU GPL v3.0](LICENSE) · Copyright © 2026 iamSt3el

`modules/MatrialShapes/` is rounded-polygon-qmljs by end_4, included under its
original [Apache License 2.0](modules/MatrialShapes/LICENSE).

---

<div align="center">
  <sub>made with ♥ and too many late nights</sub>
</div>
