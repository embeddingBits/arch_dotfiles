#!/usr/bin/env python3
"""
Generate Material You colors from a wallpaper image and apply to all app templates.

Caching layers:
  1. score cache  — primary HCT int per image hash (avoids re-quantizing same image)
  2. colors cache — full output JSON per image+variant+mode (instant repeat access)

Usage: gen_colors.py <image> <scheme-variant> <mode>
  scheme-variant  content | expressive | fidelity | fruitsalad | monochrome |
                  neutral | rainbow | tonalspot | vibrant
  mode            dark | light
"""

import colorsys
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from materialyoucolor.dislike.dislike_analyzer import DislikeAnalyzer
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.scheme.scheme_content import SchemeContent
from materialyoucolor.scheme.scheme_expressive import SchemeExpressive
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity
from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad
from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome
from materialyoucolor.scheme.scheme_neutral import SchemeNeutral
from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant
from materialyoucolor.utils.math_utils import sanitize_degrees_int

CACHE_DIR   = Path.home() / ".cache" / "quickshell"
OUTPUT_PATH = CACHE_DIR / "colors.json"

# Extra plain-copy targets: apps that just want the raw colors.json (same
# format as OUTPUT_PATH) rather than a matugen-style rendered template.
_EXTRA_COPY_PATHS = [
    Path.home() / ".config" / "orbit" / "colors.json",
]

_SCHEMES = {
    "content":    SchemeContent,
    "expressive": SchemeExpressive,
    "fidelity":   SchemeFidelity,
    "fruitsalad": SchemeFruitSalad,
    "monochrome": SchemeMonochrome,
    "neutral":    SchemeNeutral,
    "rainbow":    SchemeRainbow,
    "tonalspot":  SchemeTonalSpot,
    "vibrant":    SchemeVibrant,
}

# MaterialDynamicColors attr name → our JSON key (for quickshell colors.json)
_COLOR_MAP = {
    "primary":                    "primary",
    "onPrimary":                  "primaryText",
    "primaryContainer":           "primaryContainer",
    "onPrimaryContainer":         "primaryContainerText",
    "primaryFixed":               "primaryFixed",
    "primaryFixedDim":            "primaryFixedDim",
    "onPrimaryFixed":             "onPrimaryFixed",
    "onPrimaryFixedVariant":      "onPrimaryFixedVariant",
    "secondary":                  "secondary",
    "onSecondary":                "secondaryText",
    "secondaryContainer":         "secondaryContainer",
    "onSecondaryContainer":       "secondaryContainerText",
    "secondaryFixed":             "secondaryFixed",
    "secondaryFixedDim":          "secondaryFixedDim",
    "onSecondaryFixed":           "onSecondaryFixed",
    "onSecondaryFixedVariant":    "onSecondaryFixedVariant",
    "tertiary":                   "tertiary",
    "onTertiary":                 "tertiaryText",
    "tertiaryContainer":          "tertiaryContainer",
    "onTertiaryContainer":        "tertiaryContainerText",
    "tertiaryFixed":              "tertiaryFixed",
    "tertiaryFixedDim":           "tertiaryFixedDim",
    "onTertiaryFixed":            "onTertiaryFixed",
    "onTertiaryFixedVariant":     "onTertiaryFixedVariant",
    "error":                      "error",
    "onError":                    "errorText",
    "errorContainer":             "errorContainer",
    "onErrorContainer":           "errorContainerText",
    "surface":                    "surface",
    "onSurface":                  "surfaceText",
    "surfaceVariant":             "surfaceVariant",
    "onSurfaceVariant":           "surfaceVariantText",
    "outline":                    "outline",
    "outlineVariant":             "outlineVariant",
    "shadow":                     "shadow",
    "scrim":                      "scrim",
    "inverseSurface":             "inverseSurface",
    "inverseOnSurface":           "inverseSurfaceText",
    "inversePrimary":             "inversePrimary",
    "surfaceDim":                 "surfaceDim",
    "surfaceBright":              "surfaceBright",
    "surfaceContainerLowest":     "surfaceContainerLowest",
    "surfaceContainerLow":        "surfaceContainerLow",
    "surfaceContainer":           "surfaceContainer",
    "surfaceContainerHigh":       "surfaceContainerHigh",
    "surfaceContainerHighest":    "surfaceContainerHighest",
}

