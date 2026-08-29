# Quickshell Voice Bridge (Zen extension)

Relays dictated prompts from the quickshell voice overlay into a claude.ai tab
and streams the reply back.

```
quickshell ──stdio JSON──> scripts/voice_bridge.py ──ws://127.0.0.1:8765──> background.js ──> content.js ──> claude.ai
```

## Files

| File | Role |
|---|---|
| `manifest.json` | Manifest v2 with a **persistent** background page. MV3 event pages get suspended after ~30s, which would drop the WebSocket and need alarm-based keepalive hacks. Firefox still fully supports MV2, including for AMO signing. |
| `background.js` | Owns the WebSocket, reconnects with exponential backoff, picks the claude.ai tab. The socket lives here because an `https://` page is subject to mixed-content blocking on `ws://`, while a `moz-extension://` background page is not. |
| `content.js` | **The only file that knows claude.ai's DOM.** Two entry points: `insertPrompt` and `watchForResponse`. |

## Building

```bash
./build.sh
```

Produces `../voice-bridge.xpi`. Re-run after every edit to `content.js` or
`background.js`, then reinstall in Zen.

`manifest.json` must be at the **root** of the archive. Zipping the `extension`
directory itself nests everything one level down and Firefox rejects it — that
is why `build.sh` lists the files explicitly rather than using `zip -r .`.

## Installing in Zen

Try these in order — stop at the first that works.

### 1. Disable signature enforcement (free, instant, may not work)

Open `about:config`, set `xpinstall.signatures.required` to `false`. Then
`about:addons` → gear icon → **Install Add-on From File** → pick
`voice-bridge.xpi`.

The file picker only lists `.xpi` and `.zip`, so it will look like an empty
folder until you have run `./build.sh`.

This only works on unbranded/developer builds. If Zen 1.11.5b enforces
signatures regardless, the install will be rejected — move to option 2.

### 2. Self-host through AMO (reliable, needs a Mozilla account)

Upload `voice-bridge.xpi` at https://addons.mozilla.org/developers/addon/submit/
and choose **"On your own"** distribution (unlisted). Automated signing returns a
signed `.xpi` in a few minutes. The add-on stays private — it is never listed.
Install the signed `.xpi` via `about:addons` → **Install Add-on From File**.

### 3. Temporary load (works today, gone on restart)

`about:debugging#/runtime/this-firefox` → **Load Temporary Add-on** → pick
`manifest.json`. Fine for testing, but Zen drops it every restart.

## Checking it works

1. Open a **chat** on claude.ai in Zen (not the home screen — the composer has to exist).
2. `qs ipc call voice status` should report `idle (bridge up)`.

If it says `bridge down`, open the extension's console:
`about:debugging` → **Inspect** next to the add-on → Console.

## When claude.ai changes its UI

The overlay will show an error naming which half broke — `composer` or
`response`. Open devtools on claude.ai and run:

```js
__voiceBridgeProbe()
```

It prints every selector in `content.js` with its match count, plus what each
one currently resolves to. Update the matching list in `SELECTORS` at the top of
`content.js`. Nothing else in the project needs touching.
