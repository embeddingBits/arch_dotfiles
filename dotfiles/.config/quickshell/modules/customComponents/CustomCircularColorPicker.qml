import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import Quickshell.Wayland
import Quickshell.Hyprland

PopupWindow {
    id: root
    implicitWidth: 280
    implicitHeight: 370
    color: "transparent"
    visible: true

    signal close
    signal colorsChanged(color first, color second, color third)

    anchor {
        window: panelWindow
        rect.x: root.width / 2 + 110
        rect.y: root.height / 2
    }

    HyprlandFocusGrab {
        active: true
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    property color firstColor: "#833ab4"
    property color secondColor: "#fd1d1d"
    property color thirdColor: "#fcb045"

    readonly property real wheelDiameter: 240
    readonly property real wheelRadius: wheelDiameter / 2

    function hsvToRgb(h, s, v) {
        var r, g, b
        var i = Math.floor(h * 6)
        var f = h * 6 - i
        var p = v * (1 - s)
        var q = v * (1 - f * s)
        var t = v * (1 - (1 - f) * s)
        switch (i % 6) {
            case 0: r = v; g = t; b = p; break
            case 1: r = q; g = v; b = p; break
            case 2: r = p; g = v; b = t; break
            case 3: r = p; g = q; b = v; break
            case 4: r = t; g = p; b = v; break
            case 5: r = v; g = p; b = q; break
        }
        return Qt.rgba(r, g, b, 1.0)
    }

    function colorFromPolar(angle, dist, maxDist) {
        var hue = ((angle + 90) % 360 + 360) % 360 / 360
        var sat = Math.max(0, Math.min(dist / maxDist, 1.0))
        return hsvToRgb(hue, sat, 1.0)
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Colors.surface
            radius: 12
            border.color: Colors.outline
            border.width: 1
        }

        // ── Color Previews (anchored, no ColumnLayout) ──────────
        Row {
            id: previewRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 14
            height: 24
            spacing: 6

            Rectangle { width: 24; height: 24; radius: 6; color: root.firstColor }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.firstColor.toString().toUpperCase()
                size: 10
            }

            Item { width: 8; height: 1 }

            Rectangle { width: 24; height: 24; radius: 6; color: root.secondColor }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.secondColor.toString().toUpperCase()
                size: 10
            }

            Item { width: 8; height: 1 }

            Rectangle { width: 24; height: 24; radius: 6; color: root.thirdColor }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.thirdColor.toString().toUpperCase()
                size: 10
            }
        }

        Rectangle {
            id: divider
            anchors.top: previewRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 10
            height: 1
            color: Colors.outline
        }

        // ── Wheel area ──────────────────────────────────────────
        Item {
            id: wheelContainer
            anchors.top: divider.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 10

            property real cx: width / 2
            property real cy: height / 2

            Canvas {
                id: colorWheel
                width: root.wheelDiameter
                height: root.wheelDiameter
                anchors.centerIn: parent

                property bool painted: false

                onPaint: {
                    if (painted) return
                    painted = true

                    var ctx = getContext('2d')
                    var cx = width / 2
                    var cy = height / 2
                    var r = width / 2

                    ctx.clearRect(0, 0, width, height)

                    ctx.save()
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.clip()

                    var steps = 120
                    var step = (2 * Math.PI) / steps
                    var overlap = step * 0.8

                    for (var i = 0; i < steps; i++) {
                        var a0 = i * step - Math.PI / 2
                        var a1 = a0 + step + overlap
                        var hue = i / steps

                        var c = root.hsvToRgb(hue, 1.0, 1.0)
                        var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
                        grad.addColorStop(0, "white")
                        grad.addColorStop(1, c.toString())

                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.arc(cx, cy, r, a0, a1)
                        ctx.closePath()
                        ctx.fillStyle = grad
                        ctx.fill()
                    }

                    ctx.restore()
                }

                Component.onCompleted: requestPaint()
            }

            MouseArea {
                anchors.fill: parent
                property int activeMarker: -1

                function closestMarker(mx, my) {
                    var markers = [marker1, marker2, marker3]
                    var best = -1
                    var bestDist = 30
                    for (var i = 0; i < 3; i++) {
                        var mcx = markers[i].x + markers[i].width / 2
                        var mcy = markers[i].y + markers[i].height / 2
                        var d = Math.sqrt((mx - mcx) * (mx - mcx) + (my - mcy) * (my - mcy))
                        if (d < bestDist) {
                            bestDist = d
                            best = i
                        }
                    }
                    return best
                }

                function updateMarker(idx, mx, my) {
                    var dx = mx - wheelContainer.cx
                    var dy = my - wheelContainer.cy
                    var dist = Math.sqrt(dx * dx + dy * dy)
                    var angle = Math.atan2(dy, dx) * 180 / Math.PI

                    dist = Math.min(dist, root.wheelRadius)

                    var markers = [marker1, marker2, marker3]
                    markers[idx].angle = angle
                    markers[idx].distance = dist
                }

                onPressed: function(mouse) {
                    activeMarker = closestMarker(mouse.x, mouse.y)
                    if (activeMarker >= 0)
                        updateMarker(activeMarker, mouse.x, mouse.y)
                }

                onPositionChanged: function(mouse) {
                    if (activeMarker >= 0)
                        updateMarker(activeMarker, mouse.x, mouse.y)
                }

                onReleased: activeMarker = -1
            }

            component ColorMarker: Rectangle {
                width: 26
                height: 26
                radius: 13
                border.color: Colors.inverseSurface
                border.width: 3
                z: 10

                property real angle: 0
                property real distance: root.wheelRadius * 0.65

                x: wheelContainer.cx + Math.cos(angle * Math.PI / 180) * distance - width / 2
                y: wheelContainer.cy + Math.sin(angle * Math.PI / 180) * distance - height / 2

                color: root.colorFromPolar(angle, distance, root.wheelRadius)

                onAngleChanged: emitColors()
                onDistanceChanged: emitColors()

                function emitColors() {
                    if (!marker1 || !marker2 || !marker3) return
                    root.firstColor = root.colorFromPolar(marker1.angle, marker1.distance, root.wheelRadius)
                    root.secondColor = root.colorFromPolar(marker2.angle, marker2.distance, root.wheelRadius)
                    root.thirdColor = root.colorFromPolar(marker3.angle, marker3.distance, root.wheelRadius)
                    root.colorsChanged(root.firstColor, root.secondColor, root.thirdColor)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.8)
                }
            }

            ColorMarker {
                id: marker1
                angle: -90
            }

            ColorMarker {
                id: marker2
                angle: 30
            }

            ColorMarker {
                id: marker3
                angle: 150
            }
        }
    }
}
