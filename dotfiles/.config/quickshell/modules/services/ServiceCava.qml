pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    // Full bar array matching SettingsConfig.general.musicVisBars, values 0.0–1.0
    property var cavaData: []

    // Averaged down to exactly 12 groups — one per cookie12 star tip
    property var cavaData12: []

    readonly property real attackAt30: 0.6
    readonly property real decayAt30: 0.15

    readonly property real attackFactor: 1 - Math.pow(1 - root.attackAt30, 30 / root.fps)
    readonly property real decayFactor:  1 - Math.pow(1 - root.decayAt30,  30 / root.fps)

    readonly property int bars: {
        const n = parseInt(SettingsConfig.general?.musicVisBars ?? 60)
        return (isNaN(n) || n <= 0) ? 60 : Math.max(8, Math.min(256, n))
    }

    readonly property int fps: {
        const n = parseInt(SettingsConfig.general?.musicVisFps ?? "30")
        return (isNaN(n) || n <= 0) ? 30 : Math.max(10, Math.min(144, n))
    }

    property int _refCount: 0

    property bool _restarting: false

    onBarsChanged: root._restart()
    onFpsChanged: root._restart()

    function _restart() {
        if (root._refCount <= 0) return
        root._restarting = true
        restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 80
        onTriggered: root._restarting = false
    }

    function retain() {
        _refCount++
    }

    function release() {
        if (_refCount > 0) _refCount--
        if (_refCount === 0) {
            cavaData = []
            cavaData12 = []
        }
    }

    Process {
        id: cavaProc
        running: root._refCount > 0 && !root._restarting
        command: ["sh", "-c", `
cava -p /dev/stdin <<'CAVAEOF'
[general]
bars = ${root.bars}
framerate = ${root.fps}
autosens = 1

[input]
method = pulse

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59

[smoothing]
monstercat = 1.5
waves = 0
gravity = 100
noise_reduction = 0.20

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
CAVAEOF
        `]

        stdout: SplitParser {
            onRead: data => {
                const newPoints = data.split(";")
                    .map(p => parseFloat(p.trim()) / 1000)
                    .filter(p => !isNaN(p))

                if (newPoints.length === 0) return

                // Smooth or initialise the full array
                let smoothed
                if (root.cavaData.length !== newPoints.length) {
                    smoothed = newPoints
                } else {
                    smoothed = []
                    for (let i = 0; i < newPoints.length; i++) {
                        const prev = root.cavaData[i]
                        const next = newPoints[i]
                        const k = next > prev ? root.attackFactor : root.decayFactor
                        smoothed.push(prev + (next - prev) * k)
                    }
                }
                root.cavaData = smoothed

                // Average into 12 groups for the cookie12 star tips
                const n = smoothed.length
                const grouped = []
                for (let g = 0; g < 12; g++) {
                    const start = Math.floor(g * n / 12)
                    const end   = Math.floor((g + 1) * n / 12)
                    let sum = 0
                    for (let j = start; j < end; j++) sum += smoothed[j]
                    grouped.push(end > start ? sum / (end - start) : 0)
                }
                root.cavaData12 = grouped
            }
        }
    }
}
