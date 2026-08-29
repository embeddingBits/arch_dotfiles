import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "sunArc"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(100, 620)

    // ── Sun math ──────────────────────────────────────────────────────
    // wttr.in reports 12-hour times ("06:34 AM") — same shape ServiceWeather
    // .isNightTime() parses, kept local so this widget has no new service deps.
    function parseClock(str) {
        if (!str) return -1
        const m = String(str).match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i)
        if (!m) return -1
        let h = parseInt(m[1])
        const min = parseInt(m[2])
        const ap = m[3].toUpperCase()
        if (ap === "PM" && h !== 12) h += 12
        if (ap === "AM" && h === 12) h = 0
        return h * 60 + min
    }

    readonly property var astro: ServiceWeather.astronomy
    readonly property int sunriseMin: parseClock(astro?.sunrise ?? "")
    readonly property int sunsetMin:  parseClock(astro?.sunset  ?? "")
    readonly property bool hasData: sunriseMin >= 0 && sunsetMin > sunriseMin

    // ServiceClock.minute is the ticking dependency — re-evaluates once a minute
    readonly property int nowMin: {
        ServiceClock.minute
        const d = new Date()
        return d.getHours() * 60 + d.getMinutes()
    }

    readonly property bool isNight: !hasData || nowMin < sunriseMin || nowMin >= sunsetMin

    readonly property real progress: !hasData ? 0
        : Math.max(0, Math.min(1, (nowMin - sunriseMin) / (sunsetMin - sunriseMin)))

    function fmtDuration(mins) {
        const m = Math.max(0, Math.round(mins))
        const h = Math.floor(m / 60)
        return h > 0 ? h + "h " + (m % 60) + "m" : (m % 60) + "m"
    }

    readonly property string headline: {
        if (!hasData) return "—"
        if (nowMin < sunriseMin)  return fmtDuration(sunriseMin - nowMin)
        // Only today's astronomy is fetched, so the small hours use today's
        // sunrise + 24h — off by a minute or two at most.
        if (nowMin >= sunsetMin)  return fmtDuration(sunriseMin + 1440 - nowMin)
        return fmtDuration(sunsetMin - nowMin)
    }

    readonly property string caption: {
        if (!hasData) return "no sun data"
        if (isNight)  return "until sunrise"
        return "of daylight left"
    }

    readonly property string dayLength: hasData ? fmtDuration(sunsetMin - sunriseMin) : "—"

    // ── Arc geometry (shared by the canvas and the sun marker) ────────
    readonly property real arcCx: width / 2
    readonly property real arcCy: 150
    readonly property real arcR:  112
    readonly property real sunAngle: Math.PI * (1 + progress)

    // ── Card ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            // Mirrored here so a theme change repaints the arc
            property color accentColor: Colors.primary
            property color trackColor:  Colors.outlineVariant
            property color warmColor:   Colors.tertiary
            property real  prog:        root.progress
            property bool  night:       root.isNight

            onAccentColorChanged: requestPaint()
            onTrackColorChanged:  requestPaint()
            onWarmColorChanged:   requestPaint()
            onProgChanged:        requestPaint()
            onNightChanged:       requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = root.arcCx
                const cy = root.arcCy
                const r  = root.arcR

                ctx.lineCap = "round"

                // Horizon
                ctx.strokeStyle = trackColor
                ctx.lineWidth = 1
                ctx.globalAlpha = 0.5
                ctx.beginPath()
                ctx.moveTo(cx - r - 12, cy)
                ctx.lineTo(cx + r + 12, cy)
                ctx.stroke()
                ctx.globalAlpha = 1

                // Full daylight track
                ctx.strokeStyle = trackColor
                ctx.lineWidth = 3
                ctx.beginPath()
                ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI)
                ctx.stroke()

                // Golden-hour bands at each end
                ctx.strokeStyle = warmColor
                ctx.globalAlpha = 0.5
                ctx.beginPath()
                ctx.arc(cx, cy, r, Math.PI, Math.PI * 1.08)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, r, Math.PI * 1.92, Math.PI * 2)
                ctx.stroke()
                ctx.globalAlpha = 1

                // Elapsed daylight
                if (!night && prog > 0) {
                    ctx.strokeStyle = accentColor
                    ctx.lineWidth = 4
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, Math.PI, Math.PI * (1 + prog))
                    ctx.stroke()
                }
            }
        }

        // ── Sun marker ────────────────────────────────────────────────
        Item {
            id: sunMarker
            visible: root.hasData && !root.isNight
            width: 34; height: 34
            x: root.arcCx + root.arcR * Math.cos(root.sunAngle) - width / 2
            y: root.arcCy + root.arcR * Math.sin(root.sunAngle) - height / 2

            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            // Halo behind the sun, so it reads against the arc it sits on
            Rectangle {
                anchors.centerIn: parent
                width: 38; height: 38; radius: width / 2
                color: Qt.alpha(Colors.primary, 0.18)

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: sunMarker.visible
                    NumberAnimation { from: 1;    to: 1.2; duration: 1800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.2;  to: 1;   duration: 1800; easing.type: Easing.InOutQuad }
                }
            }

            // Same artwork the weather panel uses
            Image {
                anchors.fill: parent
                source: IconUtil.getSystemIcon("sunny")
                sourceSize.width: 68
                sourceSize.height: 68
                smooth: true
            }
        }

        // ── Top labels ────────────────────────────────────────────────
        CustomText {
            x: 22; y: 16
            content: root.isNight ? "Night" : "Daylight"
            size: 13
            customColor: Colors.primary
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 22
            y: 16
            spacing: 5

            MaterialIconSymbol {
                content: "wb_twilight"
                iconSize: 14
                customColor: Colors.outline
            }
            CustomText {
                content: root.dayLength
                size: 13
                customColor: Colors.outline
            }
        }

        // ── Centre readout ────────────────────────────────────────────
        ColumnLayout {
            width: root.width
            y: 76
            spacing: 0

            MaterialIconSymbol {
                Layout.alignment: Qt.AlignHCenter
                visible: root.isNight && root.hasData
                content: "dark_mode"
                iconSize: 18
                customColor: Colors.outline
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: root.headline
                size: 30
                weight: 700
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: root.caption
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Sunrise / sunset ──────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            y: 162

            ColumnLayout {
                spacing: 0
                RowLayout {
                    spacing: 5
                    MaterialIconSymbol { content: "wb_sunny"; iconSize: 13; customColor: Colors.outline }
                    CustomText { content: root.astro?.sunrise ?? "—"; size: 13 }
                }
                CustomText { content: "sunrise"; size: 11; customColor: Colors.outline }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 0
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 5
                    CustomText { content: root.astro?.sunset ?? "—"; size: 13 }
                    MaterialIconSymbol { content: "bedtime"; iconSize: 13; customColor: Colors.outline }
                }
                CustomText { Layout.alignment: Qt.AlignRight; content: "sunset"; size: 11; customColor: Colors.outline }
            }
        }
    }
}
