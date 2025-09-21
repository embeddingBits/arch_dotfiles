#!/bin/bash

# Check MPD
if command -v mpc >/dev/null 2>&1; then
    status=$(mpc status)
    if echo "$status" | grep -q "playing\|paused"; then
        song=$(mpc current)
        if [ -n "$song" ]; then
            echo "$song"
            exit
        fi
    fi
fi

# Check all MPRIS players
if command -v playerctl >/dev/null 2>&1; then
    for p in $(playerctl -l 2>/dev/null); do
        status=$(playerctl -p "$p" status 2>/dev/null)
        if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
            track=$(playerctl -p "$p" metadata --format "{{ artist }} - {{ title }}" 2>/dev/null)
            if [ -n "$track" ]; then
                echo "$track"
                exit
            fi
        fi
    done
fi
