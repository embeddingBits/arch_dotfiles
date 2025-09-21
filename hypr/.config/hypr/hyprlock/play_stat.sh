#!/bin/bash

# Check MPD
if command -v mpc >/dev/null 2>&1; then
    mpd_status=$(mpc status | head -n 2 | tail -n 1)
    if echo "$mpd_status" | grep -q "playing"; then
        echo "Playing"
        exit 0
    elif echo "$mpd_status" | grep -q "paused"; then
        echo "Paused"
        exit 0
    fi
fi

# Check MPRIS players
for p in $(playerctl -l 2>/dev/null); do
    status=$(playerctl -p "$p" status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        echo "Playing"
        exit 0
    elif [ "$status" = "Paused" ]; then
        echo "Paused"
        exit 0
    fi
done

# If nothing is playing
echo "Not playing"