# Our JSON key → matugen snake_case name (for app templates)
_KEY_TO_MATUGEN = {
    "primary":                  "primary",
    "primaryText":              "on_primary",
    "primaryContainer":         "primary_container",
    "primaryContainerText":     "on_primary_container",
    "primaryFixed":             "primary_fixed",
    "primaryFixedDim":          "primary_fixed_dim",
    "onPrimaryFixed":           "on_primary_fixed",
    "onPrimaryFixedVariant":    "on_primary_fixed_variant",
    "secondary":                "secondary",
    "secondaryText":            "on_secondary",
    "secondaryContainer":       "secondary_container",
    "secondaryContainerText":   "on_secondary_container",
    "secondaryFixed":           "secondary_fixed",
    "secondaryFixedDim":        "secondary_fixed_dim",
    "onSecondaryFixed":         "on_secondary_fixed",
    "onSecondaryFixedVariant":  "on_secondary_fixed_variant",
    "tertiary":                 "tertiary",
    "tertiaryText":             "on_tertiary",
    "tertiaryContainer":        "tertiary_container",
    "tertiaryContainerText":    "on_tertiary_container",
    "tertiaryFixed":            "tertiary_fixed",
    "tertiaryFixedDim":         "tertiary_fixed_dim",
    "onTertiaryFixed":          "on_tertiary_fixed",
    "onTertiaryFixedVariant":   "on_tertiary_fixed_variant",
    "error":                    "error",
    "errorText":                "on_error",
    "errorContainer":           "error_container",
    "errorContainerText":       "on_error_container",
    "surface":                  "surface",
    "surfaceText":              "on_surface",
    "surfaceVariant":           "surface_variant",
    "surfaceVariantText":       "on_surface_variant",
    "outline":                  "outline",
    "outlineVariant":           "outline_variant",
    "shadow":                   "shadow",
    "scrim":                    "scrim",
    "inverseSurface":           "inverse_surface",
    "inverseSurfaceText":       "inverse_on_surface",
    "inversePrimary":           "inverse_primary",
    "surfaceDim":               "surface_dim",
    "surfaceBright":            "surface_bright",
    "surfaceContainerLowest":   "surface_container_lowest",
    "surfaceContainerLow":      "surface_container_low",
    "surfaceContainer":         "surface_container",
    "surfaceContainerHigh":     "surface_container_high",
    "surfaceContainerHighest":  "surface_container_highest",
}

# App templates: input template → output file (+ optional post_hook)
_HOME = Path.home()
_TPL  = _HOME / ".config" / "matugen" / "templates"

