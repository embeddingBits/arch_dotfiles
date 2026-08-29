#!/bin/bash
wallpaper="$1"
gowall_theme="$2"

SCRIPTS_DIR="/home/steel/.config/quickshell/scripts"

if [ -z "$gowall_theme" ]; then
    echo "apply_gowall_theme.sh: no theme given" >&2
    exit 1
fi

converted="/tmp/gowall_wallpaper.png"

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    if gowall convert "$wallpaper" -t "$gowall_theme" --output "$converted"; then
        awww img "$converted" --transition-type fade --transition-duration 4
    else
        echo "apply_gowall_theme.sh: gowall convert failed" >&2
        awww img "$wallpaper" --transition-type fade --transition-duration 4
    fi
else
    echo "apply_gowall_theme.sh: no wallpaper path, only updating shell colors" >&2
fi

"$SCRIPTS_DIR/gowall_colors.sh" "$gowall_theme" "$wallpaper"

echo "apply_gowall_theme.sh: done ($gowall_theme)"
