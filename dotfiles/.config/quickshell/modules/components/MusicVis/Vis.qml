import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

PanelWindow {
    id: panelWindow
    implicitHeight: 200
    visible: true
    color: "transparent"
    WlrLayershell.namespace: "quickshell:musicVis"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property string visStyle: SettingsConfig.general.musicVisStyle ?? "Wave"
    readonly property string visColor: SettingsConfig.general.musicVisColor ?? "Primary"

    readonly property color barColor: {
        switch (panelWindow.visColor) {
        case "Secondary": return Colors.secondary
        case "Tertiary":  return Colors.tertiary
        case "Deep":      return Colors.primaryContainer
        case "Warm":      return Colors.error
        default:          return Colors.primary
        }
    }

    readonly property color ghostColor: {
        switch (panelWindow.visColor) {
        case "Secondary": return Qt.alpha(Colors.secondary, 0.3)
        case "Tertiary":  return Qt.alpha(Colors.tertiary, 0.3)
        case "Two-tone":  return Qt.alpha(Colors.tertiary, 0.45)
        case "Deep":      return Qt.alpha(Colors.primary, 0.5)
        case "Warm":      return Qt.alpha(Colors.error, 0.3)
        default:          return Qt.alpha(Colors.primary, 0.3)
        }
    }

    // Activate cava when music visualizer is visible
    Component.onCompleted: ServiceCava.retain()
    Component.onDestruction: ServiceCava.release()

    mask: Region{
        item: maskRect
        intersection: Intersection.Xor;
    }

    Rectangle{
        id: maskRect
        anchors.fill: parent
        color: "transparent"
    }

    TrapezoidChart {
        anchors.fill: parent
        visible: panelWindow.visStyle === "Chart"

        values: visible ? ServiceCava.cavaData : []
        lo: 0
        hi: 1

        backValues: visible ? ServiceCava.cavaData : []
        backMax: 0.88
        backColor: panelWindow.ghostColor

        showAxis: false
        gridLabelWidth: 0
        labelHeight: 0
        bottomOffset: 0
        tickHeight: 0
        barColor: panelWindow.barColor
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: panelWindow.visStyle === "Wave"

        Connections {
            target: ServiceCava
            enabled: canvas.visible
            function onCavaDataChanged() { canvas.requestPaint() }
        }

        Connections {
            target: panelWindow
            enabled: canvas.visible
            function onBarColorChanged() { canvas.requestPaint() }
            function onGhostColorChanged() { canvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext('2d')
            ctx.clearRect(0, 0, width, height)
            drawMountainWave(ctx, ServiceCava.cavaData, true)
            drawMountainWave(ctx, ServiceCava.cavaData, false)
        }

        function drawMountainWave(ctx, data, isShadow) {
            if (data.length < 2) return

            ctx.beginPath()

            if (isShadow) {
                ctx.save()
                ctx.translate(0, -10)
                ctx.scale(1.02, 1.05)
                ctx.fillStyle = panelWindow.ghostColor
            } else {
                ctx.fillStyle = panelWindow.barColor
            }

            ctx.moveTo(0, height)
            var startY = height - (data[0] * height)
            ctx.lineTo(0, startY)

            var barWidth = width / (data.length - 1)

            for (var i = 0; i < data.length - 1; i++) {
                var xCurr = i * barWidth
                var yCurr = height - (data[i] * height)
                var xNext = (i + 1) * barWidth
                var yNext = height - (data[i + 1] * height)
                var xMid = (xCurr + xNext) / 2
                var yMid = (yCurr + yNext) / 2
                ctx.quadraticCurveTo(xCurr, yCurr, xMid, yMid)
            }

            var lastX = (data.length - 1) * barWidth
            var lastY = height - (data[data.length - 1] * height)
            ctx.lineTo(lastX, lastY)
            ctx.lineTo(width, height)
            ctx.closePath()
            ctx.fill()

            if (isShadow) ctx.restore()
        }
    }
}
