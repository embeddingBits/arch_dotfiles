#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-copy}"
EMOJI_FILE="${EMOJI_FILE:-$HOME/.config/fuzzel/emojis.txt}"

selection="$(
    awk -F'\t' '{
        emoji = $1
        desc  = $4
        keys  = $5
        printf "%-3s  %-40s  %s\n", emoji, desc, keys
    }' "$EMOJI_FILE" \
    | fuzzel --match-mode fzf --dmenu
)"

[ -z "$selection" ] && exit 0

emoji="$(printf "%s" "$selection" | awk '{print $1}')"

case "$MODE" in
    copy)
        wl-copy "$emoji"
        notify-send "Copied $emoji"
        ;;
    type)
        wtype "$emoji"
        ;;
    both)
        wl-copy "$emoji"
        wtype "$emoji" || true
        notify-send "Copied & typed $emoji"
        ;;
    *)
        echo "Usage: $0 [copy|type|both]"
        exit 1
        ;;
esac
