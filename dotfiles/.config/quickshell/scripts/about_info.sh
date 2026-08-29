#!/bin/bash
DIR=${1:-$HOME/.config/quickshell}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

QS=$(quickshell --version 2>/dev/null | awk '{print $2}')
COMPOSITOR=$(hyprctl version 2>/dev/null | head -1 | awk '{print $1, $2}')
KERNEL=$(uname -r 2>/dev/null)

DISTRO=""
if [ -r /etc/os-release ]; then
    DISTRO=$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-$NAME}")
fi

REVISION=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
if [ -n "$REVISION" ] && ! git -C "$DIR" diff --quiet 2>/dev/null; then
    REVISION="$REVISION*"
fi

printf '{"quickshell":"%s","compositor":"%s","kernel":"%s","distro":"%s","revision":"%s"}\n' \
    "$(json_escape "$QS")" \
    "$(json_escape "$COMPOSITOR")" \
    "$(json_escape "$KERNEL")" \
    "$(json_escape "$DISTRO")" \
    "$(json_escape "$REVISION")"