_APP_TEMPLATES = [
    {
        "name":   "btop",
        "input":  _TPL / "btop.theme",
        "output": _HOME / ".config/btop/themes/matugen.theme",
    },
    {
        "name":   "qt6ct",
        "input":  _TPL / "qt-colors.conf",
        "output": _HOME / ".config/qt6ct/colors/matugen.conf",
    },
    {
        "name":   "qt5ct",
        "input":  _TPL / "qt-colors.conf",
        "output": _HOME / ".config/qt5ct/colors/matugen.conf",
    },
    {
        "name":      "gtk3",
        "input":     _TPL / "gtk-colors.css",
        "output":    _HOME / ".config/gtk-3.0/gtk.css",
        "post_hook": 'gsettings set org.gnome.desktop.interface gtk-theme "" && '
                     'gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark',
    },
    {
        "name":   "gtk4",
        "input":  _TPL / "gtk4-colors.css",
        "output": _HOME / ".config/gtk-4.0/gtk.css",
    },
    {
        "name":      "hyprland",
        "input":     _TPL / "hyprland-colors.conf",
        "output":    _HOME / ".config/hypr/colors.conf",
        "post_hook": "hyprctl reload",
    },
    {
        "name":   "kitty",
        "input":  _TPL / "kitty-colors.conf",
        "output": _HOME / ".config/kitty/colors.conf",
    },
    {
        "name":   "nwgdock",
        "input":  _TPL / "colors.css",
        "output": _HOME / ".config/nwg-dock-hyprland/colors.css",
    },
    {
        "name":   "waybar",
        "input":  _TPL / "colors.css",
        "output": _HOME / ".config/waybar/colors.css",
    },
    {
        "name":      "pywalfox",
        "input":     _TPL / "pywalfox-colors.json",
        "output":    _HOME / ".cache/wal/colors.json",
        "post_hook": "pywalfox update",
    },
    {
        "name":      "tmux",
        "input":     _TPL / "tmux-colors.conf",
        "output":    _HOME / ".config/tmux/colors.conf",
        "post_hook": 'L="$HOME/.tmux.conf.local"; C="$HOME/.config/tmux/colors.conf"; '
                     '{ sed "/^# >>> m3 palette >>>$/q" "$L"; cat "$C"; '
                     r'sed -n "/^# <<< m3 palette <<<$/,\$p" "$L"; } > "$L.new" '
                     '&& cat "$L.new" > "$L" && rm -f "$L.new"; '
                     'for s in "${TMUX_TMPDIR:-/tmp}"/tmux-$(id -u)/*; do '
                     '[ -S "$s" ] && tmux -S "$s" source-file "$HOME/.tmux.conf"; '
                     'done',
    },
    {
        "name":   "starship",
        "input":  _TPL / "starship.toml",
        "output": _HOME / ".config/starship.toml",
    },
    {
        "name":   "obsidian",
        "input":  _TPL / "obsidian.css",
        "output": _HOME / "Steel's notes/.obsidian/themes/Matugen/theme.css",
    },
]


# ── Color utilities ────────────────────────────────────────────────────────────

def _hex_to_rgb(hex_color: str) -> tuple:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"


def _lighten(hex_color: str, amount: float) -> str:
    """Adjust lightness of a hex color by `amount` percentage points."""
    r, g, b = _hex_to_rgb(hex_color)
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    l = max(0.0, min(1.0, l + amount / 100))
    r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
    return _rgb_to_hex(round(r2 * 255), round(g2 * 255), round(b2 * 255))


def _set_alpha(hex_color: str, alpha: str) -> str:
    r, g, b = _hex_to_rgb(hex_color)
    return f"rgba({r}, {g}, {b}, {alpha})"


# ── Matugen-name dict ──────────────────────────────────────────────────────────

def _build_matugen_dict(our_colors: dict) -> dict:
    """Build sorted dict of matugen snake_case names → hex values."""
    result = {}
    for our_key, matugen_name in _KEY_TO_MATUGEN.items():
        if our_key in our_colors:
            result[matugen_name] = our_colors[our_key]
    # Material You 2 compat aliases
    if "surface" in our_colors:
        result["background"] = our_colors["surface"]
    if "surfaceText" in our_colors:
        result["on_background"] = our_colors["surfaceText"]
    return dict(sorted(result.items()))


# ── Template engine ────────────────────────────────────────────────────────────

