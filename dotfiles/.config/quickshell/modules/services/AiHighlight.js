const KEYWORDS = new Set([
    "abstract", "and", "as", "assert", "async", "await", "bool", "boolean", "break", "byte",
    "case", "catch", "char", "class", "const", "constexpr", "continue", "ctypedef", "def",
    "default", "defer", "del", "delete", "do", "double", "elif", "else", "elseif", "end",
    "enum", "except", "export", "extends", "extern", "false", "final", "finally", "float",
    "fn", "for", "from", "func", "function", "global", "go", "goto", "if", "impl", "implements",
    "import", "in", "include", "instanceof", "int", "interface", "is", "lambda", "let", "local",
    "long", "loop", "match", "mod", "module", "mut", "namespace", "new", "nil", "None", "not",
    "null", "nullptr", "object", "or", "package", "pass", "private", "protected", "public",
    "pub", "raise", "range", "record", "ref", "return", "select", "self", "short", "signed",
    "sizeof", "static", "std", "str", "struct", "super", "switch", "template", "then", "this",
    "throw", "throws", "trait", "true", "try", "type", "typedef", "typeof", "union", "unsigned",
    "use", "using", "var", "virtual", "void", "volatile", "when", "where", "while", "with",
    "yield", "True", "False", "Null"
])

function _esc(s) {
    return String(s)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\t/g, "    ")
        .replace(/ /g, "&nbsp;")
        .replace(/\n/g, "<br/>")
}

function _commentPattern(lang) {
    const l = String(lang || "").toLowerCase()

    if (/^(py|python|sh|bash|zsh|fish|rb|ruby|yaml|yml|toml|ini|conf|r|perl|pl|makefile|dockerfile)$/.test(l))
        return "#[^\\n]*"

    if (/^(sql|lua|hs|haskell|elm|ada)$/.test(l))
        return "--[^\\n]*"

    if (/^(lisp|clj|clojure|scheme|el)$/.test(l))
        return ";[^\\n]*"

    if (/^(html|xml|svg|vue|md|markdown)$/.test(l))
        return "&lt;!--[\\s\\S]*?--&gt;|<!--[\\s\\S]*?-->"

    // c-like default, plus '#' so shell-ish snippets in unlabelled blocks still read well
    return "//[^\\n]*|/\\*[\\s\\S]*?\\*/|#[^\\n]*"
}

function _scanner(lang) {
    const comment = _commentPattern(lang)
    const string =
        '"""[\\s\\S]*?"""' +
        "|'''[\\s\\S]*?'''" +
        '|"(?:\\\\.|[^"\\\\\\n])*"' +
        "|'(?:\\\\.|[^'\\\\\\n])*'" +
        "|`(?:\\\\.|[^`\\\\])*`"
    const number = "\\b0[xXbBoO][0-9a-fA-F_]+\\b|\\b\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b"
    const word = "[A-Za-z_$][A-Za-z0-9_$]*"

    return new RegExp(
        "(" + comment + ")|(" + string + ")|(" + number + ")|(" + word + ")",
        "g"
    )
}

function highlight(code, lang, palette) {
    const src = String(code || "")
    if (src === "") return ""

    const p = palette || {}
    const re = _scanner(lang)

    let out = ""
    let last = 0
    let m

    const paint = (color, text) =>
        color ? '<span style="color:' + color + '">' + _esc(text) + "</span>" : _esc(text)

    while ((m = re.exec(src)) !== null) {
        if (m.index > last) out += _esc(src.slice(last, m.index))

        const tok = m[0]
        if (m[1] !== undefined) out += paint(p.comment, tok)
        else if (m[2] !== undefined) out += paint(p.string, tok)
        else if (m[3] !== undefined) out += paint(p.number, tok)
        else if (m[4] !== undefined) out += paint(KEYWORDS.has(tok) ? p.keyword : "", tok)
        else out += _esc(tok)

        last = m.index + tok.length
        if (tok.length === 0) re.lastIndex += 1
    }

    out += _esc(src.slice(last))
    return out
}
