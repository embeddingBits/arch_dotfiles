pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool installed: false
    property bool connected: false
    property bool busy: false
    property string error: ""

    property string country: ""
    property string city: ""
    property string serverId: ""
    property string ip: ""

    function connectFastest() {
        if (root.busy || !root.installed) return
        root.busy = true
        root.error = ""
        connectProcess.command = ["protonvpn", "connect"]
        connectProcess.running = true
    }

    function disconnectVpn() {
        if (root.busy || !root.installed) return
        root.busy = true
        root.error = ""
        disconnectProcess.running = true
    }

    function _resetConnectionState() {
        root.connected = false
        root.country = ""
        root.city = ""
        root.serverId = ""
        root.ip = ""
    }

    Component.onCompleted: {
        installedCheck.running = true
        statusProcess.running = true
    }

    // ── Installed check ──────────────────────────────────────────────
    Process {
        id: installedCheck
        command: ["which", "protonvpn"]
        running: false
        onExited: function(code) { root.installed = (code === 0) }
    }

    // ── Status polling ───────────────────────────────────────────────
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!root.installed) return
            statusProcess.running = true
        }
    }

    Process {
        id: statusProcess
        command: ["protonvpn", "status"]
        running: false
        property string _buffer: ""
        stdout: SplitParser {
            onRead: function(line) { statusProcess._buffer += line + "\n" }
        }
        onRunningChanged: if (running) statusProcess._buffer = ""
        onExited: function(code) {
            const out = statusProcess._buffer
            if (/Status:\s*Connected/i.test(out)) {
                root.connected = true
            } else if (/Status:\s*Disconnected/i.test(out)) {
                if (root.connected) root._resetConnectionState()
                root.connected = false
            }
        }
    }

    // ── Connect ──────────────────────────────────────────────────────
    Process {
        id: connectProcess
        running: false
        property string _buffer: ""
        stdout: SplitParser {
            onRead: function(line) { connectProcess._buffer += line + "\n" }
        }
        stderr: SplitParser {
            onRead: function(line) { connectProcess._buffer += line + "\n" }
        }
        onRunningChanged: if (running) connectProcess._buffer = ""
        onExited: function(code) {
            root.busy = false
            const out = connectProcess._buffer

            if (code === 0) {
                const m = out.match(/Connected to (\S+) in ([^,]+), ([^.]+)\./)
                const ipM = out.match(/Your new IP address is ([0-9a-fA-F:.]+)\./)
                root.connected = true
                root.serverId = m ? m[1] : ""
                root.city = m ? m[2].trim() : ""
                root.country = m ? m[3].trim() : ""
                root.ip = ipM ? ipM[1] : ""
            } else {
                root._resetConnectionState()
                if (/sign.?in|log.?in|not authenticated/i.test(out)) {
                    root.error = "Not signed in — run \"protonvpn signin\" in a terminal"
                } else {
                    const lines = out.trim().split("\n").filter(l => l.trim().length > 0)
                    root.error = lines.length > 0 ? lines[lines.length - 1].replace(/^Error:\s*/, "") : "Connection failed"
                }
            }
        }
    }

    // ── Disconnect ───────────────────────────────────────────────────
    Process {
        id: disconnectProcess
        command: ["protonvpn", "disconnect"]
        running: false
        onExited: function(code) {
            root.busy = false
            root._resetConnectionState()
        }
    }
}