def _render_template(template: str, matugen: dict, wallpaper: str) -> str:
    """Render a matugen-style template string with Material You colors."""
    result = template

    # <* for name, value in colors *>...<* endfor *>
    loop_re = re.compile(
        r"<\*\s*for\s+name,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*\*>",
        re.DOTALL,
    )
    def _expand_loop(m: re.Match) -> str:
        inner = m.group(1)
        lines = []
        for name, hex_val in matugen.items():
            stripped = hex_val.lstrip("#")
            r, g, b = _hex_to_rgb(hex_val)
            line = inner
            line = line.replace("{{name}}", name)
            line = line.replace("{{value.default.hex}}", hex_val)
            line = line.replace("{{value.default.hex_stripped}}", stripped)
            line = line.replace("{{value.default.rgba}}", f"rgba({r}, {g}, {b}, 1.0)")
            lines.append(line)
        return "".join(lines)
    result = loop_re.sub(_expand_loop, result)

    # {{image}}
    result = result.replace("{{image}}", wallpaper)

    # Templates may use {{ spaces }} or {{nospaces}} — \s* handles both forms.

    # {{ colors.X.Y.rgba | set_alpha: N }}
    def _repl_alpha(m: re.Match) -> str:
        hex_val = matugen.get(m.group(1), "#000000")
        return _set_alpha(hex_val, m.group(2))
    result = re.sub(
        r"\{\{\s*colors\.([a-z0-9_]+)\.[a-z]+\.[a-z]+\s*\|\s*set_alpha:\s*([\d.]+)\s*\}\}",
        _repl_alpha, result,
    )

    # {{ colors.X.Y.hex | lighten: N }}
    def _repl_lighten(m: re.Match) -> str:
        hex_val = matugen.get(m.group(1), "#000000")
        return _lighten(hex_val, float(m.group(2)))
    result = re.sub(
        r"\{\{\s*colors\.([a-z0-9_]+)\.[a-z]+\.hex\s*\|\s*lighten:\s*([-\d.]+)\s*\}\}",
        _repl_lighten, result,
    )

    # {{ base16.base08.Y.hex | lighten: N }}  → use error color
    def _repl_base16_lighten(m: re.Match) -> str:
        hex_val = matugen.get("error", "#ff0000")
        return _lighten(hex_val, float(m.group(1)))
    result = re.sub(
        r"\{\{\s*base16\.base08\.[a-z]+\.hex\s*\|\s*lighten:\s*([-\d.]+)\s*\}\}",
        _repl_base16_lighten, result,
    )

    # {{ colors.X.Y.hex_stripped }}
    def _repl_stripped(m: re.Match) -> str:
        return matugen.get(m.group(1), "#000000").lstrip("#")
    result = re.sub(
        r"\{\{\s*colors\.([a-z0-9_]+)\.[a-z]+\.hex_stripped\s*\}\}",
        _repl_stripped, result,
    )

    # {{ colors.X.Y.hex }}
    def _repl_hex(m: re.Match) -> str:
        return matugen.get(m.group(1), "#000000")
    result = re.sub(
        r"\{\{\s*colors\.([a-z0-9_]+)\.[a-z]+\.hex\s*\}\}",
        _repl_hex, result,
    )

    # {{ colors.X.Y.rgba }}  (standalone, without filter)
    def _repl_rgba(m: re.Match) -> str:
        hex_val = matugen.get(m.group(1), "#000000")
        r, g, b = _hex_to_rgb(hex_val)
        return f"rgba({r}, {g}, {b}, 1.0)"
    result = re.sub(
        r"\{\{\s*colors\.([a-z0-9_]+)\.[a-z]+\.rgba\s*\}\}",
        _repl_rgba, result,
    )

    return result


# ── Apply all app templates ────────────────────────────────────────────────────

def _apply_app_templates(our_colors: dict, wallpaper: str) -> None:
    matugen = _build_matugen_dict(our_colors)
    t0 = time.time()

    for tpl in _APP_TEMPLATES:
        input_path:  Path = tpl["input"]
        output_path: Path = tpl["output"]
        name:        str  = tpl["name"]

        if not input_path.exists():
            print(f"[gen_colors] skip {name}: template not found ({input_path})", flush=True)
            continue

        if not output_path.parent.exists():
            print(f"[gen_colors] skip {name}: output dir missing ({output_path.parent})", flush=True)
            continue

        try:
            template_str = input_path.read_text()
            rendered     = _render_template(template_str, matugen, wallpaper)
            _atomic_write(output_path, rendered)
            print(f"[gen_colors] wrote {name} → {output_path}", flush=True)
        except Exception as e:
            print(f"[gen_colors] ERROR {name}: {e}", file=sys.stderr)
            continue

        hook = tpl.get("post_hook")
        if hook:
            try:
                subprocess.Popen(hook, shell=True,
                                 stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL)
                print(f"[gen_colors] hook {name}: {hook}", flush=True)
            except Exception as e:
                print(f"[gen_colors] hook ERROR {name}: {e}", file=sys.stderr)

    print(f"[gen_colors] app templates done in {(time.time()-t0)*1000:.0f}ms", flush=True)


# ── Papirus folder color sync ─────────────────────────────────────────────────

