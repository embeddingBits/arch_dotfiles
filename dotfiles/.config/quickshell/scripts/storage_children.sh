#!/usr/bin/env bash
# usage: storage_children.sh <dir>
# emits: bytes<TAB>isDir(1|0)<TAB>name
# streamed as results land: plain files first (one stat pass), then each
# subdirectory as its own du finishes. unsorted overall — the caller sorts.
set -u
D="${1:?dir required}"
J=$(nproc 2>/dev/null || echo 8)
RD=$(stat -c '%d' "$D" 2>/dev/null) || exit 0

find "$D" -mindepth 1 -maxdepth 1 ! -type d -printf '%s\t0\t%f\n' 2>/dev/null \
| sort -rn \
| awk -F'\t' 'NR<=60 { print; next } { o += $1 } END { if (o > 0) printf "%d\t0\t(other)\n", o }'

find "$D" -mindepth 1 -maxdepth 1 -type d -printf '%D\t%p\0' 2>/dev/null \
| awk -v RS='\0' -F'\t' -v r="$RD" '$1 == r { printf "%s%c", $2, 0 }' \
| xargs -0 -r -P "$J" -n 1 bash -c '
    b=$(du -sxb -- "$1" 2>/dev/null | cut -f1)
    [ -n "$b" ] && printf "%s\t1\t%s\n" "$b" "${1##*/}"
  ' _
