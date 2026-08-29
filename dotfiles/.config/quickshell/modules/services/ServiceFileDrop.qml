pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/filedrop.py"
    readonly property string shareListPath: Quickshell.env("HOME") + "/.cache/quickshell/filedrop-share.json"
    readonly property string qrPath: "/tmp/nebula_drop_qr.png"

    property string saveDir: SettingsConfig.general?.fileDropDir || (Quickshell.env("HOME") + "/Downloads")

    property bool running: false
    property string url: ""
    property string ip: ""
    property int port: 0
    property string error: ""
    property string peer: ""

    property var shared: []
    property var transfers: []

    property int qrRevision: 0
    property bool notify: true

    signal received(string name, string path)

    function _notify(summary, body, icon) {
        if (!root.notify) return
        ServiceNotification.sendNotification(summary, body, "Nebula Drop", icon)
    }

    function start() {
        if (root.running) return
        root.error = ""
        root.peer = ""
        root.url = ""
        root._writeShareList()
        server.command = ["python3", root.scriptPath,
                          "--dir", root.saveDir,
                          "--share-list", root.shareListPath]
        server.running = true
        root.running = true
    }

    function stop() {
        const wasRunning = root.running
        server.running = false
        root.running = false
        root.url = ""
        root.peer = ""
        if (wasRunning)
            root._notify("Drop session ended", "The link is no longer reachable",
                         "network-wireless")
    }

    function humanSize(bytes) {
        if (!bytes || bytes <= 0) return ""
        const units = ["B", "KB", "MB", "GB"]
        let v = bytes
        for (let i = 0; i < units.length; i++) {
            if (v < 1024 || i === units.length - 1)
                return (i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
            v /= 1024
        }
        return ""
    }

    function toggle() {
        if (root.running) root.stop()
        else root.start()
    }

    function share(paths) {
        const add = (paths ?? []).filter(p => !!p && !root.shared.includes(p))
        if (add.length === 0) return
        root.shared = root.shared.concat(add)
        root._writeShareList()
    }

    function unshare(path) {
        root.shared = root.shared.filter(p => p !== path)
        root._writeShareList()
    }

    function clearShared() {
        root.shared = []
        root._writeShareList()
    }

    function clearTransfers() {
        root.transfers = []
    }

    function _writeShareList() {
        shareFile.setText(JSON.stringify(root.shared))
    }

    function _push(entry) {
        const next = [entry].concat(root.transfers)
        root.transfers = next.slice(0, 40)
    }

    FileView {
        id: shareFile
        path: root.shareListPath
    }

    Process {
        id: server
        running: false

        stdout: SplitParser {
            onRead: line => {
                if (!line) return
                let e = null
                try {
                    e = JSON.parse(line)
                } catch (err) {
                    return
                }
                if (e.event === "ready") {
                    root.url = e.url
                    root.ip = e.ip
                    root.port = e.port
                    root._makeQr(e.url)
                    root._notify("Drop session started", e.url, "network-wireless")
                } else if (e.event === "peer") {
                    const first = root.peer === ""
                    root.peer = e.addr
                    if (first)
                        root._notify("Phone connected", e.addr, "network-wireless")
                } else if (e.event === "upload") {
                    root._push({ kind: "in", name: e.name, size: e.size, path: e.path })
                    root.received(e.name, e.path)
                    root._notify("Received " + e.name,
                                 root.humanSize(e.size) + " → " + root.saveDir,
                                 "document-save")
                } else if (e.event === "download") {
                    root._push({ kind: "out", name: e.name, size: 0, path: "" })
                    root._notify("Sent " + e.name, "Downloaded by " + (root.peer || "phone"),
                                 "document-send")
                } else if (e.event === "error") {
                    root.error = e.message
                    root._notify("Drop error", e.message, "dialog-error")
                }
            }
        }

        onExited: {
            root.running = false
            root.url = ""
        }
    }

    function _makeQr(text) {
        qrProcess.command = ["qrencode", "-o", root.qrPath, "-s", "8", "-m", "1", text]
        qrProcess.running = true
    }

    Process {
        id: qrProcess
        onExited: code => {
            if (code === 0) root.qrRevision++
            else root.error = "qrencode failed"
        }
    }

    Component.onDestruction: server.running = false
}
