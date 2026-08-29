pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string childrenScript:
        Quickshell.env("HOME") + "/.config/quickshell/scripts/storage_children.sh"

    property var drives: []
    property var children: []
    property bool mapScanning: false

    property string childrenPath: ""
    property string scanTarget: ""

    property var pathStack: []
    readonly property string currentPath:
        root.pathStack.length > 0 ? root.pathStack[root.pathStack.length - 1] : ""
    readonly property bool canGoUp: root.pathStack.length > 1

    property string fileManager: "xdg-open"

    readonly property var rootDrive: {
        for (let i = 0; i < root.drives.length; i++)
            if (root.drives[i].target === "/") return root.drives[i]
        return null
    }

    readonly property var breadcrumb: {
        const p = root.currentPath
        if (p === "") return []
        const parts = p.split("/").filter(s => s !== "")
        const out = [{ label: "/", path: "/" }]
        let acc = ""
        for (const seg of parts) {
            acc += "/" + seg
            out.push({ label: seg, path: acc })
        }
        return out
    }

    function formatBytes(bytes) {
        const b = Number(bytes) || 0
        if (b >= 1099511627776) return (b / 1099511627776).toFixed(2) + " TB"
        if (b >= 1073741824)    return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576)       return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024)          return (b / 1024).toFixed(0) + " KB"
        return b + " B"
    }

    function openPath(path) {
        if (!path) return
        Quickshell.execDetached([root.fileManager, path])
    }

    function refreshDrives() {
        dfProc.buffer = ""
        dfProc.running = true
    }

    function scanPath(path) {
        if (!path) return
        root.scanTarget = path
        root.mapScanning = true
        childrenProc.rows = []
        childrenProc.dirty = false
        childrenProc.command = ["bash", root.childrenScript, path]
        childrenProc.running = true
    }

    function publishRows() {
        const rows = childrenProc.rows.slice()
        rows.sort((a, b) => b.bytes - a.bytes)
        root.childrenPath = root.scanTarget
        if (rows.length <= 40) {
            root.children = rows
            return
        }
        const top = rows.slice(0, 40)
        let o = 0
        for (let i = 40; i < rows.length; i++) o += rows[i].bytes
        if (o > 0) top.push({ bytes: o, isDir: false, name: "(other)" })
        root.children = top
    }

    function openRoot(path) {
        root.pathStack = [path]
        root.scanPath(path)
    }

    function drillInto(name) {
        if (!name || name === "(other)") return
        const base = root.currentPath === "/" ? "" : root.currentPath
        const next = base + "/" + name
        root.pathStack = root.pathStack.concat([next])
        root.scanPath(next)
    }

    function goUp() {
        if (!root.canGoUp) return
        const stack = root.pathStack.slice()
        stack.pop()
        root.pathStack = stack
        root.scanPath(root.currentPath)
    }

    function jumpTo(path) {
        const idx = root.pathStack.indexOf(path)
        if (idx >= 0) root.pathStack = root.pathStack.slice(0, idx + 1)
        else root.pathStack = [path]
        root.scanPath(root.currentPath)
    }

    function rescan() {
        root.refreshDrives()
        root.scanPath(root.currentPath)
    }

    Component.onCompleted: {
        root.refreshDrives()
        root.openRoot(root.home)
    }

    Process {
        running: true
        command: ["bash", "-c",
            "for c in nautilus dolphin thunar nemo pcmanfm-qt pcmanfm caja; do " +
            "command -v $c >/dev/null 2>&1 && { echo $c; exit 0; }; done; echo xdg-open"]
        stdout: SplitParser {
            onRead: line => {
                const t = line.trim()
                if (t !== "") root.fileManager = t
            }
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: root.mapScanning
        onTriggered: {
            if (!childrenProc.dirty) return
            childrenProc.dirty = false
            root.publishRows()
        }
    }

    Process {
        id: childrenProc
        property var rows: []
        property bool dirty: false

        stdout: SplitParser {
            onRead: line => {
                const t = line.replace(/\n$/, "")
                if (t.trim() === "") return
                const p = t.split("\t")
                if (p.length < 3) return
                const bytes = parseFloat(p[0])
                if (!isFinite(bytes) || bytes <= 0) return
                childrenProc.rows.push({
                    bytes: bytes,
                    isDir: p[1] === "1",
                    name: p.slice(2).join("\t")
                })
                childrenProc.dirty = true
            }
        }

        onExited: {
            root.publishRows()
            childrenProc.rows = []
            childrenProc.dirty = false
            root.mapScanning = false
        }
    }

    Process {
        id: dfProc
        command: ["df", "-B1", "--output=source,target,fstype,size,used,avail",
                  "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "squashfs"]
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => dfProc.buffer += data + "\n"
        }

        onExited: {
            const lines = dfProc.buffer.trim().split("\n")
            const out = []
            for (let i = 1; i < lines.length; i++) {
                const p = lines[i].trim().split(/\s+/)
                if (p.length < 6) continue
                const size = parseFloat(p[3])
                const used = parseFloat(p[4])
                if (!isFinite(size) || size <= 0) continue
                out.push({
                    source: p[0], target: p[1], fstype: p[2],
                    size: size, used: used, avail: parseFloat(p[5]),
                    pct: Math.max(0, Math.min(1, used / size))
                })
            }
            out.sort((a, b) => b.size - a.size)
            root.drives = out
            dfProc.buffer = ""
        }
    }
}
