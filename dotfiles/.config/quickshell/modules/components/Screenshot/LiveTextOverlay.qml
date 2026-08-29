pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import qs.modules.utils

Scope {
    id: scope

    GlobalShortcut {
        name: "ocr"
        description: "Live Text — highlight text on screen and click to copy"
        onPressed: {
            if (GlobalStates.liveTextOpen) return
            var mon = Hyprland.focusedMonitor
            if (!mon) return
            ServiceTools.startLiveText(mon.name)
        }
    }

    Connections {
        target: ServiceTools
        function onOcrCaptureReady(path) {
            GlobalStates.liveTextOpen = true
        }
    }

    Loader {
        active: GlobalStates.liveTextOpen
        visible: active

        sourceComponent: PanelWindow {
            id: overlay

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            WlrLayershell.namespace:     "quickshell:livetext"
            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode:               ExclusionMode.Ignore

            readonly property var  lines:    ServiceTools.ocrLines
            readonly property bool scanning: ServiceTools.ocrScanning

            readonly property real scaleF:
                (frozen.status === Image.Ready && frozen.width > 0)
                    ? frozen.sourceSize.width / frozen.width : 1

            onLinesChanged: hoveredIdx = lineAt(curX, curY)

            property real startX: 0; property real startY: 0
            property real curX:   0; property real curY:   0
            property bool dragging: false
            property int  hoveredIdx: -1

            readonly property real selX: Math.min(startX, curX)
            readonly property real selY: Math.min(startY, curY)
            readonly property real selW: Math.abs(curX - startX)
            readonly property real selH: Math.abs(curY - startY)

            readonly property bool isDragSelecting: dragging && (selW > 3 || selH > 3)

            function boxOf(line) {
                return Qt.rect(line.x / scaleF, line.y / scaleF,
                               line.w / scaleF, line.h / scaleF)
            }

            function lineAt(mx, my) {
                for (var i = lines.length - 1; i >= 0; i--) {
                    var b = boxOf(lines[i])
                    if (mx >= b.x && mx < b.x + b.width &&
                        my >= b.y && my < b.y + b.height) return i
                }
                return -1
            }

            function isInSelection(i) {
                if (!isDragSelecting) return false
                var b = boxOf(lines[i])
                return b.x < selX + selW && b.x + b.width  > selX &&
                       b.y < selY + selH && b.y + b.height > selY
            }

            function selectedText() {
                var parts = []
                for (var i = 0; i < lines.length; i++)
                    if (isInSelection(i)) parts.push(lines[i].text)
                return parts.join("\n")
            }

            function close() {
                GlobalStates.liveTextOpen = false
                ServiceTools.clearScan()
            }

            Item {
                id: rootItem
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: overlay.close()

                Image {
                    id: frozen
                    anchors.fill: parent
                    fillMode: Image.Stretch
                    cache: false
                    asynchronous: false
                    source: ServiceTools.ocrImage !== ""
                        ? "file://" + ServiceTools.ocrImage : ""
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#59000000"
                }

                Repeater {
                    model: overlay.lines

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property rect b: overlay.boxOf(modelData)
                        readonly property bool picked: overlay.isInSelection(index)
                        readonly property bool hot:
                            picked || (!overlay.isDragSelecting && overlay.hoveredIdx === index)

                        x: b.x - 3; y: b.y - 2
                        width:  b.width  + 6
                        height: b.height + 4
                        radius: 4

                        color: hot ? Qt.alpha(Colors.primary, 0.34)
                                   : Qt.alpha(Colors.primary, 0.10)
                        border.color: hot ? Colors.primary
                                          : Qt.alpha(Colors.primary, 0.45)
                        border.width: hot ? 1.5 : 1

                        opacity: 0
                        Component.onCompleted: opacity = 1
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on color       { ColorAnimation  { duration: 90 } }
                        Behavior on border.color{ ColorAnimation  { duration: 90 } }
                    }
                }

                Rectangle {
                    visible: overlay.isDragSelecting
                    x: overlay.selX; y: overlay.selY
                    width: overlay.selW; height: overlay.selH
                    color: Qt.alpha(Colors.primary, 0.08)
                    border.color: Colors.primary
                    border.width: 1
                    radius: 3
                }

                Rectangle {
                    visible: overlay.scanning
                    anchors.centerIn: parent
                    width: scanRow.implicitWidth + 32
                    height: 56
                    radius: 20
                    color: Colors.surfaceContainer

                    Row {
                        id: scanRow
                        anchors.centerIn: parent
                        spacing: 12

                        CustomCircularLoader {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 24
                            trackWidth: 3
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: "Looking for text…"
                            size: 12; weight: 600; color: Colors.surfaceText
                        }
                    }
                }

                Rectangle {
                    id: hintPill
                    visible: !overlay.scanning && !overlay.dragging

                    readonly property real offsetX: 18
                    readonly property real offsetY: 18
                    width: hintRow.implicitWidth + 22; height: 34
                    radius: 13
                    color: Colors.surfaceContainer

                    x: {
                        var bx = overlay.curX + offsetX
                        return (bx + width > overlay.width - 8) ? overlay.curX - width - offsetX : bx
                    }
                    y: {
                        var by = overlay.curY + offsetY
                        return (by + height > overlay.height - 8) ? overlay.curY - height - offsetY : by
                    }

                    Row {
                        id: hintRow
                        anchors.centerIn: parent
                        spacing: 7

                        MaterialIconSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            content: overlay.hoveredIdx >= 0 ? "content_copy" : "text_select_start"
                            iconSize: 14
                            color: Colors.primary
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: {
                                if (overlay.hoveredIdx >= 0) return "Click to copy"
                                if (overlay.lines.length === 0) return "No text found — drag to OCR a region"
                                return overlay.lines.length + " lines — drag to select"
                            }
                            size: 11; weight: 700; color: Colors.surfaceText
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: overlay.hoveredIdx >= 0 ? Qt.PointingHandCursor : Qt.CrossCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPositionChanged: mouse => {
                        overlay.curX = mouse.x
                        overlay.curY = mouse.y
                        if (!overlay.dragging)
                            overlay.hoveredIdx = overlay.lineAt(mouse.x, mouse.y)
                    }

                    onPressed: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            overlay.close()
                            return
                        }
                        overlay.startX   = mouse.x
                        overlay.startY   = mouse.y
                        overlay.curX     = mouse.x
                        overlay.curY     = mouse.y
                        overlay.dragging = true
                    }

                    onReleased: mouse => {
                        if (mouse.button !== Qt.LeftButton) return
                        if (!overlay.dragging) return
                        overlay.dragging = false

                        if (overlay.selW <= 3 && overlay.selH <= 3) {
                            var idx = overlay.lineAt(mouse.x, mouse.y)
                            if (idx < 0) return
                            var t = overlay.lines[idx].text
                            overlay.close()
                            ServiceTools.copyText(t)
                            return
                        }

                        var text = overlay.selectedText()
                        if (text.trim() !== "") {
                            overlay.close()
                            ServiceTools.copyText(text)
                            return
                        }

                        var gx = Math.round(overlay.selX) + overlay.screen.x
                        var gy = Math.round(overlay.selY) + overlay.screen.y
                        var geo = gx + "," + gy + " " +
                                  Math.round(overlay.selW) + "x" + Math.round(overlay.selH)
                        if (overlay.selW < 5 || overlay.selH < 5) return
                        overlay.close()
                        ServiceTools.ocrArea(geo)
                    }
                }
            }
        }
    }
}
