#!/usr/bin/env bash
# Sign the extension through addons.mozilla.org and install the result.
#
# Why bother: Firefox-derived browsers reject unsigned extensions, and a
# temporary add-on (about:debugging) is dropped on every browser restart — which
# silently reverts the extension to an old build and makes bugs look unfixed.
# A signed, self-hosted xpi installs permanently.
#
# "unlisted" distribution means AMO signs it but never publishes or reviews it;
# the add-on stays private to you.
#
# One-time setup:
#   1. Sign in at https://addons.mozilla.org/
#   2. Create API credentials: https://addons.mozilla.org/developers/addon/api/key/
#   3. Save them (chmod 600) to ~/.config/quickshell/.amo-credentials as:
#        AMO_JWT_ISSUER=user:12345678:123
#        AMO_JWT_SECRET=abcdef...
#
# Then just run this after any edit to content.js or background.js.

set -euo pipefail
cd "$(dirname "$0")"

CREDS="${AMO_CREDENTIALS:-$HOME/.config/quickshell/.amo-credentials}"
OUT_DIR="../"

if [ ! -f "$CREDS" ]; then
  cat >&2 <<EOF
No AMO credentials at $CREDS

Create them at https://addons.mozilla.org/developers/addon/api/key/ then:

  install -m600 /dev/null "$CREDS"
  \$EDITOR "$CREDS"      # AMO_JWT_ISSUER=... and AMO_JWT_SECRET=...

Or do it by hand this once: upload ../voice-bridge-src.zip at
https://addons.mozilla.org/developers/addon/submit/ and choose "On your own".
EOF
  exit 1
fi

# shellcheck disable=SC1090
. "$CREDS"
: "${AMO_JWT_ISSUER:?missing AMO_JWT_ISSUER in $CREDS}"
: "${AMO_JWT_SECRET:?missing AMO_JWT_SECRET in $CREDS}"

# Bump the patch version — AMO rejects a version it has already signed.
VERSION=$(python3 - <<'PY'
import json, pathlib
p = pathlib.Path("manifest.json")
m = json.loads(p.read_text())
major, minor, patch = (m["version"].split(".") + ["0", "0"])[:3]
m["version"] = "%s.%s.%d" % (major, minor, int(patch) + 1)
p.write_text(json.dumps(m, indent=2) + "\n")
print(m["version"])
PY
)
echo "==> version bumped to $VERSION"

echo "==> submitting to AMO for signing (unlisted)"
npx --yes web-ext sign \
  --channel=unlisted \
  --api-key="$AMO_JWT_ISSUER" \
  --api-secret="$AMO_JWT_SECRET" \
  --source-dir=. \
  --artifacts-dir="$OUT_DIR" \
  --ignore-files="*.md" "*.sh" \
  2>&1 | tail -20

SIGNED=$(ls -t "$OUT_DIR"/*.xpi 2>/dev/null | head -1)
echo "==> signed: $SIGNED"
echo "    Install it once via about:addons -> gear -> Install Add-on From File."
echo "    Future signed builds update in place; no reinstall needed."
