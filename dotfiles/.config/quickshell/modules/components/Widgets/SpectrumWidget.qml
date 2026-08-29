import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Radial audio spectrum. Deliberately not the bottom-edge bar look the music
// visualizer already has — bars radiate from a centre disc so the tile reads
// as its own object rather than a cropped strip of the overlay.
WidgetHost {
    id: root
    configKey: "spectrum"
    tile: WidgetSizes.small
    defaultPos: Qt.point(420, 620)

    // Cava is refcounted, so a hidden tile costs nothing. Previews must never
    // start the process — the settings gallery would spawn one per thumbnail.
    Component.onCompleted: if (!root.preview) ServiceCava.retain()
    Component.onDestruction: if (!root.preview) ServiceCava.release()

    // A standing wave for the gallery, so the preview isn't an empty ring
    readonly property var previewData: {
        const out = []
        for (let i = 0; i < 60; i++)
            out.push(0.25 + 0.55 * Math.abs(Math.sin(i / 60 * Math.PI * 3)))
        return out
    }

    readonly property var bars: root.preview ? root.previewData : ServiceCava.cavaData

    // ── Card ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            // Mirrored so a theme change repaints
            property color lowColor:  Colors.primary
            property color highColor: Colors.tertiary
            property color idleColor: Colors.outlineVariant
            property var   data:      root.bars

            onLowColorChanged:  requestPaint()
            onHighColorChanged: requestPaint()
            onIdleColorChanged: requestPaint()
            onDataChanged:      requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2
                const cy = height / 2
                const r0 = 40          // inner radius — edge of the centre disc
                const maxLen = 42      // fully-saturated bar length

                const d = canvas.data ?? []
                const n = d.length

                ctx.lineCap = "round"
                ctx.lineWidth = 3

                if (n === 0) {
                    // Idle: a dotted ring, so the tile still reads as a widget
                    ctx.strokeStyle = idleColor
                    ctx.globalAlpha = 0.5
                    for (let i = 0; i < 60; i++) {
                        const a = (i / 60) * Math.PI * 2 - Math.PI / 2
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0)
                        ctx.lineTo(cx + Math.cos(a) * (r0 + 3), cy + Math.sin(a) * (r0 + 3))
                        ctx.stroke()
                    }
                    ctx.globalAlpha = 1
                    return
                }

                for (let i = 0; i < n; i++) {
                    const amp = Math.max(0, Math.min(1, d[i]))
                    const a = (i / n) * Math.PI * 2 - Math.PI / 2
                    const len = 3 + amp * maxLen

                    // Loud bars shift toward the accent colour, so peaks read
                    // without needing a separate peak indicator
                    ctx.strokeStyle = Qt.rgba(
                        lowColor.r + (highColor.r - lowColor.r) * amp,
                        lowColor.g + (highColor.g - lowColor.g) * amp,
                        lowColor.b + (highColor.b - lowColor.b) * amp,
                        1)

                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0)
                    ctx.lineTo(cx + Math.cos(a) * (r0 + len), cy + Math.sin(a) * (r0 + len))
                    ctx.stroke()
                }
            }
        }

        // ── Centre disc ───────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 66; height: 66
            radius: width / 2
            color: Colors.surfaceContainerHigh

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: ServiceMusic.isPlaying ? "graphic_eq" : "music_off"
                iconSize: 24
                customColor: ServiceMusic.isPlaying ? Colors.primary : Colors.outline
            }

            // Breathes only while something is actually playing
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !root.preview && ServiceMusic.isPlaying
                NumberAnimation { from: 1;    to: 1.05; duration: 900; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.05; to: 1;    duration: 900; easing.type: Easing.InOutQuad }
            }
        }
    }
}
