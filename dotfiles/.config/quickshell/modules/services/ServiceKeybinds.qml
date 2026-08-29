pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Parses the Hyprland keybindings out of the Lua config.
//
// Reads lua/keybinds.lua, NOT conf/keybindings/default.conf. The .conf chain
// still exists on disk but nothing loads it — hyprland.lua is the entry point,
// and every bind in the running compositor reports `dispatcher: __lua`. Parsing
// the .conf file produced a plausible-looking list that did not match reality.
//
// Shared by the cheat sheet overlay and the Keybindings settings page so the
// two cannot drift apart.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/hypr/lua/keybinds.lua"

    // [{ name, binds: [{ shortcut, description }] }]
    property var groups: []

    readonly property int bindCount: {
        var n = 0
        for (var i = 0; i < root.groups.length; i++) n += root.groups[i].binds.length
        return n
    }

    function reload() { readKeybinds.running = true }

    // Case-insensitive match on either the shortcut or its description.
    // Grouping is preserved so the cheat sheet keeps its section headers
    // while a search is being typed.
    function filtered(query) {
        const q = (query ?? "").trim().toLowerCase()
        if (q === "") return root.groups

        var out = []
        for (var i = 0; i < root.groups.length; i++) {
            const g = root.groups[i]
            const hits = g.binds.filter(b =>
                b.shortcut.toLowerCase().indexOf(q) !== -1 ||
                b.description.toLowerCase().indexOf(q) !== -1)
            if (hits.length > 0) out.push({ name: g.name, binds: hits })
        }
        return out
    }

    Process {
        id: readKeybinds
        running: true
        command: ["cat", root.path]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.groups = root.parse(data)
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    // "quickshellCheatSheet" -> "Quickshell cheat sheet"
    function _humanize(s) {
        if (!s) return ""
        var out = String(s).replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/[_\-]+/g, " ")
        out = out.trim().toLowerCase()
        return out.charAt(0).toUpperCase() + out.slice(1)
    }

    // Splits on a delimiter only where it appears outside a double-quoted
    // string. Lua's concat ".." and its comment "--" both occur inside string
    // literals in this config ("waypaper --random"), so naive splitting mangles
    // them.
    function _splitTop(s, delim) {
        var parts = [], depth = 0, inStr = false, start = 0
        for (var i = 0; i < s.length; i++) {
            const ch = s[i]
            if (inStr) {
                if (ch === "\\") { i++; continue }
                if (ch === '"') inStr = false
                continue
            }
            if (ch === '"') { inStr = true; continue }
            if (ch === "(" || ch === "{") { depth++; continue }
            if (ch === ")" || ch === "}") { depth--; continue }
            if (depth === 0 && s.substr(i, delim.length) === delim) {
                parts.push(s.substring(start, i))
                i += delim.length - 1
                start = i + 1
            }
        }
        parts.push(s.substring(start))
        return parts
    }

    // Index of the first `--` that is not inside a string literal, or -1.
    function _commentAt(s) {
        var inStr = false
        for (var i = 0; i < s.length; i++) {
            const ch = s[i]
            if (inStr) {
                if (ch === "\\") { i++; continue }
                if (ch === '"') inStr = false
                continue
            }
            if (ch === '"') { inStr = true; continue }
            if (ch === "-" && s[i + 1] === "-") return i
        }
        return -1
    }

    // Resolves a Lua concat expression into a display string: quoted literals
    // and `local` identifiers joined by "..".
    function _resolveExpr(expr, locals) {
        const parts = root._splitTop(String(expr), "..")
        var out = ""
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim()
            if (p === "") continue
            const q = p.match(/^"([\s\S]*)"$/)
            if (q) { out += q[1].replace(/\\"/g, '"'); continue }
            if (locals.hasOwnProperty(p)) { out += locals[p]; continue }
            // Loop counter — the caller expands the range
            out += p
        }
        return out.trim()
    }

    // Turns a dispatcher call into something readable when there is no comment.
    function _describe(disp, locals) {
        const d = String(disp).trim()

        const g = d.match(/global\s*\(\s*"([^"]*)"/)
        if (g) return root._humanize(g[1].replace(/^quickshell:/, ""))

        const e = d.match(/exec_cmd\s*\(([\s\S]*)\)\s*$/)
        if (e) return root._resolveExpr(e[1], locals)

        // hl.dsp.window.swap({ direction = "l" }) -> "Window swap — direction l"
        const m = d.match(/hl\.dsp\.([A-Za-z_.]+)\s*\(([\s\S]*)\)\s*$/)
        if (m) {
            var name = root._humanize(m[1].replace(/\./g, " "))
            const inner = m[2].trim()
            if (inner === "" || inner === "{}") return name
            const kv = inner.match(/([A-Za-z_]+)\s*=\s*"?([^",}]+)"?/)
            if (kv) return name + " — " + kv[1] + " " + kv[2].trim()
            const lit = inner.match(/^"([^"]*)"$/)
            if (lit) return name + " — " + lit[1]
            return name
        }

        return d
    }

    // ── Parser ────────────────────────────────────────────────────────────
    function parse(text) {
        const lines = text.split("\n")
        var groups = []
        var currentGroup = null
        var locals = {}
        var loopRange = ""      // non-empty while inside `for i = a, b do`

        function group() {
            if (!currentGroup) {
                currentGroup = { name: "General", binds: [] }
                groups.push(currentGroup)
            }
            return currentGroup
        }

        for (var i = 0; i < lines.length; i++) {
            const raw = lines[i]
            const line = raw.trim()
            if (line === "") continue

            // local name = "value"
            const loc = line.match(/^local\s+([A-Za-z_]\w*)\s*=\s*"([^"]*)"/)
            if (loc) { locals[loc[1]] = loc[2]; continue }

            // Section header: -- ─── Name ────────
            const sec = line.match(/^--\s*[─-]{2,}\s*(.+?)\s*[─-]{2,}/)
            if (sec) {
                currentGroup = { name: sec[1].trim(), binds: [] }
                groups.push(currentGroup)
                continue
            }

            // for i = 1, 9 do  — the body binds nine keys; show them as a range
            const forM = line.match(/^for\s+\w+\s*=\s*(\d+)\s*,\s*(\d+)\s*do/)
            if (forM) { loopRange = forM[1] + "–" + forM[2]; continue }
            if (line === "end") { loopRange = ""; continue }

            if (line.indexOf("hl.bind(") !== 0) continue

            // Trailing comment wins as the description
            var body = line
            var comment = ""
            const cIdx = root._commentAt(body)
            if (cIdx !== -1) {
                comment = body.substring(cIdx + 2).trim()
                body = body.substring(0, cIdx).trim()
            }

            // Everything between hl.bind( and its matching close paren
            const open = body.indexOf("(")
            var depth = 0, inStr = false, close = -1
            for (var c = open; c < body.length; c++) {
                const ch = body[c]
                if (inStr) {
                    if (ch === "\\") { c++; continue }
                    if (ch === '"') inStr = false
                    continue
                }
                if (ch === '"') { inStr = true; continue }
                if (ch === "(") depth++
                else if (ch === ")") { depth--; if (depth === 0) { close = c; break } }
            }
            if (close === -1) continue

            // args[0] = key, args[1] = dispatcher, args[2] = options (ignored)
            const args = root._splitTop(body.substring(open + 1, close), ",")
            if (args.length < 2) continue

            var shortcut = root._resolveExpr(args[0], locals)
            if (loopRange !== "") shortcut = shortcut.replace(/\bi\b/, loopRange)
            // Tidy spacing around the separator
            shortcut = shortcut.replace(/\s*\+\s*/g, " + ").trim()

            var desc = comment !== "" ? comment : root._describe(args[1].trim(), locals)
            // The loop counter leaks into descriptions too ("workspace i")
            if (loopRange !== "") desc = desc.replace(/\bi\b/, loopRange)

            group().binds.push({ shortcut: shortcut, description: desc })
        }

        return groups.filter(g => g.binds.length > 0)
    }
}
