pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string latestPath:      ""
    property bool   hasNew:          false
    property real   dismissProgress: 0.0

    // ── Auto-dismiss ─────────────────────────────────────────────────────────
    NumberAnimation {
        id: progressAnim
        target: root
        property: "dismissProgress"
        from: 0.0; to: 1.0
        duration: 5000
        running: root.hasNew
        onFinished: root.dismiss()
    }

    onHasNewChanged: {
        if (hasNew) {
            root.dismissProgress = 0.0
            progressAnim.restart()
        }
    }

    // ── API ──────────────────────────────────────────────────────────────────
    function dismiss() {
        progressAnim.stop()
        root.hasNew     = false
        root.latestPath = ""
    }

    function copyToClipboard() {
        if (root.latestPath === "") return
        const safe = root.latestPath.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", "wl-copy < '" + safe + "'"]
        copyProcess.running = true
        root.dismiss()
    }

    function editWithSwappy() {
        if (root.latestPath === "") return
        Quickshell.execDetached(["swappy", "-f", root.latestPath])
        root.dismiss()
    }

    function openFile() {
        if (root.latestPath === "") return
        Quickshell.execDetached(["xdg-open", root.latestPath])
        root.dismiss()
    }

    function deleteFile() {
        if (root.latestPath === "") return
        deleteProcess.command = ["rm", "--", root.latestPath]
        deleteProcess.running = true
        root.dismiss()
    }

    // ── Watcher ──────────────────────────────────────────────────────────────
    Process {
        running: true
        command: [
            "inotifywait", "-m", "-e", "close_write",
            "--format", "%f",
            Quickshell.env("HOME") + "/Pictures"
        ]
        stdout: SplitParser {
            onRead: line => {
                const f = line.trim()
                if (!f.match(/\.(png|jpg|jpeg|webp)$/i)) return
                root.latestPath = Quickshell.env("HOME") + "/Pictures/" + f
                root.hasNew     = true
            }
        }
    }

    Process { id: copyProcess }
    Process { id: deleteProcess }
}
