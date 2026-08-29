#!/usr/bin/env bash
# Package the extension into ../voice-bridge.xpi
#
# Run this after every edit to content.js or background.js, then reinstall the
# xpi in Zen. manifest.json must sit at the archive root — Firefox rejects an
# archive where the files are nested inside a folder, which is what you get if
# you zip the directory itself rather than its contents.

set -euo pipefail
cd "$(dirname "$0")"

OUT="../voice-bridge.xpi"
rm -f "$OUT"
FILES="manifest.json background.js content.js"
grep -q '"inject.js"' manifest.json && FILES="$FILES inject.js"
zip -r -FS "$OUT" $FILES >/dev/null

echo "built $(cd .. && pwd)/voice-bridge.xpi"
unzip -l "$OUT" | tail -n +4 | head -n -2
