pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")
    readonly property bool isNiri: socketPath !== ""

    // workspaces: id -> workspace object
    property var workspaces: ({})
    // sorted array of workspaces (by output then idx)
    property var allWorkspaces: []
    // windows: array of window objects
    property var windows: []
    // outputs: name -> output info (from niri msg outputs)
    property var outputs: ({})
    property string currentOutput: ""
    property var currentOutputWorkspaces: []
    property int focusedWorkspaceIndex: -1
    // focused workspace id (u64 as string/int)
    property var focusedWorkspaceId: null
    property bool inOverview: false

    // Helpers to sort workspaces deterministically by output name then idx
    function setWorkspaces(newMap) {
        root.workspaces = newMap
        var arr = Object.values(newMap)
        arr.sort(function(a, b) {
            var outA = a.output ?? ""
            var outB = b.output ?? ""
            if (outA !== outB) return outA < outB ? -1 : 1
            return (a.idx ?? 0) - (b.idx ?? 0)
        })
        root.allWorkspaces = arr
        updateCurrentOutputWorkspaces()
    }

    function updateCurrentOutputWorkspaces() {
        if (!currentOutput) {
            // derive from focused workspace
            var fw = null
            for (var i = 0; i < allWorkspaces.length; i++) {
                if (allWorkspaces[i].is_focused) { fw = allWorkspaces[i]; break }
            }
            if (fw) currentOutput = fw.output ?? ""
        }
        if (!currentOutput && allWorkspaces.length > 0) {
            currentOutput = allWorkspaces[0].output ?? ""
        }
        var filtered = []
        for (var j = 0; j < allWorkspaces.length; j++) {
            if (allWorkspaces[j].output === currentOutput) filtered.push(allWorkspaces[j])
        }
        currentOutputWorkspaces = filtered

        focusedWorkspaceIndex = -1
        focusedWorkspaceId = null
        for (var k = 0; k < allWorkspaces.length; k++) {
            if (allWorkspaces[k].is_focused) {
                focusedWorkspaceIndex = k
                focusedWorkspaceId = allWorkspaces[k].id
                if (!currentOutput) currentOutput = allWorkspaces[k].output ?? ""
                break
            }
        }
        // also keep currentOutput in sync if focused changed
        if (focusedWorkspaceId !== null) {
            var fws = workspaces[focusedWorkspaceId]
            if (fws && fws.output) currentOutput = fws.output
        }
    }

    // Find workspace by output + idx
    function getWorkspaceByIdx(idx, outputName) {
        var targetOutput = outputName ?? currentOutput
        for (var i = 0; i < allWorkspaces.length; i++) {
            var ws = allWorkspaces[i]
            if (ws.idx === idx && ws.output === targetOutput) return ws
        }
        return null
    }

    function getWorkspaceById(id) {
        return workspaces[id] ?? null
    }

    // Fetch outputs via niri msg outputs (not in event stream)
    function fetchOutputs() {
        if (!isNiri) return
        outputsProc.running = true
    }

    Component.onCompleted: {
        if (isNiri) {
            console.log("[ServiceNiri] NIRI_SOCKET=" + socketPath + " – starting event stream")
            fetchOutputs()
        } else {
            console.log("[ServiceNiri] No NIRI_SOCKET – niri integration disabled")
        }
    }

    // ── Event stream via Process ────────────────────────────────────────
    Process {
        id: eventStreamProc
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.isNiri
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line || line.trim().length === 0) return
                try {
                    var event = JSON.parse(line)
                    root.handleNiriEvent(event)
                } catch (e) {
                    console.warn("[ServiceNiri] Failed to parse event:", line, e)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: console.warn("[ServiceNiri] event-stream stderr:", text)
        }
        onExited: (code, status) => {
            console.warn("[ServiceNiri] event-stream exited code=" + code + " status=" + status + " – restarting in 1s")
            restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: {
            if (root.isNiri) eventStreamProc.running = true
        }
    }

    Process {
        id: outputsProc
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    // data is object map outputName -> info
                    root.outputs = data
                    console.log("[ServiceNiri] Loaded outputs:", Object.keys(data).join(", "))
                    // infer currentOutput if not yet set
                    if (!root.currentOutput && Object.keys(data).length > 0) {
                        root.currentOutput = Object.keys(data)[0]
                    }
                } catch(e) {
                    console.warn("[ServiceNiri] Failed to parse outputs:", e, text)
                }
            }
        }
        onExited: code => {
            if (code !== 0) console.warn("[ServiceNiri] outputs fetch exit code", code)
        }
    }

    // ── Actions via Process ─────────────────────────────────────────────
    Process { id: actionProc }

    function runAction(args) {
        // args: array of strings after "niri msg action"
        var cmd = ["niri", "msg", "action"].concat(args)
        // Use a dedicated ephemeral Process via exec
        // Create a temporary Process object dynamically would be ideal, but we reuse actionProc:
        // Need to ensure previous actionProc not still running – queue via timer if needed.
        // Simplest: create new Process via Qt.createQmlObject – avoid race by using execDetached via Process.exec
        // However Process.exec is static? We'll use a new Process instance via creation.
        // For now reuse actionProc sequentially – niri actions are quick.
        if (actionProc.running) {
            // queue next action after current finishes
            pendingActions.push(cmd)
            return
        }
        actionProc.command = cmd
        actionProc.running = true
    }

    property var pendingActions: []

    Connections {
        target: actionProc
        function onExited(code, status) {
            if (code !== 0) console.warn("[ServiceNiri] action", actionProc.command, "exit", code)
            if (root.pendingActions.length > 0) {
                var next = root.pendingActions.shift()
                actionProc.command = next
                actionProc.running = true
            }
        }
    }

    // Public API
    function focusWorkspaceByIdx(idx) {
        if (idx === undefined || idx === null) return
        console.log("[ServiceNiri] focusWorkspace idx", idx)
        runAction(["focus-workspace", idx.toString()])
    }

    function focusWorkspaceById(id) {
        var ws = getWorkspaceById(id)
        if (ws && ws.idx !== undefined) focusWorkspaceByIdx(ws.idx)
        else console.warn("[ServiceNiri] focusWorkspaceById unknown id", id)
    }

    function moveWindowToWorkspace(windowId, workspaceIdx) {
        if (!windowId || !workspaceIdx) return
        console.log("[ServiceNiri] moveWindow", windowId, "to ws", workspaceIdx)
        runAction(["move-window-to-workspace", "--window-id", windowId.toString(), workspaceIdx.toString()])
    }

    // Overload that moves currently focused window
    function moveFocusedWindowToWorkspace(workspaceIdx) {
        runAction(["move-window-to-workspace", workspaceIdx.toString()])
    }

    function focusWindow(windowId) {
        runAction(["focus-window", "--id", windowId.toString()])
    }

    function closeWindow(windowId) {
        // niri close-window acts on focused window, but we can focus first then close? Use action with window-id not supported.
        // Fallback: focus then close
        if (windowId) {
            focusWindow(windowId)
            // delay close slightly
            closeTimer.windowId = windowId
            closeTimer.restart()
        } else {
            runAction(["close-window"])
        }
    }

    Timer {
        id: closeTimer
        interval: 50
        property var windowId
        onTriggered: runAction(["close-window"])
    }

    // ── Event handling ──────────────────────────────────────────────────
    function handleNiriEvent(event) {
        var type = Object.keys(event)[0]
        var data = event[type]
        // console.log("[ServiceNiri] event", type)
        switch (type) {
        case "WorkspacesChanged": handleWorkspacesChanged(data); break
        case "WorkspaceActivated": handleWorkspaceActivated(data); break
        case "WorkspaceActiveWindowChanged": handleWorkspaceActiveWindowChanged(data); break
        case "WindowsChanged": handleWindowsChanged(data); break
        case "WindowOpenedOrChanged": handleWindowOpenedOrChanged(data); break
        case "WindowClosed": handleWindowClosed(data); break
        case "WindowFocusChanged": handleWindowFocusChanged(data); break
        case "WindowLayoutsChanged": handleWindowLayoutsChanged(data); break
        case "WindowUrgencyChanged": handleWindowUrgencyChanged(data); break
        case "WorkspaceUrgencyChanged": handleWorkspaceUrgencyChanged(data); break
        case "OverviewOpenedOrClosed": handleOverviewChanged(data); break
        case "KeyboardLayoutsChanged": /* ignore */ break
        case "KeyboardLayoutSwitched": /* ignore */ break
        case "ConfigLoaded": /* ignore */ break
        case "CastsChanged": /* ignore */ break
        case "CastStartedOrChanged": /* ignore */ break
        case "CastStopped": /* ignore */ break
        case "ScreenshotCaptured": /* ignore */ break
        default: console.log("[ServiceNiri] unhandled event", type)
        }
    }

    function handleWorkspacesChanged(data) {
        console.log("[ServiceNiri] WorkspacesChanged:", JSON.stringify(data.workspaces.map(w=>({id:w.id, idx:w.idx, out:w.output, foc:w.is_focused, act:w.is_active}))))
        var newMap = {}
        for (var i = 0; i < data.workspaces.length; i++) {
            var ws = data.workspaces[i]
            newMap[ws.id] = ws
        }
        setWorkspaces(newMap)
        console.log("[ServiceNiri] after WorkspacesChanged allWorkspaces:", JSON.stringify(allWorkspaces.map(w=>({idx:w.idx, act:w.is_active, foc:w.is_focused}))))
    }

    function handleWorkspaceActivated(data) {
        console.log("[ServiceNiri] WorkspaceActivated:", JSON.stringify(data))
        // data: {id: u64, focused: bool}
        var targetId = data.id
        var ws = workspaces[targetId]
        if (!ws) {
            console.warn("[ServiceNiri] WorkspaceActivated unknown id", targetId)
            return
        }
        var targetOutput = ws.output
        var updated = {}
        for (var id in workspaces) {
            var w = workspaces[id]
            var copy = {}
            for (var k in w) copy[k] = w[k]
            if (w.output === targetOutput) {
                copy.is_active = (w.id === targetId)
            }
            if (data.focused) {
                copy.is_focused = (w.id === targetId)
            }
            updated[id] = copy
        }
        setWorkspaces(updated)
        if (data.focused) {
            focusedWorkspaceId = targetId
        }
        console.log("[ServiceNiri] after activated idx", ws.idx, "activeWs should be", ws.idx, "all:", JSON.stringify(allWorkspaces.map(w=>({idx:w.idx, act:w.is_active, foc:w.is_focused}))))
    }

    function handleWorkspaceActiveWindowChanged(data) {
        var ws = workspaces[data.workspace_id]
        if (!ws) return
        var updated = {}
        for (var id in workspaces) {
            var w = workspaces[id]
            if (w.id === data.workspace_id) {
                var copy = {}
                for (var k in w) copy[k] = w[k]
                copy.active_window_id = data.active_window_id
                updated[id] = copy
            } else {
                updated[id] = w
            }
        }
        workspaces = updated
        // trigger allWorkspaces recompute via setWorkspaces to keep binding
        setWorkspaces(updated)
    }

    function handleWindowsChanged(data) {
        // data.windows is complete list
        // sort by layout pos if outputs known
        var wins = data.windows
        windows = sortWindowsByLayout(wins)
    }

    function handleWindowOpenedOrChanged(data) {
        var win = data.window
        var found = false
        var newWindows = []
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].id === win.id) {
                newWindows.push(win)
                found = true
            } else {
                newWindows.push(windows[i])
            }
        }
        if (!found) newWindows.push(win)
        windows = sortWindowsByLayout(newWindows)
    }

    function handleWindowClosed(data) {
        var id = data.id
        var filtered = []
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].id !== id) filtered.push(windows[i])
        }
        windows = filtered
    }

    function handleWindowFocusChanged(data) {
        var focusedId = data.id
        var newWindows = []
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            var isFocused = (w.id === focusedId)
            if (!!w.is_focused === isFocused) {
                newWindows.push(w)
            } else {
                var copy = {}
                for (var k in w) copy[k] = w[k]
                copy.is_focused = isFocused
                newWindows.push(copy)
            }
        }
        windows = newWindows
        // also update workspace is_focused? WorkspacesChanged will update but we could infer
    }

    function handleWindowLayoutsChanged(data) {
        // data.changes: [[id, layout], ...]
        var layoutMap = {}
        for (var i = 0; i < data.changes.length; i++) {
            var pair = data.changes[i]
            layoutMap[pair[0]] = pair[1]
        }
        var newWindows = []
        for (var j = 0; j < windows.length; j++) {
            var w2 = windows[j]
            if (layoutMap[w2.id] !== undefined) {
                var copy2 = {}
                for (var k2 in w2) copy2[k2] = w2[k2]
                copy2.layout = layoutMap[w2.id]
                newWindows.push(copy2)
            } else {
                newWindows.push(w2)
            }
        }
        windows = sortWindowsByLayout(newWindows)
    }

    function handleWindowUrgencyChanged(data) {
        var newWindows = []
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            if (w.id === data.id) {
                var c = {}
                for (var k in w) c[k] = w[k]
                c.is_urgent = data.urgent
                newWindows.push(c)
            } else newWindows.push(w)
        }
        windows = newWindows
    }

    function handleWorkspaceUrgencyChanged(data) {
        var ws = workspaces[data.id]
        if (!ws) return
        var upd = {}
        for (var id in workspaces) {
            var w = workspaces[id]
            if (w.id === data.id) {
                var copy = {}
                for (var k in w) copy[k] = w[k]
                copy.is_urgent = data.urgent
                upd[id] = copy
            } else upd[id] = w
        }
        setWorkspaces(upd)
    }

    function handleOverviewChanged(data) {
        inOverview = data.is_open
    }

    function sortWindowsByLayout(list) {
        // If we don't have outputs or workspaces, just return as is
        if (!list || list.length === 0) return list
        // Need workspace -> output mapping and output logical positions
        var enriched = []
        for (var i = 0; i < list.length; i++) {
            var w = list[i]
            var ws = workspaces[w.workspace_id]
            var outName = ws ? ws.output : ""
            var outInfo = outputs[outName]
            var outX = 999999, outY = 999999
            if (outInfo && outInfo.logical) {
                outX = outInfo.logical.x ?? 999999
                outY = outInfo.logical.y ?? 999999
            }
            var wsIdx = ws ? ws.idx : 999999
            var pos = w.layout ? w.layout.pos_in_scrolling_layout : null
            var col = 999999, row = 999999
            if (pos && pos.length >= 2) {
                col = pos[0]; row = pos[1]
            }
            enriched.push({win: w, outX: outX, outY: outY, wsIdx: wsIdx, col: col, row: row})
        }
        enriched.sort(function(a,b){
            if (a.outX !== b.outX) return a.outX - b.outX
            if (a.outY !== b.outY) return a.outY - b.outY
            if (a.wsIdx !== b.wsIdx) return a.wsIdx - b.wsIdx
            if (a.col !== b.col) return a.col - b.col
            if (a.row !== b.row) return a.row - b.row
            return a.win.id - b.win.id
        })
        var out = []
        for (var j = 0; j < enriched.length; j++) out.push(enriched[j].win)
        return out
    }

    // Utility for matching Wayland Toplevel to niri window via appId/title
    function findNiriWindowForToplevel(toplevel) {
        if (!toplevel) return null
        var appId = toplevel.appId ?? toplevel.wayland?.appId ?? ""
        var title = toplevel.title ?? toplevel.wayland?.title ?? ""
        // Try exact appId + title match first
        var best = null, bestScore = -1
        for (var i = 0; i < windows.length; i++) {
            var nw = windows[i]
            if (nw.app_id !== appId) continue
            var score = 1
            if (nw.title && title) {
                if (nw.title === title) score = 3
                else if (title.includes(nw.title) || nw.title.includes(title)) score = 2
            }
            if (score > bestScore) {
                bestScore = score; best = nw
                if (score === 3) break
            }
        }
        // If no appId match, fallback to title only
        if (!best) {
            for (var j = 0; j < windows.length; j++) {
                var nw2 = windows[j]
                if (nw2.title && title && nw2.title === title) { best = nw2; break }
            }
        }
        return best
    }

    // Return list of Wayland toplevels enriched with niri IDs, filtered by workspace idx + output
    // This is used by TopLevels to show icons per workspace
    function getNiriWindowsForWorkspace(idx, outputName) {
        var ws = getWorkspaceByIdx(idx, outputName)
        if (!ws) return []
        var res = []
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].workspace_id === ws.id) res.push(windows[i])
        }
        return res
    }
}
