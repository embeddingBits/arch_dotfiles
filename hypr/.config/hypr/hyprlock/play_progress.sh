#!/bin/bash

# Check MPD
if command -v mpc >/dev/null 2>&1; then
    status_line=$(mpc status | grep -E "playing|paused")
    if [ -n "$status_line" ]; then
        # Extract the second line of the status which contains time information
        time_info=$(mpc status | sed -n '2p')
        # Use awk to extract the times and format them
        progress=$(echo "$time_info" | awk '{print $3}' | tr -d '()' | sed 's|/| / |')
        echo "$progress"
        exit
    fi
fi

# Check all MPRIS players
if command -v playerctl >/dev/null 2>&1; then
    for p in $(playerctl -l 2>/dev/null); do
        status=$(playerctl -p "$p" status 2>/dev/null)
        if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
            # Get position and length in a human-readable format and combine them
            progress=$(playerctl -p "$p" metadata --format \
                "{{ duration(position) }} / {{ duration(mpris:length) }}" 2>/dev/null)
            if [ -n "$progress" ]; then
                echo "$progress"
                exit
            fi
        fi
    done
fi

echo "0:00 / 0:00"
