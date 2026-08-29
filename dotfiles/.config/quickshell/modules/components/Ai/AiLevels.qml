pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.settings

Item {
    id: root

    property bool active: false
    property int bars: 28

    property var levels: []

    readonly property real peak: {
        if (levels.length === 0) return 0
        let m = 0
        for (let i = 0; i < levels.length; i++) m = Math.max(m, levels[i])
        return m
    }

    readonly property real smoothFactor: 0.35

    onActiveChanged: if (!active) levels = []

    Process {
        id: cavaProc
        running: root.active

        environment: ({
            QS_AI_SOURCE: SettingsConfig.ai?.source ?? ""
        })

        command: ["sh", "-c", `
SRC="$QS_AI_SOURCE"
if [ -z "$SRC" ]; then SRC="$(pactl get-default-source 2>/dev/null)"; fi

cava -p /dev/stdin <<CAVAEOF
[general]
bars = ${root.bars}
framerate = 30
autosens = 1

[input]
method = pulse
source = $SRC

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
noise_reduction = 0.25
CAVAEOF
        `]

        stdout: SplitParser {
            onRead: data => {
                const next = String(data).split(";")
                    .map(p => parseFloat(p.trim()) / 1000)
                    .filter(p => !isNaN(p))

                if (next.length === 0) return

                if (root.levels.length !== next.length) {
                    root.levels = next
                    return
                }

                const smoothed = []
                for (let i = 0; i < next.length; i++)
                    smoothed.push(root.levels[i] + (next[i] - root.levels[i]) * root.smoothFactor)
                root.levels = smoothed
            }
        }
    }
}
