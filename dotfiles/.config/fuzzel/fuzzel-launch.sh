#!/bin/sh

# Get the name of the focused output from riverctl
# It usually outputs something like "HDMI-A-1 (focused)"
FOCUS=$(riverctl list-outputs | grep '(focused)' | awk '{print $1}')

if [ "$FOCUS" = "HDMI-A-1" ]; then
    # Specific size for your 24" Dell Monitor
    # Adjust width and font size to your liking
    exec fuzzel --font="Iosevka Nerd Font:style=semibold:size=18" --line-height=35
else
    # Default size for your laptop screen (eDP-1)
    exec fuzzel
fi