_PAPIRUS_PATHS = [
    Path("/usr/share/icons/Papirus"),
    Path("/usr/share/icons/Papirus-Dark"),
    Path("/usr/share/icons/Papirus-Light"),
    Path.home() / ".local/share/icons/Papirus",
    Path.home() / ".icons/Papirus",
]


def _determine_papirus_hue(r: int, g: int, b: int, brightness: int, use_pale: bool) -> str:
    if b > r and b > g:
        r_ratio = (r * 100) // b if b > 0 else 0
        g_ratio = (g * 100) // b if b > 0 else 0
        rg_diff = abs(r - g)
        if r_ratio > 70 and g_ratio > 70:
            if rg_diff < 15:
                return "blue"
            elif r > g:
                return "violet"
            else:
                return "cyan"
        elif r_ratio > 60 and r > g:
            return "violet"
        elif g_ratio > 60 and g > r:
            return "cyan"
        else:
            return "blue"
    elif r > g and r > b:
        if g > b + 30:
            rg_ratio = (g * 100) // r if r > 0 else 0
            if use_pale:
                return "palebrown" if rg_ratio > 70 and brightness < 220 else "paleorange"
            else:
                return "brown" if rg_ratio > 70 and brightness < 180 else "orange"
        elif b > g + 20:
            return "pink"
        else:
            return "pink" if use_pale else "red"
    elif g > r and g > b:
        return "yellow" if r > b + 30 else "green"
    else:
        return "grey"


def _map_to_papirus_color(hex_color: str) -> str:
    """Map a hex color (with or without #) to the nearest Papirus folder color name."""
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

    max_val = max(r, g, b)
    min_val = min(r, g, b)
    brightness = max_val
    saturation = 0 if max_val == 0 else ((max_val - min_val) * 100) // max_val

    if saturation < 20:
        if brightness < 85:
            return "black"
        elif brightness < 170:
            return "grey"
        else:
            return "white"
    elif saturation < 60 and brightness > 180:
        return _determine_papirus_hue(r, g, b, brightness, use_pale=True)
    else:
        return _determine_papirus_hue(r, g, b, brightness, use_pale=False)


