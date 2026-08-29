pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    property real cpuUsage: 0.0     // 0.0 – 1.0
    property real memUsage: 0.0     // 0.0 – 1.0
    property real memUsedGb: 0.0
    property real memTotalGb: 0.0
    property real cpuTemp: 0.0      // °C (Tctl from k10temp)
    property real diskUsage: 0.0    // 0.0 – 1.0
    property real diskUsedGb: 0.0
    property real diskTotalGb: 0.0
    property real gpuUsage: 0.0     // 0.0 – 1.0
    property real gpuTemp: 0.0      // °C
    property real gpuVramUsage: 0.0 // 0.0 – 1.0
    property real gpuVramUsedGb: 0.0
    property real gpuVramTotalGb: 0.0
    property real gpuClockMhz: 0.0
    property string gpuName: ""
    property string cpuName: ""
    property real netDownloadBps: 0.0   // bytes/sec
    property real netUploadBps: 0.0     // bytes/sec
    property real netTotalRxBytes: 0.0  // cumulative
    property real netTotalTxBytes: 0.0  // cumulative
    property var uptime

    property int _refCount: 0

    function retain() {
        _refCount++
    }

    function release() {
        if (_refCount > 0) _refCount--
        if (_refCount === 0) _resetNetBaseline()
    }

    function formatNetSpeed(bps) {
        if (bps >= 1024 * 1024) return (bps / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bps >= 1024)        return (bps / 1024).toFixed(1) + " KB/s"
        return bps.toFixed(1) + " B/s"
    }

    function formatBytes(bytes) {
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
        if (bytes >= 1024 * 1024)        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        if (bytes >= 1024)               return (bytes / 1024).toFixed(1) + " KB"
        return bytes.toFixed(0) + " B"
    }

    // --- Static info (cpu name, gpu name, vram total — run once at startup) ---
    Process {
        id: staticInfoProc
        running: true
        command: ["bash", "-c", [
            "echo cpu:$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')",
            "echo gpu:$(lspci | grep -i vga | sed 's/.*: //')",
            "echo vram:$(cat /sys/class/drm/card1/device/mem_info_vram_total)"
        ].join(" && ")]

        stdout: SplitParser {
            onRead: data => {
                const sep = data.indexOf(":")
                const key = data.slice(0, sep)
                const val = data.slice(sep + 1)
                if      (key === "cpu")  root.cpuName       = val
                else if (key === "gpu")  root.gpuName       = val
                else if (key === "vram") root.gpuVramTotalGb = parseInt(val) / (1024 * 1024 * 1024)
            }
        }
    }

    // --- CPU usage (needs two /proc/stat snapshots to diff) ---
    property var _prevCpu: null

    FileView {
        id: cpuFile
        path: "/proc/stat"

        onLoaded: {
            const line = text().split("\n")[0]
            const p = line.trim().split(/\s+/)
            const user    = parseInt(p[1])
            const nice    = parseInt(p[2])
            const system  = parseInt(p[3])
            const idle    = parseInt(p[4])
            const iowait  = parseInt(p[5])
            const irq     = parseInt(p[6])
            const softirq = parseInt(p[7])

            const total   = user + nice + system + idle + iowait + irq + softirq
            const idleSum = idle + iowait

            if (root._prevCpu) {
                const dt = total   - root._prevCpu.total
                const di = idleSum - root._prevCpu.idle
                root.cpuUsage = dt > 0 ? (dt - di) / dt : 0
            }

            root._prevCpu = { total: total, idle: idleSum }
        }
    }

    // --- Memory ---
    FileView {
        id: memFile
        path: "/proc/meminfo"

        onLoaded: {
            const lines = text().split("\n")
            let total = 0, available = 0
            for (const line of lines) {
                if (line.startsWith("MemTotal:"))
                    total = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("MemAvailable:"))
                    available = parseInt(line.split(/\s+/)[1])
            }
            root.memTotalGb = total / (1024 * 1024)
            root.memUsedGb  = (total - available) / (1024 * 1024)
            root.memUsage   = total > 0 ? (total - available) / total : 0
        }
    }

    // --- CPU temperature (AMD k10temp Tctl, millidegrees → °C) ---
    FileView {
        id: cpuTempFile
        path: "/sys/class/hwmon/hwmon4/temp1_input"

        onLoaded: {
            root.cpuTemp = parseInt(text().trim()) / 1000
        }
    }

    // --- GPU busy % (amdgpu) ---
    FileView {
        id: gpuBusyFile
        path: "/sys/class/drm/card1/device/gpu_busy_percent"

        onLoaded: {
            root.gpuUsage = parseInt(text().trim()) / 100
        }
    }

    // --- GPU temperature (amdgpu hwmon, millidegrees → °C) ---
    FileView {
        id: gpuTempFile
        path: "/sys/class/hwmon/hwmon2/temp1_input"

        onLoaded: {
            root.gpuTemp = parseInt(text().trim()) / 1000
        }
    }

    // --- GPU VRAM ---
    FileView {
        id: gpuVramUsedFile
        path: "/sys/class/drm/card1/device/mem_info_vram_used"

        onLoaded: {
            const used  = parseInt(text().trim())
            root.gpuVramUsedGb = used / (1024 * 1024 * 1024)
            if (root.gpuVramTotalGb > 0)
                root.gpuVramUsage = used / (root.gpuVramTotalGb * 1024 * 1024 * 1024)
        }
    }

    // --- GPU clock (Hz → MHz) ---
    FileView {
        id: gpuClockFile
        path: "/sys/class/hwmon/hwmon2/freq1_input"

        onLoaded: {
            root.gpuClockMhz = parseInt(text().trim()) / 1000000
        }
    }

    // --- Network speed (active interface from /proc/net/dev) ---
    readonly property string netInterface: ServiceNetwork.activeInterface

    readonly property int netWindowMinutes: {
        const n = parseInt(SettingsConfig.widgets?.networkGraphWindow ?? "3")
        return (isNaN(n) || n <= 0) ? 3 : n
    }

    readonly property int netSampleIntervalMs: {
        const n = parseInt(SettingsConfig.widgets?.networkGraphInterval ?? "2")
        return Math.max(1000, Math.min(60000, (isNaN(n) || n <= 0 ? 2 : n) * 1000))
    }

    readonly property int _netRawPoints:
        Math.max(1, Math.round(root.netWindowMinutes * 60000 / root.netSampleIntervalMs))

    readonly property int netSamplesPerPoint: Math.max(1, Math.ceil(root._netRawPoints / 240))

    readonly property int netHistoryPoints:
        Math.max(2, Math.round(root._netRawPoints / root.netSamplesPerPoint))

    signal netSampled()

    property var _prevNet: null
    property real _lastNetTime: 0

    function _resetNetBaseline() {
        root._prevNet = null
        root._lastNetTime = 0
    }

    function _clearNetReadings() {
        root.netDownloadBps = 0
        root.netUploadBps = 0
    }

    onNetInterfaceChanged: {
        _resetNetBaseline()
        _clearNetReadings()
        root.netTotalRxBytes = 0
        root.netTotalTxBytes = 0
    }

    FileView {
        id: netFile
        path: "/proc/net/dev"

        onLoaded: {
            const iface = root.netInterface
            if (!iface) {
                root._resetNetBaseline()
                root._clearNetReadings()
                root.netSampled()
                return
            }

            const prefix = iface + ":"
            const lines = text().split("\n")
            let rx = NaN, tx = NaN

            for (const line of lines) {
                const trimmed = line.trim()
                if (!trimmed.startsWith(prefix)) continue
                const parts = trimmed.slice(prefix.length).trim().split(/\s+/)
                rx = parseFloat(parts[0])
                tx = parseFloat(parts[8])
                break
            }

            if (isNaN(rx) || isNaN(tx)) {
                root._resetNetBaseline()
                root._clearNetReadings()
                root.netSampled()
                return
            }

            const now = Date.now()
            const dt = (now - root._lastNetTime) / 1000

            const usable = root._prevNet !== null
                && rx >= root._prevNet.rx
                && tx >= root._prevNet.tx
                && dt > 0
                && dt < (root.netSampleIntervalMs / 1000) * 3

            if (usable) {
                root.netDownloadBps = (rx - root._prevNet.rx) / dt
                root.netUploadBps   = (tx - root._prevNet.tx) / dt
            } else {
                root._clearNetReadings()
            }

            root.netTotalRxBytes = rx
            root.netTotalTxBytes = tx
            root._prevNet = { rx: rx, tx: tx }
            root._lastNetTime = now
            root.netSampled()
        }
    }

    Timer {
        interval: root.netSampleIntervalMs
        repeat: true
        running: root._refCount > 0
        triggeredOnStart: true
        onTriggered: netFile.reload()
    }

    // inotify doesn't work on /proc or /sys, so poll manually
    Timer {
        interval: 4000
        repeat: true
        running: root._refCount > 0
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload()
            memFile.reload()
            cpuTempFile.reload()
            gpuBusyFile.reload()
            gpuTempFile.reload()
            gpuVramUsedFile.reload()
            gpuClockFile.reload()
        }
    }

    // --- Disk (df, polls slower since it changes rarely) ---
    Process {
        id: diskProc
        command: ["df", "-B1", "--output=used,size", "/"]

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => diskProc.buffer += data + "\n"
        }

        onExited: {
            const lines = diskProc.buffer.trim().split("\n")
            if (lines.length >= 2) {
                const parts = lines[1].trim().split(/\s+/)
                const used  = parseInt(parts[0])
                const total = parseInt(parts[1])
                root.diskUsedGb  = used  / (1024 * 1024 * 1024)
                root.diskTotalGb = total / (1024 * 1024 * 1024)
                root.diskUsage   = total > 0 ? used / total : 0
            }
            diskProc.buffer = ""
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root._refCount > 0
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    // --- Uptime ---
    function getUptime() {
        uptimeProc.running = true
        return uptime
    }

    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //' | sed 's/ hours*/h/' | sed 's/ minutes*/m/' | sed 's/,//g'"]

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => uptimeProc.buffer = data
        }

        onExited: root.uptime = uptimeProc.buffer
    }
}
