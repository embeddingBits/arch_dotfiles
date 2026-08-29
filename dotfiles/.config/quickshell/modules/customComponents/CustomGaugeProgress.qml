import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Item {
    id: root
    property bool showData: true
    property real progress: 0.0
    property real thickness: 4
    property real radius: Math.min(width, height) / 2 - thickness
    property string baseColor: Colors.primaryText
    property string lineColor: Colors.primary
    property string icon: ""
    property real iconSize: 20
    property string iconColor: Colors.primary
    property real gap: 0.4

    property bool sperm: false
    property bool animateSperm: true
    property real spermAmplitudeMultiplier: sperm ? 0.5 : 0
    property real spermFrequency: 8
    property real spermFps: 60

    Behavior on spermAmplitudeMultiplier {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }

    Behavior on progress {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        // 270° arc, gap at bottom — starts bottom-left, ends bottom-right
        readonly property real startAngle: Math.PI * 0.75   // ~7:30 o'clock
        readonly property real totalSpan:  Math.PI * 1.5    // 270°
        readonly property real trackEnd:   startAngle + totalSpan
        readonly property real progressEnd: startAngle + totalSpan * root.progress

        onProgressEndChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const r = root.radius
            ctx.lineWidth = root.thickness
            ctx.lineCap = "round"

            // Background track (unfilled portion), offset by gap from progress tip
            const arcSpan = progressEnd - startAngle
            const effectiveGap = root.progress > 0 ? Math.min(root.gap, arcSpan * 0.5) : 0
            const bgStart = progressEnd + effectiveGap
            if (bgStart < trackEnd) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, bgStart, trackEnd, false)
                ctx.strokeStyle = root.baseColor
                ctx.stroke()
            }

            if (root.progress > 0) {
                // The gap belongs to the background track only — pushing bgStart
                // past the tip already creates it. Subtracting it here as well
                // shortened the progress arc by `gap`, so at 100% it stopped
                // short of the track end instead of closing the sweep.
                const end = progressEnd
                const amplitude = root.thickness * root.spermAmplitudeMultiplier

                if (amplitude > 0 && end > startAngle) {
                    const frequency = root.spermFrequency * root.progress
                    const phase = Date.now() / 400.0
                    const steps = Math.max(1, Math.round(Math.abs(end - startAngle) / 0.02))

                    ctx.beginPath()
                    for (let i = 0; i <= steps; i++) {
                        const angle = startAngle + (end - startAngle) * i / steps
                        const waveR = r + amplitude * Math.sin(frequency * 2 * Math.PI * i / steps + phase)
                        const x = cx + waveR * Math.cos(angle)
                        const y = cy + waveR * Math.sin(angle)
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = root.lineColor
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, end, false)
                    ctx.strokeStyle = root.lineColor
                    ctx.stroke()
                }
            }
        }

        Timer {
            interval: 1000 / root.spermFps
            running: root.animateSperm
            repeat: root.sperm
            onTriggered: canvas.requestPaint()
        }
    }

    Loader{
        active: root.showData
        visible: active
        anchors.centerIn: parent
        sourceComponent: ColumnLayout{
            anchors.centerIn: parent
            MaterialIconSymbol {
                Layout.alignment: Qt.AlignCenter
                content: root.icon
                iconSize: root.iconSize
                color: root.iconColor
            }
            CustomText{
                Layout.alignment: Qt.AlignCenter
                content: Math.round(root.progress * 100) + "%"
                size: 18
                color: Colors.primary
            }

            CustomText{
                Layout.alignment: Qt.AlignCenter
                content: "Used"
                size: 14
            }
        }
    }
}
