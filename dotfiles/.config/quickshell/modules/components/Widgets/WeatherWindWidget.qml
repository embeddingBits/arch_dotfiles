import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Wind as a compass rather than a number.
//
// The arrow points the way meteorologists quote wind — at the direction it
// blows FROM — which is why the caption says "from" rather than leaving the
// reader to guess the convention.
WidgetHost {
    id: root
    configKey: "weatherWind"
    tile: WidgetSizes.small
    defaultPos: Qt.point(760, 200)

    readonly property real degree: ServiceWeather.windDegree ?? 0
    readonly property string dir: ServiceWeather.windDirection ?? "—"

    // ServiceWeather hands back "12 km/h"; the number and unit want different
    // sizes, so they get split apart here.
    readonly property var speedParts: String(ServiceWeather.windSpeed ?? "").split(" ")
    readonly property string speedNum: root.speedParts[0] ?? "—"
    readonly property string speedUnit: root.speedParts.slice(1).join(" ")

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        CustomText {
            x: 20; y: 14
            content: "Wind"
            size: 13
            customColor: Colors.primary
        }

        // ── Compass rose ──────────────────────────────────────────────
        Canvas {
            id: rose
            anchors.fill: parent
            antialiasing: true

            property color tickColor: Colors.outlineVariant
            property color cardinalColor: Colors.outline

            onTickColorChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2
                const cy = height / 2 + 8
                const r = 66

                ctx.lineCap = "round"

                // 16 ticks; the four cardinals are longer and brighter
                for (var i = 0; i < 16; i++) {
                    const a = (i / 16) * Math.PI * 2 - Math.PI / 2
                    const cardinal = i % 4 === 0
                    const inner = cardinal ? r - 9 : r - 5
                    ctx.strokeStyle = cardinal ? rose.cardinalColor : rose.tickColor
                    ctx.lineWidth = cardinal ? 2 : 1
                    ctx.globalAlpha = cardinal ? 0.9 : 0.5
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                    ctx.lineTo(cx + Math.cos(a) * r,     cy + Math.sin(a) * r)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1
            }
        }

        // N marker, so the rose has an orientation without four letters of clutter
        CustomText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + 8 - 66 - 16
            content: "N"
            size: 10
            weight: 700
            customColor: Colors.outline
        }

        // ── Needle ────────────────────────────────────────────────────
        Item {
            id: needle
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 8
            width: 2; height: 2

            rotation: root.degree
            Behavior on rotation {
                RotationAnimation { duration: 700; direction: RotationAnimation.Shortest; easing.type: Easing.OutCubic }
            }

            // Points outward from the centre toward the origin direction
            Canvas {
                anchors.centerIn: parent
                width: 140; height: 140
                antialiasing: true

                property color c: Colors.primary
                onCChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2

                    // Arrow head at the top (rotation carries it round)
                    ctx.fillStyle = c
                    ctx.beginPath()
                    ctx.moveTo(cx, cy - 52)
                    ctx.lineTo(cx - 7, cy - 36)
                    ctx.lineTo(cx + 7, cy - 36)
                    ctx.closePath()
                    ctx.fill()

                    // Tail
                    ctx.strokeStyle = c
                    ctx.globalAlpha = 0.35
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(cx, cy - 34)
                    ctx.lineTo(cx, cy + 30)
                    ctx.stroke()
                }
            }
        }

        // ── Centre readout ────────────────────────────────────────────
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 8
            spacing: -4

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 3

                CustomText {
                    content: root.speedNum
                    size: 30
                    weight: 700
                }
                CustomText {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6
                    content: root.speedUnit
                    size: 10
                    customColor: Colors.outline
                }
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: "from " + root.dir
                size: 11
                customColor: Colors.primary
            }
        }
    }
}
