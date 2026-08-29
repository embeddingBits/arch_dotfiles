function _defaults(opts) {
    const o = opts || {}
    return {
        keepScreenReader: o.keepScreenReader === true,
        keepControls: o.keepControls === true,
        keepHidden: o.keepHidden === true
    }
}

var LANG_LINE = /(?:^|\n)[ \t]*([A-Za-z][A-Za-z0-9+#.\-]{0,14})[ \t]*$/

function _takeLangLabel(buf) {
    const m = buf.match(LANG_LINE)
    if (!m) return null
    const token = m[1]
    if (/[.,;:!?]$/.test(token)) return null
    if (token !== token.toLowerCase()) return null
    return { lang: token.toLowerCase(), buf: buf.slice(0, m.index) }
}

function nodesToBlocks(nodes, opts) {
    const cfg = _defaults(opts)
    const list = Array.isArray(nodes) ? nodes : []
    const blocks = []
    const hrefs = []

    let buf = ""
    let skipTo = -1
    let hideTo = -1
    let hiddenBuf = ""
    let thinking = ""
    let pre = null
    let tbl = null

    function flushText() {
        const t = buf.replace(/\n{3,}/g, "\n\n").trim()
        if (t !== "") blocks.push({ type: "text", text: t })
        buf = ""
    }

    function flushHidden() {
        const t = hiddenBuf.replace(/\s+/g, " ").trim()
        if (t !== "") thinking += (thinking === "" ? "" : "\n\n") + t
        hiddenBuf = ""
    }

    function closeTable() {
        let cols = tbl.headers.length
        for (let r = 0; r < tbl.rows.length; r++) cols = Math.max(cols, tbl.rows[r].length)
        if (cols > 0) {
            while (tbl.headers.length < cols) tbl.headers.push("")
            for (let r = 0; r < tbl.rows.length; r++)
                while (tbl.rows[r].length < cols) tbl.rows[r].push("")
            blocks.push({ type: "table", headers: tbl.headers, rows: tbl.rows })
        }
        tbl = null
    }

    for (let i = 0; i < list.length; i++) {
        const n = list[i]
        if (!n) continue

        if (skipTo >= 0) {
            if (n.k === "/" && n.d === skipTo) skipTo = -1
            continue
        }

        if (n.k === "e") {
            if ((n.b && !cfg.keepControls) || (n.s && !cfg.keepScreenReader)) {
                skipTo = n.d
                continue
            }
            if (n.h && !cfg.keepHidden && hideTo < 0) {
                flushText()
                hideTo = n.d
                continue
            }
            if (hideTo >= 0) continue

            const g = n.g

            if (pre) continue
            if (g === "pre") {
                let lang = n.l || ""
                if (lang === "") {
                    const taken = _takeLangLabel(buf)
                    if (taken) {
                        lang = taken.lang
                        buf = taken.buf
                    }
                }
                flushText()
                pre = { lang: lang, text: "" }
                continue
            }

            if (tbl) {
                if (g === "tr") tbl.row = []
                else if (g === "th" || g === "td") tbl.cell = ""
                continue
            }
            if (g === "table") {
                flushText()
                tbl = { headers: [], rows: [], row: null, cell: null }
                continue
            }

            switch (g) {
            case "br":         buf += "\n"; break
            case "h1":         buf += "\n# "; break
            case "h2":         buf += "\n## "; break
            case "h3":
            case "h4":
            case "h5":
            case "h6":         buf += "\n### "; break
            case "strong":
            case "b":          buf += "**"; break
            case "em":
            case "i":          buf += "*"; break
            case "del":
            case "s":          buf += "~~"; break
            case "code":       buf += "`"; break
            case "a":          hrefs.push(n.u || ""); buf += "["; break
            case "li":         buf += "\n" + (n.o ? String(n.i || 1) + ". " : "- "); break
            case "blockquote": buf += "\n> "; break
            case "hr":         buf += "\n---\n"; break
            }
            continue
        }

        if (n.k === "t") {
            if (hideTo >= 0) { hiddenBuf += n.x; continue }
            if (pre) { pre.text += n.x; continue }
            if (tbl) { if (tbl.cell !== null) tbl.cell += n.x; continue }
            buf += n.x
            continue
        }

        if (n.k === "/") {
            if (hideTo >= 0) {
                if (n.d === hideTo) { hideTo = -1; flushHidden() }
                continue
            }

            const g = n.g

            if (pre) {
                if (g === "pre") {
                    blocks.push({ type: "code", lang: pre.lang, text: pre.text.replace(/\n+$/, "") })
                    pre = null
                }
                continue
            }

            if (tbl) {
                if (g === "table") closeTable()
                else if (g === "tr") {
                    if (tbl.row) {
                        if (tbl.headers.length === 0) tbl.headers = tbl.row
                        else tbl.rows.push(tbl.row)
                        tbl.row = null
                    }
                } else if (g === "th" || g === "td") {
                    if (tbl.row && tbl.cell !== null)
                        tbl.row.push(tbl.cell.replace(/\s+/g, " ").trim())
                    tbl.cell = null
                }
                continue
            }

            switch (g) {
            case "p":
            case "h1":
            case "h2":
            case "h3":
            case "h4":
            case "h5":
            case "h6":
            case "ul":
            case "ol":
            case "blockquote": buf += "\n\n"; break
            case "strong":
            case "b":          buf += "**"; break
            case "em":
            case "i":          buf += "*"; break
            case "del":
            case "s":          buf += "~~"; break
            case "code":       buf += "`"; break
            case "a":          buf += "](" + (hrefs.length ? hrefs.pop() : "") + ")"; break
            }
            continue
        }
    }

    if (pre) blocks.push({ type: "code", lang: pre.lang, text: pre.text.replace(/\n+$/, "") })
    if (tbl) closeTable()
    flushText()
    flushHidden()

    for (let b = 0; b < blocks.length; b++) blocks[b].id = b

    return { blocks: blocks, thinking: thinking }
}

function newStream() {
    return { buf: "", data: [], text: "", thinking: "", skip: false }
}

function feedSse(st, chunk) {
    st.buf += chunk
    const out = []
    let idx
    while ((idx = st.buf.indexOf("\n")) !== -1) {
        let line = st.buf.slice(0, idx)
        st.buf = st.buf.slice(idx + 1)
        if (line.charAt(line.length - 1) === "\r") line = line.slice(0, -1)
        if (line === "") {
            if (st.data.length) {
                out.push(st.data.join("\n"))
                st.data = []
            }
            continue
        }
        if (line.indexOf("data:") === 0) st.data.push(line.slice(5).replace(/^ /, ""))
    }
    return out
}

function sseDelta(obj, st) {
    if (!obj || typeof obj !== "object") return ""

    const kind = obj.type || ""

    if (kind === "content_block_start") {
        const inner = obj.content_block && obj.content_block.type
        st.skip = !!(inner && inner !== "text")
        return ""
    }
    if (kind === "content_block_stop") {
        st.skip = false
        return ""
    }
    if (kind === "content_block_delta") {
        if (st.skip) return ""
        const d = obj.delta || {}
        if (d.type && d.type !== "text_delta") return ""
        return typeof d.text === "string" ? d.text : ""
    }

    if (typeof obj.completion === "string") return obj.completion
    if (obj.delta && typeof obj.delta.text === "string" && !st.skip) return obj.delta.text
    return ""
}

function sseThinking(obj) {
    if (!obj || obj.type !== "content_block_delta") return ""
    const d = obj.delta || {}
    if (d.type === "thinking_delta" && typeof d.thinking === "string") return d.thinking
    return ""
}

function feedStream(st, chunk) {
    const payloads = feedSse(st, String(chunk || ""))
    for (let i = 0; i < payloads.length; i++) {
        const raw = payloads[i]
        if (raw === "[DONE]") continue
        let obj
        try {
            obj = JSON.parse(raw)
        } catch (e) {
            continue
        }
        const piece = sseDelta(obj, st)
        if (piece) st.text += piece
        const reasoning = sseThinking(obj)
        if (reasoning) st.thinking += reasoning
    }
    return st.text
}

function _splitRow(line) {
    let s = line.trim()
    if (s.charAt(0) === "|") s = s.slice(1)
    if (s.charAt(s.length - 1) === "|") s = s.slice(0, -1)
    return s.split("|").map(function (c) { return c.trim() })
}

function _isSeparator(line) {
    return /^\s*\|?[\s:|-]+\|?\s*$/.test(line) && line.indexOf("-") !== -1
}

function mdToBlocks(md) {
    const blocks = []
    const lines = String(md || "").split("\n")
    let buf = []
    let i = 0

    function flush() {
        const t = buf.join("\n").replace(/\n{3,}/g, "\n\n").trim()
        if (t !== "") blocks.push({ type: "text", text: t })
        buf = []
    }

    while (i < lines.length) {
        const line = lines[i]

        const fence = line.match(/^\s*(`{3,}|~{3,})\s*([A-Za-z0-9+#._-]*)\s*$/)
        if (fence) {
            flush()
            const marker = fence[1].charAt(0)
            const width = fence[1].length
            const body = []
            i += 1
            while (i < lines.length) {
                const close = lines[i].match(/^\s*(`{3,}|~{3,})\s*$/)
                if (close && close[1].charAt(0) === marker && close[1].length >= width) {
                    i += 1
                    break
                }
                body.push(lines[i])
                i += 1
            }
            blocks.push({ type: "code", lang: (fence[2] || "").toLowerCase(), text: body.join("\n") })
            continue
        }

        if (/^\s*\|/.test(line) && i + 1 < lines.length && _isSeparator(lines[i + 1])) {
            flush()
            const headers = _splitRow(line)
            const rows = []
            i += 2
            while (i < lines.length && /^\s*\|/.test(lines[i])) {
                rows.push(_splitRow(lines[i]))
                i += 1
            }
            let cols = headers.length
            for (let r = 0; r < rows.length; r++) cols = Math.max(cols, rows[r].length)
            while (headers.length < cols) headers.push("")
            for (let r = 0; r < rows.length; r++)
                while (rows[r].length < cols) rows[r].push("")
            blocks.push({ type: "table", headers: headers, rows: rows })
            continue
        }

        buf.push(line)
        i += 1
    }

    flush()
    for (let b = 0; b < blocks.length; b++) blocks[b].id = b
    return blocks
}
