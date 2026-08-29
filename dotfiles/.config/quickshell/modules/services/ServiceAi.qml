pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.settings
import "AiParse.js" as AiParse

Singleton {
    id: root

    readonly property string scriptDir: Quickshell.env("HOME") + "/.config/quickshell/scripts"
    readonly property string sttScript: scriptDir + "/ai_stt.sh"
    readonly property string bridgeScript: scriptDir + "/ai_bridge.py"
    readonly property string sttDaemonScript: scriptDir + "/ai_stt_daemon.py"
    readonly property string venvPython: Quickshell.env("HOME") + "/.local/state/quickshell/.venv/bin/python"
    readonly property string wavPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-ai.wav"

    readonly property bool enabled: SettingsConfig.ai?.enabled ?? true

    onEnabledChanged: if (!root.enabled) root.open = false

    property bool open: false

    property string state: "idle"

    readonly property bool busy: state === "transcribing" || state === "sending" || state === "streaming"
    readonly property bool recording: state === "recording"
    readonly property bool transcribing: state === "transcribing"

    readonly property bool replying: state === "sending" || state === "streaming" || state === "answer"

    readonly property bool awaitingReply: state === "sending" || state === "streaming"

    property var turns: []

    property string conversationId: ""
    property double conversationAt: 0

    property string response: ""

    property var responseBlocks: []

    property var _pendingReply: null

    property var conversations: []
    readonly property int conversationLimit: 30

    property bool historyOpen: false

    property int historyIndex: -1

    readonly property var viewedConversation:
        (historyOpen && historyIndex >= 0 && historyIndex < conversations.length)
            ? conversations[historyIndex]
            : null

    property string dictated: ""
    property int dictationSeq: 0

    property int recordingMs: 0

    property int draftSeq: 0

    property string notice: ""

    property bool bridgeConnected: false

    property string streamTap: ""

    property string thinkingText: ""

    readonly property string thinkingStatus: {
        const t = root.thinkingText.replace(/\s+/g, " ").trim()
        if (t === "") return ""
        return t.length > 110 ? "…" + t.slice(t.length - 110) : t
    }
    property int rawNodeCount: 0
    property bool rawTruncated: false

    readonly property bool keepScreenReader: SettingsConfig.ai?.keepScreenReader ?? false
    readonly property bool keepControls: SettingsConfig.ai?.keepControls ?? false
    property bool keepHidden: false

    property var midStreamSample: []
    property var lastNodes: []
    property var _sse: null
    property int lastCommittedSeq: -1

    function _renderNodes(list) {
            if (!list || list.length === 0) return "(empty)"
            const out = []
            for (let i = 0; i < list.length; i++) {
                const n = list[i]
                if (!n) continue
                if (n.k === "t") {
                    out.push("  ".repeat(n.d) + "\"" + String(n.x).replace(/\s+/g, " ").slice(0, 70) + "\"")
                } else if (n.k === "e") {
                    const flags = (n.h ? " HIDDEN(" + (n.y || "?") + ")" : "") + (n.s ? " SR" : "") + (n.b ? " CTL" : "")
                    out.push("  ".repeat(n.d) + "<" + n.g + ">"
                             + (n.c ? " ." + String(n.c).split(/\s+/).slice(0, 3).join(".") : "")
                             + (n.l ? " lang=" + n.l : "") + flags)
                }
            }
            return out.join("\n")
    }

    function _parse(nodes) {
        try {
            return AiParse.nodesToBlocks(nodes, {
                keepScreenReader: root.keepScreenReader,
                keepControls: root.keepControls,
                keepHidden: root.keepHidden
            })
        } catch (e) {
            return { blocks: [], thinking: "" }
        }
    }

    property int _promptId: 0
    property int _pendingId: -1

    property int _newChatId: -1

    signal answered()
    signal scrollToBottom()

    function show() {
        if (!root.enabled) return
        root.open = true
    }

    function hide() {
        root.open = false
    }

    function toggle() {
        if (!root.enabled) {
            root.open = false
            return
        }
        root.open = !root.open
    }

    function toggleMic() {
        switch (state) {
        case "transcribing": return
        case "recording":    stopRecording(); return
        case "idle":
        case "answer":       startRecording(); return
        default:             return
        }
    }

    function startRecording() {
        if (state === "recording" || state === "transcribing") return

        _commitReply()
        root.notice = ""
        root.recordingMs = 0

        root.state = "recording"
        recordProc.running = true

        sttDaemon.write(JSON.stringify({ cmd: "load" }) + "\n")
    }

    function stopRecording() {
        if (state !== "recording") return
        root.state = "transcribing"

        recordProc.signal(2)
    }

    function send(text) {
        const body = String(text ?? "").trim()
        if (body === "") {
            root.notice = "Nothing to send."
            return
        }
        if (!bridgeConnected) {
            root.notice = "Zen extension is not connected. Open claude.ai in Zen."
            return
        }
        if (root.awaitingReply) {
            root.notice = "Still waiting on the last reply."
            return
        }

        _commitReply()

        root.notice = ""
        root._appendTurn({ role: "user", text: body, at: Date.now() })
        root.response = ""
        root.responseBlocks = []
        root.thinkingText = ""
        root._sse = null
        root.midStreamSample = []
        root.revealChars = 0
        root._pendingReply = null
        root._promptId += 1
        root._pendingId = root._promptId
        root.state = "sending"
        bridgeProc.write(JSON.stringify({ type: "prompt", id: root._promptId, text: body }) + "\n")
        root.scrollToBottom()
    }

    function _newId() {
        return String(Date.now()) + "-" + Math.floor(Math.random() * 100000)
    }

    property int _turnSeq: 0

    function _numbered(blocks) {
        const out = Array.isArray(blocks) ? blocks : []
        for (let i = 0; i < out.length; i++)
            if (out[i]) out[i].id = i
        return out
    }

    function _numberTurns(turns) {
        const list = Array.isArray(turns) ? turns : []
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].blocks) root._numbered(list[i].blocks)
        return list
    }

    function _appendTurn(turn) {
        root._turnSeq += 1
        turn.seq = root._turnSeq
        root.turns = [...root.turns, turn]
        if (root.conversationId === "") {
            root.conversationId = _newId()
            root.conversationAt = turn.at
        }
        chatsWrite.restart()
    }

    function conversationTitle(c) {
        const list = (c && c.turns) ? c.turns : []
        for (let i = 0; i < list.length; i++)
            if (list[i].role === "user" && (list[i].text ?? "") !== "")
                return list[i].text
        return "Empty chat"
    }

    function _archiveCurrent() {
        if (root.turns.length === 0) return
        const entry = {
            id: root.conversationId !== "" ? root.conversationId : _newId(),
            at: root.conversationAt > 0 ? root.conversationAt : Date.now(),
            turns: root.turns
        }
        root.conversations = [entry, ...root.conversations].slice(0, root.conversationLimit)
    }

    function newChat() {
        _commitReply()
        const archived = root.turns.length > 0
        _archiveCurrent()

        root.turns = []
        root.conversationId = ""
        root.conversationAt = 0
        root.response = ""
        root.responseBlocks = []
        root.thinkingText = ""
        root.revealChars = 0
        root._pendingReply = null
        root._pendingId = -1
        root.notice = ""
        root.historyOpen = false
        root.historyIndex = -1
        root.draftSeq += 1
        if (root.state !== "recording" && root.state !== "transcribing")
            root.state = "idle"

        if (archived) root.notice = "Chat moved to history — Super+Shift+D to reopen it."

        if (bridgeConnected) {
            root._promptId += 1
            root._newChatId = root._promptId
            bridgeProc.write(JSON.stringify({ type: "newchat", id: root._promptId }) + "\n")
        } else {
            root.notice = "Cleared here, but Zen is not connected — start the new chat in the browser too."
        }

        chatsWrite.restart()
    }

    function openHistory() {
        root.historyIndex = -1
        root.historyOpen = true
    }

    function viewConversation(i) {
        if (i < 0 || i >= conversations.length) return
        root.historyIndex = i
    }

    function historyBack() {
        if (root.historyIndex >= 0) root.historyIndex = -1
        else root.historyOpen = false
    }

    function clearHistory() {
        root.conversations = []
        root.historyIndex = -1
        chatsWrite.restart()
    }

    function copyConversation() {
        const lines = []
        for (let i = 0; i < root.turns.length; i++) {
            const t = root.turns[i]
            lines.push((t.role === "user" ? "You: " : t.role === "error" ? "Error: " : "Claude: ") + (t.text ?? ""))
        }
        Quickshell.clipboardText = lines.join("\n\n")
    }

    function _commitReply() {
        if (!root._pendingReply) return
        const reply = root._pendingReply
        root._pendingReply = null
        root._appendTurn(reply)
        root.lastCommittedSeq = reply.seq
        root.response = ""
        root.responseBlocks = []
        root.revealChars = 0
        if (root.state === "answer" || root.state === "streaming" || root.state === "sending")
            root.state = "idle"
    }

    function _maybeCommit() {
        if (root.state !== "answer") return
        if (!root._pendingReply) {
            root.state = "idle"
            return
        }
        if (root.revealChars >= root.revealTotal) _commitReply()
    }

    onStateChanged: _maybeCommit()
    onRevealCharsChanged: _maybeCommit()

    function _failTurn(message) {
        if (root._pendingId !== -1) {
            root._pendingId = -1
            root._pendingReply = null
            root.response = ""
            root.responseBlocks = []
            root.revealChars = 0
            root._appendTurn({ role: "error", text: message, at: Date.now() })
            root.state = "idle"
            root.scrollToBottom()
        } else {
            root.notice = message
        }
    }

    property int revealChars: 0

    function _blockLength(b) {
        if (!b) return 0
        if (b.type === "table") {

            let n = 0
            const headers = b.headers ?? []
            for (let i = 0; i < headers.length; i++) n += String(headers[i] ?? "").length + 1
            const rows = b.rows ?? []
            for (let r = 0; r < rows.length; r++)
                for (let c = 0; c < rows[r].length; c++) n += String(rows[r][c] ?? "").length + 1
            return n
        }
        return String(b.text ?? "").length
    }

    readonly property var blockOffsets: {
        const out = []
        let n = 0
        for (let i = 0; i < root.responseBlocks.length; i++) {
            out.push(n)
            n += root._blockLength(root.responseBlocks[i]) + 1
        }
        out.push(n)
        return out
    }

    readonly property int revealTotal: root.blockOffsets.length > 0
        ? root.blockOffsets[root.blockOffsets.length - 1]
        : 0

    readonly property bool revealing: root.revealChars < root.revealTotal

    Timer {

        running: root.revealing && (root.state === "streaming" || root.state === "answer")
        interval: 16
        repeat: true
        onTriggered: {

            const behind = root.revealTotal - root.revealChars
            root.revealChars = Math.min(root.revealTotal,
                                        root.revealChars + Math.max(2, Math.ceil(behind / 20)))
        }
    }

    Process {
        id: recordProc

        command: ["bash", root.sttScript, "record", root.wavPath]

        environment: ({
            QS_AI_SOURCE: SettingsConfig.ai?.source ?? ""
        })

        stderr: StdioCollector { id: recordErr }

        onExited: (code, status) => {
            if (root.state === "transcribing") {

                sttDaemon.write(JSON.stringify({ cmd: "final", id: root._promptId + 1, path: root.wavPath }) + "\n")
                return
            }
            if (root.state === "recording") {
                const msg = recordErr.text.trim().replace(/^ERR:\s*/, "")
                root.notice = msg !== "" ? msg : "Recording stopped unexpectedly."
                root.state = "idle"
            }
        }
    }

    Process {
        id: sttDaemon
        running: root.enabled
        command: [root.venvPython, root.sttDaemonScript]
        stdinEnabled: true

        environment: ({
            QS_AI_FW_MODEL: SettingsConfig.ai?.model ?? "distil-large-v3",
            QS_AI_PROMPT: SettingsConfig.ai?.vocabulary ?? ""
        })

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root._onSttLine(data)
        }

        stderr: StdioCollector { id: sttErr }

        onExited: (code, status) => {

            sttRestart.start()
        }
    }

    Timer {
        id: sttRestart
        interval: 2000
        onTriggered: if (root.enabled) sttDaemon.running = true
    }

    function _onSttLine(line) {
        const text = String(line).trim()
        if (text === "") return

        let msg
        try {
            msg = JSON.parse(text)
        } catch (e) {
            return
        }

        switch (msg.type) {
        case "final":
            if (root.state !== "transcribing") return

            if ((msg.text || "").trim() === "") {
                root.notice = "didn't hear anything"
            } else {
                root.dictated = msg.text.trim()
                root.dictationSeq += 1
            }
            root.state = "idle"
            break

        case "error":
            if (root.state === "transcribing") {
                root.notice = msg.message || "Transcription failed."
                root.state = "idle"
            }
            break
        }
    }

    Timer {
        running: root.state === "recording"
        interval: 100
        repeat: true
        onTriggered: root.recordingMs += 100
    }

    Process {
        id: bridgeProc
        running: root.enabled
        command: ["python3", root.bridgeScript]
        stdinEnabled: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root._onBridgeLine(data)
        }

        onExited: (code, status) => {
            root.bridgeConnected = false
            if (!root.enabled) return

            bridgeRestart.interval = Math.min(bridgeRestart.interval * 2, 30000)
            bridgeRestart.start()
        }
    }

    Timer {
        id: bridgeRestart
        interval: 2000
        onTriggered: if (root.enabled) bridgeProc.running = true
    }

    onBridgeConnectedChanged: if (bridgeConnected) bridgeRestart.interval = 2000

    function _onBridgeLine(line) {
        const text = String(line).trim()
        if (text === "") return

        let msg
        try {
            msg = JSON.parse(text)
        } catch (e) {
            return
        }

        switch (msg.type) {
        case "bridge":
            root.bridgeConnected = !!msg.connected
            break

        case "hello":
            root.bridgeConnected = true
            break

        case "accepted":
            if (msg.id === root._pendingId) root.state = "streaming"
            break

        case "delta":

            if (msg.id === root._pendingId) {
                const d = root._parse(msg.nodes)
                root.response = msg.text || ""
                root.responseBlocks = root._numbered(d.blocks)
                root.thinkingText = d.thinking
                root.rawNodeCount = Array.isArray(msg.nodes) ? msg.nodes.length : 0
                root.rawTruncated = !!msg.truncated

                if (d.blocks.length === 0
                        && Array.isArray(msg.nodes) && msg.nodes.length > 0)
                    root.midStreamSample = msg.nodes.slice(0, 700)

                if (root.state === "sending") root.state = "streaming"
            }
            break

        case "done":
            if (msg.id === root._pendingId) {
                const f = root._parse(msg.nodes)
                root.response = msg.text || root.response
                if (f.blocks.length) root.responseBlocks = root._numbered(f.blocks)
                if (f.thinking !== "") root.thinkingText = f.thinking
                root.rawNodeCount = Array.isArray(msg.nodes) ? msg.nodes.length : root.rawNodeCount
                root.rawTruncated = !!msg.truncated
                if (Array.isArray(msg.nodes)) root.lastNodes = msg.nodes
                root._pendingId = -1

                root._pendingReply = {
                    role: "assistant",
                    text: root.response,
                    blocks: root.responseBlocks,
                    thinking: root.thinkingText,
                    at: Date.now()
                }
                root.state = "answer"
                root._maybeCommit()
                root.answered()
            }
            break

        case "rawchunk":
            if (msg.id === root._pendingId) {
                if (!root._sse) root._sse = AiParse.newStream()
                const acc = AiParse.feedStream(root._sse, msg.text || "")
                root.response = acc
                root.responseBlocks = root._numbered(AiParse.mdToBlocks(acc))
                root.thinkingText = root._sse.thinking || ""
                if (root.state === "sending") root.state = "streaming"
            }
            break

        case "rawdone":
            if (msg.id === root._pendingId) {
                const tail = root._sse ? root._sse.text : ""
                if (tail !== "") {
                    root.response = tail
                    root.responseBlocks = root._numbered(AiParse.mdToBlocks(tail))
                }
                root._sse = null
                root._pendingId = -1
                root._pendingReply = {
                    role: "assistant",
                    text: root.response,
                    blocks: root.responseBlocks,
                    thinking: root.thinkingText,
                    at: Date.now()
                }
                root.state = "answer"
                root._maybeCommit()
                root.answered()
            }
            break

        case "streamtap":
            root.streamTap = JSON.stringify(msg, null, 1)
            break

        case "newchat":
            root._newChatId = -1
            if (!msg.ok) root.notice = msg.message || "Could not start a new chat in Zen."
            break

        case "error":

            if (msg.id !== undefined && msg.id !== null && msg.id === root._newChatId) {
                root._newChatId = -1
                root.notice = msg.message || "Could not start a new chat in Zen."
                break
            }
            if (msg.id === undefined || msg.id === null || msg.id === root._pendingId) {
                root._failTurn(msg.message || "Browser bridge error.")
            }
            break

        case "fatal":
            root._failTurn(msg.message || "Bridge failed to start.")
            break
        }
    }

    Timer {
        id: chatsWrite
        interval: 400
        onTriggered: chatsFile.setText(JSON.stringify({
            version: 2,
            current: {
                id: root.conversationId,
                at: root.conversationAt,
                turns: root.turns
            },
            conversations: root.conversations
        }))
    }

    FileView {
        id: chatsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/ai-chats.json"

        preload: true
        printErrors: false

        onLoaded: {
            try {
                const parsed = JSON.parse(chatsFile.text())
                const past = Array.isArray(parsed.conversations) ? parsed.conversations : []
                for (let i = 0; i < past.length; i++) root._numberTurns(past[i]?.turns)
                root.conversations = past
                const cur = parsed.current
                if (cur && Array.isArray(cur.turns)) {

                    const restored = root._numberTurns(cur.turns)
                    for (let i = 0; i < restored.length; i++) restored[i].seq = i + 1
                    root._turnSeq = restored.length
                    root.turns = restored
                    root.conversationId = cur.id ?? ""
                    root.conversationAt = cur.at ?? 0
                }
            } catch (e) {
                root.conversations = []
            }
        }

        onLoadFailed: root._migrateLegacyHistory()
    }

    FileView {
        id: legacyFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/ai-history.json"
        preload: false
        blockLoading: true
        printErrors: false
    }

    function _migrateLegacyHistory() {
        let parsed
        try {
            parsed = JSON.parse(legacyFile.text())
        } catch (e) {
            return
        }
        if (!Array.isArray(parsed)) return

        const out = []
        for (let i = 0; i < parsed.length; i++) {
            const e = parsed[i]
            if (!e) continue
            const at = e.at ?? Date.now()
            out.push({
                id: String(at) + "-legacy" + i,
                at: at,
                turns: [
                    { role: "user", text: e.prompt ?? "", at: at },
                    { role: "assistant", text: e.text ?? "", blocks: root._numbered(e.blocks), at: at }
                ]
            })
        }
        root.conversations = out.slice(0, root.conversationLimit)
        if (out.length > 0) chatsWrite.restart()
    }

    IpcHandler {
        target: "ai"

        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
        function mic(): void { root.toggleMic() }
        function newChat(): void { root.newChat() }
        function status(): string { return root.state + (root.bridgeConnected ? " (bridge up)" : " (bridge down)") }

        function say(text: string): void { root.send(text) }
        function history(): void { root.openHistory() }
        function turnCount(): string { return String(root.turns.length) }
        function chatCount(): string { return String(root.conversations.length) }

        function diag(): string {
            return "state=" + root.state
                + " revealChars=" + root.revealChars
                + " revealTotal=" + root.revealTotal
                + " revealing=" + root.revealing
                + " pending=" + (root._pendingReply ? "set" : "null")
                + " offsets=" + JSON.stringify(root.blockOffsets)
        }
        function streamtap(): string { return root.streamTap !== "" ? root.streamTap : "(no streamtap message received)" }
        function thinking(): string { return root.thinkingText !== "" ? root.thinkingText : "(none carried)" }
        function dump(): string { return root._renderNodes(root.midStreamSample) }
        function tree(): string { return root._renderNodes(root.lastNodes) }
        function raw(): string {
            return "nodes=" + root.rawNodeCount
                + " truncated=" + root.rawTruncated
                + " blocks=" + root.responseBlocks.length
                + " thinkingChars=" + root.thinkingText.length
        }

        function reply(): string { return root.response }
        function blocks(): string { return JSON.stringify(root.responseBlocks, null, 1) }
        function transcript(): string { return JSON.stringify(root.turns, null, 1) }
    }
}
