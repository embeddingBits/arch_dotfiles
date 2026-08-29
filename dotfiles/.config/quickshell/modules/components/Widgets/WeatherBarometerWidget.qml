import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Pressure on a 270° gauge. ServiceWeather already normalises the reading
// against its own 960–1060 hPa range, so this only has to draw it.
//
// A raw hPa number means nothing to most people, so the band label under it
// does the interpreting — that is the whole reason to show pressure at all.
WidgetHost {
    id: root
    configKey: "weatherBarometer"
    tile: WidgetSizes.small
    defaultPos: Qt.point(1000, 200)

    readonly property real value: ServiceWeather.currentPressure ?? 0
    readonly property real frac: Math.max(0, Math.min(1, ServiceWeather.pressure ?? 0))

    readonly property string band: {
        if (root.value <= 0) return "—"
        if (root.value < 1000) return "Low · unsettled"
        if (root.value < 1020) return "Fair"
        return "High · settled"
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        CustomText {
            x: 20; y: 14
            content: "Pressure"
            size: 13
            customColor: Colors.primary
        }

        Canvas {
            id: gauge
            anchors.fill: parent
            antialiasing: true

            property color trackColor: Colors.surfaceContainerHighest
            property color fillColor:  Colors.primary
            property real  f:          root.frac

            onTrackColorChanged: requestPaint()
            onFillColorChanged:  requestPaint()
            onFChanged:          requestPaint()

            // 270° sweep with the gap at the bottom, so the ends read as a
            // scale rather than a closed ring
            readonly property real startA: Math.PI * 0.75
            readonly property real sweep:  Math.PI * 1.5

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2
                const cy = height / 2 + 10
                const r = 60

                ctx.lineCap = "round"
                ctx.lineWidth = 9

                ctx.strokeStyle = gauge.trackColor
                ctx.beginPath()
                ctx.arc(cx, cy, r, gauge.startA, gauge.startA + gauge.sweep)
                ctx.stroke()

                if (gauge.f > 0) {
                    ctx.strokeStyle = gauge.fillColor
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, gauge.startA, gauge.startA + gauge.sweep * gauge.f)
                    ctx.stroke()
                }
            }
        }

        // Marker dot riding the arc end
        Rectangle {
            width: 13; height: 13; radius: 7
            color: Colors.surface
            border.width: 3
            border.color: Colors.primary
            visible: root.value > 0

            readonly property real ang: gauge.startA + gauge.sweep * root.frac
            x: parent.width / 2 + Math.cos(ang) * 60 - width / 2
            y: parent.height / 2 + 10 + Math.sin(ang) * 60 - height / 2

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 10
            spacing: -2

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 3

                CustomText {
                    content: root.value > 0 ? Math.round(root.value) : "—"
                    size: 30
                    weight: 700
                }
                CustomText {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6
                    content: "hPa"
                    size: 10
                    customColor: Colors.outline
                }
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: root.band
                size: 11
                customColor: Colors.primary
            }
        }
    }
}
