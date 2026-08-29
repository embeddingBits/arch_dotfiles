#!/bin/bash
wallpaper="$1"
scheme="$2"
theme="${3,,}"
transition="${4:-fade}"

awww img "$wallpaper" --transition-type "$transition" --transition-duration 4
python3 "$HOME/.config/quickshell/scripts/gen_colors.py" "$wallpaper" "$scheme" "$theme"
