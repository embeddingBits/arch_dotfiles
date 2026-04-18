#!/usr/bin/env bash

QUERY=$(fuzzel --dmenu --lines 0 --placeholder "Search or Type URL")

if [ -z "$QUERY" ]; then
    exit 0
fi

if [[ "$QUERY" =~ ^(https?|ftp):// ]] || [[ "$QUERY" =~ ^[^\ ]+\.[^\ ]+ ]]; then
    firefox --new-tab "$QUERY"
else
    firefox --new-tab "https://www.google.com/search?q=$QUERY"
fi
