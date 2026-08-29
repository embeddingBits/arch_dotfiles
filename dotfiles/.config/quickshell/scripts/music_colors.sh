#!/bin/bash
art_url="$1"
scheme="${2:-scheme-content}"
mode="${3:-dark}"

# Strip file:// prefix if present
image="${art_url#file://}"

if [ -z "$image" ] || [ ! -f "$image" ]; then
    echo "[music_colors] No valid image path: '$image'" >&2
    exit 1
fi

# Generate colors using only the music template — does NOT touch other theme files
matugen image "$image" \
    --config ~/.config/matugen/music_config.toml \
    -t "$scheme" \
    -m "$mode"

echo "[music_colors] Generated music colors from: $image"
