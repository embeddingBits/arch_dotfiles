pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import qs.modules.utils

Scope {
    id: scope

    Loader {
        active: GlobalStates.areaSelectOpen
        sourceComponent: PanelWindow {
            id: overlay

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            WlrLayershell.namespace: "quickshell:screenshot"
            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode:               ExclusionMode.Ignore

            // ── Mode flags ───────────────────────────────────────────────────
            readonly property bool isWindowMode:
                GlobalStates.areaSelectMode === "window-screenshot" ||
                GlobalStates.areaSelectMode === "window-recording"

            // ── Area-select state ────────────────────────────────────────────
            property real startX: 0; property real startY: 0
            property real curX:   0; property real curY:   0
            property bool dragging: false

            readonly property real selX: Math.min(startX, curX)
            readonly property real selY: Math.min(startY, curY)
            readonly property real selW: Math.abs(curX - startX)
            readonly property real selH: Math.abs(curY - startY)

            readonly property real geoX: Math.round(selX) + overlay.screen.x
            readonly property real geoY: Math.round(selY) + overlay.screen.y
            readonly property real geoW: Math.round(selW)
            readonly property real geoH: Math.round(selH)

            // ── Window-pick state ────────────────────────────────────────────
            property int hoveredIdx: -1

            readonly property var windowList: {
                var ws = Hyprland.focusedWorkspace
                if (!ws) return []
                var result = []
                var tls = ws.toplevels.values
                for (var i = 0; i < tls.length; i++) {
                    var t = tls[i]
                    var obj = t.lastIpcObject
                    if (!obj || !obj.mapped || obj.hidden) continue
                    if (!obj.size || obj.size[0] <= 0 || obj.size[1] <= 0) continue
                    result.push({
                        at:       obj.at,
                        size:     obj.size,
                        address:  t.address,
                        "class":  obj["class"] || "",
                        title:    obj.title    || "",
                        isActive: t.activated
                    })
                }
                return result
            }

            onWindowListChanged: {
                var idx = windowList.findIndex(function(w) { return w.isActive })
                hoveredIdx = idx
            }

            function findWindowAt(mx, my) {
                var gx = mx + overlay.screen.x
                var gy = my + overlay.screen.y
                for (var i = windowList.length - 1; i >= 0; i--) {
                    var w = windowList[i]
                    if (gx >= w.at[0] && gx < w.at[0] + w.size[0] &&
                        gy >= w.at[1] && gy < w.at[1] + w.size[1]) {
                        return i
                    }
                }
                return -1
            }

            Connections {
                target: Hyprland
                function onFocusedWorkspaceChanged() {
                    if (overlay.isWindowMode) Hyprland.refreshToplevels()
                }
            }

            // ── Root interaction item ────────────────────────────────────────
            Item {
                id: rootItem
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: GlobalStates.areaSelectOpen = false

                Component.onCompleted: {
                    if (overlay.isWindowMode) Hyprland.refreshToplevels()
                }

                // ════════════════════════════════════════════════════════════
                // AREA SELECT MODE
                // ════════════════════════════════════════════════════════════

                // Pre-drag dim
                Rectangle {
                    anchors.fill: parent
                    color: "#55000000"
                    visible: !overlay.isWindowMode && !overlay.dragging
                }

                // Four dark panels surrounding selection
                Rectangle {
                    visible: !overlay.isWindowMode && overlay.dragging
                    x: 0; y: 0; width: parent.width; height: overlay.selY
                    color: "#88000000"
                }
                Rectangle {
                    visible: !overlay.isWindowMode && overlay.dragging
                    x: 0; y: overlay.selY + overlay.selH
                    width: parent.width
                    height: parent.height - overlay.selY - overlay.selH
                    color: "#88000000"
                }
                Rectangle {
                    visible: !overlay.isWindowMode && overlay.dragging
                    x: 0; y: overlay.selY
                    width: overlay.selX; height: overlay.selH
                    color: "#88000000"
                }
                Rectangle {
                    visible: !overlay.isWindowMode && overlay.dragging
                    x: overlay.selX + overlay.selW; y: overlay.selY
                    width: parent.width - overlay.selX - overlay.selW
                    height: overlay.selH
                    color: "#88000000"
                }

                // Selection border + corner handles
                Rectangle {
                    visible: !overlay.isWindowMode && overlay.dragging && overlay.selW > 4 && overlay.selH > 4
                    x: overlay.selX; y: overlay.selY
                    width: overlay.selW; height: overlay.selH
                    color: "transparent"
                    border.color: Colors.primary
                    border.width: 2

                    Repeater {
                        model: [ [0,0], [1,0], [0,1], [1,1] ]
                        delegate: Rectangle {
                            required property var modelData
                            x: modelData[0] * (overlay.selW - 8)
                            y: modelData[1] * (overlay.selH - 8)
                            width: 8; height: 8; radius: 2
                            color: Colors.primary
                        }
                    }
                }

                // Area info box (drag progress)
                Rectangle {
                    id: infoBox
                    visible: !overlay.isWindowMode && overlay.dragging && overlay.selW > 4 && overlay.selH > 4

                    readonly property real offsetX: 16
                    readonly property real offsetY: 16
                    width: infoRow.implicitWidth + 20; height: 30
                    radius: 10
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
                        id: infoRow
                        anchors.centerIn: parent
                        spacing: 8

                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: overlay.geoX + ", " + overlay.geoY
                            size: 10; color: Colors.outline
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1; height: 14; color: Colors.outline; opacity: 0.4
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: overlay.geoW + " × " + overlay.geoH
                            size: 10; weight: 700; color: Colors.surfaceText
                        }
                    }
                }

                // ════════════════════════════════════════════════════════════
                // WINDOW PICK MODE
                // ════════════════════════════════════════════════════════════

                Item {
                    anchors.fill: parent
                    visible: overlay.isWindowMode

                    // Base dim layer
                    Rectangle {
                        anchors.fill: parent
                        color: "#66000000"
                    }

                    // Per-window highlight rectangles
                    Repeater {
                        model: overlay.windowList
                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            x: modelData.at[0] - overlay.screen.x
                            y: modelData.at[1] - overlay.screen.y
                            width:  modelData.size[0]
                            height: modelData.size[1]
                            radius: 6

                            readonly property bool isActive: modelData.isActive
                            readonly property bool isHovered: overlay.hoveredIdx === index

                            color: isHovered
                                ? Qt.alpha(Colors.primary, 0.18)
                                : isActive ? Qt.alpha(Colors.primary, 0.07) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            border.color: isHovered
                                ? Colors.primary
                                : isActive ? Qt.alpha(Colors.primary, 0.60) : Qt.alpha(Colors.outline, 0.25)
                            border.width: isHovered ? 2.5 : isActive ? 1.5 : 1
                            Behavior on border.width { NumberAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation  { duration: 100 } }

                            // Window label (shown when hovered)
                            Rectangle {
                                visible: overlay.hoveredIdx === index
                                anchors { bottom: parent.top; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
                                width: wndLabelRow.implicitWidth + 16; height: 28
                                radius: 10
                                color: Colors.surfaceContainer

                                Row {
                                    id: wndLabelRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    MaterialIconSymbol {
                                        anchors.verticalCenter: parent.verticalCenter
                                        content: "window"; iconSize: 13
                                        color: Colors.primary
                                    }
                                    CustomText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        content: modelData["class"] || modelData.title || "Window"
                                        size: 10; weight: 600; color: Colors.surfaceText
                                    }
                                }
                            }
                        }
                    }
                }

                // ════════════════════════════════════════════════════════════
                // MODE BADGE  (near cursor — both modes, before drag)
                // ════════════════════════════════════════════════════════════
                Rectangle {
                    id: modeBadge
                    visible: overlay.isWindowMode ? true : !overlay.dragging

                    readonly property real offsetX: 18
                    readonly property real offsetY: 18
                    width: badgeRow.implicitWidth + 20; height: 32
                    radius: 12
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
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialIconSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            content: {
                                if (overlay.isWindowMode) return "window"
                                if (GlobalStates.areaSelectMode === "ocr") return "text_select_start"
                                return GlobalStates.areaSelectMode === "screenshot" ? "photo_camera" : "videocam"
                            }
                            iconSize: 14
                            color: Colors.primary
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: {
                                if (overlay.isWindowMode) {
                                    return overlay.hoveredIdx >= 0
                                        ? (overlay.windowList[overlay.hoveredIdx]["class"] || "Window")
                                        : "Click a window"
                                }
                                if (GlobalStates.areaSelectMode === "ocr") return "Copy text"
                                return GlobalStates.areaSelectMode === "screenshot" ? "Screenshot" : "Recording"
                            }
                            size: 11; weight: 700; color: Colors.surfaceText
                        }
                    }
                }

                // ════════════════════════════════════════════════════════════
                // SHARED MOUSE AREA
                // ════════════════════════════════════════════════════════════
                MouseArea {
                    anchors.fill: parent
                    cursorShape:     Qt.CrossCursor
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPositionChanged: mouse => {
                        overlay.curX = mouse.x
                        overlay.curY = mouse.y
                        if (overlay.isWindowMode) {
                            overlay.hoveredIdx = overlay.findWindowAt(mouse.x, mouse.y)
                        }
                    }

                    onPressed: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            GlobalStates.areaSelectOpen = false
                            return
                        }
                        if (overlay.isWindowMode) return  // handled in onClicked
                        overlay.startX   = mouse.x
                        overlay.startY   = mouse.y
                        overlay.curX     = mouse.x
                        overlay.curY     = mouse.y
                        overlay.dragging = true
                    }

                    onClicked: mouse => {
                        if (!overlay.isWindowMode) return
                        if (mouse.button !== Qt.LeftButton) return
                        if (overlay.hoveredIdx < 0) return
                        var w   = overlay.windowList[overlay.hoveredIdx]
                        var geo = w.at[0] + "," + w.at[1] + " " + w.size[0] + "x" + w.size[1]
                        var mode = GlobalStates.areaSelectMode
                        GlobalStates.areaSelectOpen = false
                        if (mode === "window-screenshot") ServiceTools.takeAreaScreenshot(geo)
                        else ServiceTools.startWithGeometry("Window", geo)
                    }

                    onReleased: mouse => {
                        if (overlay.isWindowMode) return
                        if (mouse.button !== Qt.LeftButton) return
                        if (overlay.geoW < 5 || overlay.geoH < 5) {
                            overlay.dragging = false
                            return
                        }
                        var geo  = overlay.geoX + "," + overlay.geoY + " " + overlay.geoW + "x" + overlay.geoH
                        var mode = GlobalStates.areaSelectMode
                        GlobalStates.areaSelectOpen = false
                        if (mode === "screenshot") ServiceTools.takeAreaScreenshot(geo)
                        else if (mode === "ocr") ServiceTools.ocrArea(geo)
                        else if (mode === "recording") ServiceTools.startWithGeometry("Area", geo)
                    }
                }
            }
        }
    }
}