def _sync_papirus_colors(primary_hex: str, mode: str) -> None:
    """Recolor Papirus folder icons and switch GTK icon theme to Papirus."""
    if not any(p.exists() for p in _PAPIRUS_PATHS):
        return

    if subprocess.run(["which", "papirus-folders"], capture_output=True).returncode != 0:
        print("[gen_colors] papirus-folders not found — skipping icon sync", flush=True)
        return

    color = _map_to_papirus_color(primary_hex)
    icon_theme = "Papirus-Dark" if mode == "dark" else "Papirus-Light"
    print(f"[gen_colors] papirus-folders → {color} ({icon_theme})", flush=True)

    try:
        for theme in ("Papirus", "Papirus-Dark", "Papirus-Light"):
            if not any(p.name == theme and p.exists() for p in _PAPIRUS_PATHS):
                continue
            subprocess.Popen(
                ["sudo", "-n", "papirus-folders", "-C", color, "--theme", theme, "-u"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        subprocess.Popen(
            ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", icon_theme],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as e:
        print(f"[gen_colors] papirus-folders ERROR: {e}", file=sys.stderr)


# ── Font sync ──────────────────────────────────────────────────────────────────

# Body font → monospace equivalent (for terminal)
_FONT_TO_MONO = {
    "Adwaita Sans":    "Adwaita Mono",
    "Cantarell":       "Source Code Pro",
    "DejaVu Sans":     "DejaVu Sans Mono",
    "Fira Sans":       "FiraCode Nerd Font",
    "Liberation Sans": "Liberation Mono",
    "Noto Sans":       "Noto Sans Mono",
    "Readex Pro":      "Source Code Pro",
    "Rubik":           "Source Code Pro",
}

# Font size multiplier per fontScale setting
_FONT_SCALE_PT = {
    "small":      10,
    "normal":     12,
    "large":      13,
    "extralarge": 15,
}

# Nerd font PUA ranges → FiraCode NF for nerd font icons in kitty
_NF_SYMBOL_MAP = (
    "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,"
    "U+E000-U+E00A,U+E0A0-U+E0C8,U+E0CA,U+E0CC-U+E0D4,"
    "U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6B1,"
    "U+E700-U+E7C5,U+EA60-U+EBEB,"
    "U+F000-U+F2E0,U+F300-U+F372,U+F400-U+F532,"
    "U+F0001-U+F1AF0"
)
_NF_SYMBOL_FONT = "FiraCode Nerd Font"

_QS_SETTINGS = _HOME / ".cache" / "quickshell" / "settings.json"
_KITTY_CUSTOM = _HOME / ".config" / "kitty" / "custom.conf"


def _apply_fonts() -> None:
    try:
        settings = json.loads(_QS_SETTINGS.read_text())
    except Exception as e:
        print(f"[gen_colors] font sync: cannot read settings.json: {e}", file=sys.stderr)
        return

    general    = settings.get("general", {})
    body_font  = general.get("defaultFont", "Adwaita Sans")
    font_scale = general.get("fontScale", "normal")
    font_size  = _FONT_SCALE_PT.get(font_scale, 11)
    mono_font  = _FONT_TO_MONO.get(body_font, "Source Code Pro")

    # Write kitty custom.conf (overrides font_family from kitty.conf)
    kitty_conf = (
        f"# Auto-generated by gen_colors.py\n"
        f"font_family      {mono_font}\n"
        f"bold_font        auto\n"
        f"italic_font      auto\n"
        f"bold_italic_font auto\n"
        f"font_size        {font_size}.0\n"
        f"\n"
        f"# Nerd font icons via FiraCode NF (powerline + MDI + devicons)\n"
        f"symbol_map {_NF_SYMBOL_MAP} {_NF_SYMBOL_FONT}\n"
    )
    try:
        _atomic_write(_KITTY_CUSTOM, kitty_conf)
        print(f"[gen_colors] font sync: kitty → {mono_font} {font_size}pt", flush=True)
    except Exception as e:
        print(f"[gen_colors] font sync ERROR kitty: {e}", file=sys.stderr)

    # Apply system font via gsettings
    gs_cmds = [
        f'gsettings set org.gnome.desktop.interface font-name "{body_font} {font_size}"',
        f'gsettings set org.gnome.desktop.interface monospace-font-name "{mono_font} {font_size}"',
        f'gsettings set org.gnome.desktop.interface document-font-name "{body_font} {font_size}"',
    ]
    for cmd in gs_cmds:
        try:
            subprocess.Popen(cmd, shell=True,
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"[gen_colors] font sync gsettings ERROR: {e}", file=sys.stderr)
    print(f"[gen_colors] font sync: gsettings → {body_font} {font_size}pt", flush=True)


# ── Core color generation ──────────────────────────────────────────────────────

def _image_hash(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()[:24]


def _quantize_and_score(image_path: str) -> Hct:
    quantized = ImageQuantizeCelebi(image_path, 1, 128)

    colors_hct = []
    hue_population = [0] * 360
    population_sum = 0
    for rgb, population in quantized.items():
        hct = Hct.from_int(rgb)
        colors_hct.append(hct)
        hue_population[int(hct.hue)] += population
        population_sum += population

    hue_excited = [0.0] * 360
    for hue in range(360):
        prop = hue_population[hue] / population_sum
        for i in range(hue - 14, hue + 16):
            hue_excited[int(sanitize_degrees_int(i))] += prop

    scored = []
    for hct in colors_hct:
        hue  = int(sanitize_degrees_int(round(hct.hue)))
        prop = hue_excited[hue]
        cw   = 0.1 if hct.chroma < 48.0 else 0.3
        scored.append((prop * 100.0 * 0.7 + (hct.chroma - 48.0) * cw, hct))
    scored.sort(reverse=True)

    for cutoff in range(20, -1, -1):
        for _, hct in scored:
            if hct.chroma > cutoff and hct.tone > cutoff * 3:
                return DislikeAnalyzer.fix_if_disliked(hct)
    return DislikeAnalyzer.fix_if_disliked(scored[0][1])


def _build_scheme(primary: Hct, variant: str, is_dark: bool) -> dict:
    SchemeClass = _SCHEMES.get(variant, SchemeVibrant)
    scheme = SchemeClass(source_color_hct=primary, is_dark=is_dark, contrast_level=0.0)

    dyn = MaterialDynamicColors()
    if hasattr(dyn, "all_colors"):
        raw = {c.name: c.get_hct(scheme).to_int() for c in dyn.all_colors}
    else:
        raw = {}
        for attr in vars(MaterialDynamicColors):
            obj = getattr(MaterialDynamicColors, attr)
            if hasattr(obj, "get_hct"):
                raw[attr] = obj.get_hct(scheme).to_int()

    output = {}
    for src, dst in _COLOR_MAP.items():
        if src in raw:
            argb = raw[src] if isinstance(raw[src], int) else raw[src].to_int()
            output[dst] = f"#{argb & 0xFFFFFF:06x}"
    return output


def _atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(content)
        os.chmod(tmp, 0o644)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def _write_colors_json(content: str) -> None:
    """Writes colors.json to OUTPUT_PATH plus every plain-copy target in
    _EXTRA_COPY_PATHS (e.g. the file manager's own config dir)."""
    _atomic_write(OUTPUT_PATH, content)
    for path in _EXTRA_COPY_PATHS:
        try:
            _atomic_write(path, content)
            print(f"[gen_colors] copied colors.json → {path}", flush=True)
        except Exception as e:
            print(f"[gen_colors] ERROR copying colors.json to {path}: {e}", file=sys.stderr)


# ── Entry point ────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <image> <variant> <mode>", file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]
    variant    = sys.argv[2].removeprefix("scheme-")
    mode       = sys.argv[3].lower()
    is_dark    = mode != "light"

    if not os.path.isfile(image_path):
        print(f"[gen_colors] ERROR: image not found: {image_path}", file=sys.stderr)
        sys.exit(1)

    t_start     = time.time()
    img_hash    = _image_hash(image_path)
    cache_base  = CACHE_DIR / "color_cache" / img_hash
    score_cache = cache_base / "score.txt"
    color_cache = cache_base / f"{variant}_{mode}.json"

    # ── Fast path: full colors cached ─────────────────────────────────────
    if color_cache.exists():
        cached = color_cache.read_text()
        _write_colors_json(cached)
        our_colors = json.loads(cached)
        wallpaper  = our_colors.get("wallpaper", image_path)
        print(f"[gen_colors] cache hit ({(time.time()-t_start)*1000:.0f}ms) — {img_hash[:8]}_{variant}_{mode}")
        _apply_app_templates(our_colors, wallpaper)
        _apply_fonts()
        _sync_papirus_colors(our_colors.get("primary", ""), mode)
        return

    # ── Medium path: primary HCT cached ───────────────────────────────────
    primary = None
    if score_cache.exists():
        try:
            primary = Hct.from_int(int(score_cache.read_text()))
            print(f"[gen_colors] score cache hit — skipping quantize", flush=True)
        except Exception:
            primary = None

    # ── Slow path: quantize image ──────────────────────────────────────────
    if primary is None:
        t0 = time.time()
        primary = _quantize_and_score(image_path)
        print(f"[gen_colors] quantize+score: {(time.time()-t0)*1000:.0f}ms", flush=True)
        cache_base.mkdir(parents=True, exist_ok=True)
        score_cache.write_text(str(primary.to_int()))

    # ── Generate scheme ────────────────────────────────────────────────────
    t0 = time.time()
    our_colors = _build_scheme(primary, variant, is_dark)
    print(f"[gen_colors] scheme gen: {(time.time()-t0)*1000:.0f}ms", flush=True)

    our_colors["wallpaper"] = image_path
    content = json.dumps(our_colors, indent=4)

    cache_base.mkdir(parents=True, exist_ok=True)
    color_cache.write_text(content)
    _write_colors_json(content)

    print(f"[gen_colors] done in {(time.time()-t_start)*1000:.0f}ms — primary: {our_colors.get('primary', '?')}")

    _apply_app_templates(our_colors, image_path)
    _apply_fonts()
    _sync_papirus_colors(our_colors.get("primary", ""), mode)


if __name__ == "__main__":
    main()
