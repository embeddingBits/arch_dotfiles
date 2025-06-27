#!/usr/bin/env bash

# Get currently connected monitors from wlr-randr
get_all_monitors() {
    wlr-randr | awk '/^[^ ]/ {print $1}'
}

# Print monitor list
echo "📺 Available monitors:"
get_all_monitors
echo

# Ask user which monitor to switch to
read -rp "Enter the monitor to switch to (e.g., HDMI-A-1 or eDP-1): " MON

if [[ -z "$MON" ]]; then
    echo "❌ No monitor selected."
    exit 1
fi

# Enable selected monitor
echo "🛠️ Enabling monitor: $MON"
hyprctl keyword monitor "$MON,1920x1080@60,0x0,1"

# If switching to eDP-1, disable all others
if [[ "$MON" == "eDP-1" ]]; then
    for m in $(get_all_monitors); do
        if [[ "$m" != "eDP-1" ]]; then
            echo "🔻 Disabling $m"
            hyprctl keyword monitor "$m,disable"
        fi
    done
else
    # If switching to external, disable eDP-1
    echo "🔻 Disabling internal display eDP-1"
    hyprctl keyword monitor "eDP-1,disable"
fi

echo "✅ Switched to monitor: $MON"

# 🔁 Restart Waybar
echo "🔁 Restarting Waybar..."
pkill waybar
sleep 0.5
waybar -s ~/.config/waybar/blocks/style.css -c ~/.config/waybar/blocks/config.jsonc & disown

