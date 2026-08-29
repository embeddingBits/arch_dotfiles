import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "battery"
    tile: WidgetSizes.small
    defaultPos: Qt.point(600, 200)

    readonly property real pct: ServiceUPower.powerLevel
    readonly property bool charging: ServiceUPower.isCharging
    readonly property color levelColor: {
        if (pct < 0.15) return Qt.color(Colors.error)
        if (pct < 0.30) return Qt.color(Colors.tertiary)
        return Qt.color(Colors.primary)
    }

    // ── Card + wavy fill ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        Canvas {
            id: waveCanvas
            anchors.fill: parent
            antialiasing: true

            // Smooth fill level transition
            property real smoothPct: 0
            Behavior on smoothPct {
                id: smoothBehavior
                enabled: false
                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
            }

            // Wave animation phase
            property real phase: 0

            // Colors as properties so they're accessible inside onPaint
            property color fillColor: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.15)
            property color crestColor: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.38)

            Component.onCompleted: {
                smoothPct = root.pct       // instant — behavior is off
                smoothBehavior.enabled = true  // animate all future changes
            }

            Connections {
                target: root
                function onPctChanged() { waveCanvas.smoothPct = root.pct }
            }

            // 60 fps wave animation — phase grows unboundedly so Math.sin()
            // stays continuous with no wrap-around snap
            // Keeps running at 100% too — otherwise a full battery renders as a
            // dead flat wash with no crest, which is what made the card look grey.
            Timer {
                interval: 16
                repeat: true
                running: !root.preview   // gallery previews don't need 60fps
                onTriggered: {
                    waveCanvas.phase += 0.02
                    waveCanvas.requestPaint()
                }
            }

            onSmoothPctChanged: requestPaint()
            onFillColorChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (smoothPct <= 0) return

                // Item.clip only clips to the bounding box, ignoring radius, so the
                // wave has to clip itself to the card's rounded outline.
                const r = WidgetSizes.radius
                ctx.save()
                ctx.beginPath()
                ctx.moveTo(r, 0)
                ctx.lineTo(width - r, 0)
                ctx.arcTo(width, 0, width, r, r)
                ctx.lineTo(width, height - r)
                ctx.arcTo(width, height, width - r, height, r)
                ctx.lineTo(r, height)
                ctx.arcTo(0, height, 0, height - r, r)
                ctx.lineTo(0, r)
                ctx.arcTo(0, 0, r, 0, r)
                ctx.closePath()
                ctx.clip()

                const amp   = 7   // wave amplitude px
                const freq1 = Math.PI * 4 / width   // ~2 full waves
                const freq2 = Math.PI * 7 / width   // secondary harmonic

                // Peak deflection of the two summed harmonics
                const maxAmp = amp * 1.4

                // Travel is extended by maxAmp past both edges: otherwise at 100%
                // the waterline sits exactly on y=0 and the troughs leave unfilled
                // notches along the top edge.
                const fillY = (height + maxAmp * 2) * (1 - smoothPct) - maxAmp

                // Build the wave path
                const wavePath = (offsetY) => {
                    ctx.moveTo(0, height)
                    ctx.lineTo(0, fillY + amp * Math.sin(phase) + offsetY)
                    for (let x = 1; x <= width; x++) {
                        const y = fillY + offsetY
                            + amp       * Math.sin(freq1 * x + phase)
                            + amp * 0.4 * Math.sin(freq2 * x - phase * 1.7)
                        ctx.lineTo(x, y)
                    }
                    ctx.lineTo(width, height)
                    ctx.closePath()
                }

                // Main fill body
                ctx.beginPath()
                wavePath(0)
                ctx.fillStyle = fillColor
                ctx.fill()

                // Bright crest line on top of the wave
                ctx.beginPath()
                ctx.moveTo(0, fillY + amp * Math.sin(phase))
                for (let x = 1; x <= width; x++) {
                    const y = fillY
                        + amp       * Math.sin(freq1 * x + phase)
                        + amp * 0.4 * Math.sin(freq2 * x - phase * 1.7)
                    ctx.lineTo(x, y)
                }
                ctx.strokeStyle = crestColor
                ctx.lineWidth = 1.5
                ctx.lineJoin = "round"
                ctx.stroke()

                ctx.restore()
            }
        }
    }

    // ── Battery icon — top-left ───────────────────────────────────────
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 22
        anchors.leftMargin: 22
        implicitWidth: 44
        implicitHeight: 44

        MaterialShapes.ShapeCanvas {
            anchors.fill: parent
            roundedPolygon: MaterialShapeFn.getCookie6Sided()
            color: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.28)
        }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: root.charging ? "bolt" : (
                root.pct < 0.15 ? "battery_alert" :
                root.pct < 0.35 ? "battery_2_bar" :
                root.pct < 0.55 ? "battery_3_bar" :
                root.pct < 0.75 ? "battery_5_bar" : "battery_full"
            )
            iconSize: 22
            customColor: root.levelColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.charging
                NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Health — top-right, aligned to the icon's centre ──────────────
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 36
        anchors.rightMargin: 22
        spacing: 5

        MaterialIconSymbol {
            content: "favorite"
            iconSize: 13
            customColor: ServiceUPower.health > 0.8 ? Colors.primary : Colors.error
        }

        CustomText {
            content: Math.round(ServiceUPower.health * 100) + "%"
            size: 13
            customColor: Colors.outline
        }
    }

    // ── Hero: percentage + status — bottom-left ───────────────────────
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 20
        anchors.leftMargin: 22
        spacing: 0

        CustomText {
            content: Math.round(root.pct * 100) + "%"
            size: 46
            weight: 400
            customColor: root.levelColor
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
        }

        CustomText {
            content: root.charging
                ? (ServiceUPower.timeToFull.length > 0 ? ServiceUPower.timeToFull : "Charging")
                : "On Battery"
            size: 13
            customColor: Colors.outline
        }
    }
}
