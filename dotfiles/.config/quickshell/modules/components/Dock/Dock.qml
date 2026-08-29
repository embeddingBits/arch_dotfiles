import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: dockRow.implicitWidth
    visible: false

    signal contextMenuRequested(real px, real py, var appEntry)
    property bool showPreview: false
    property bool iconHovered: false
    property bool previewHovered: false
    property point previewPos: Qt.point(0, 0)
    property var hoveredAppEntry: null
    property bool closing: false

    states: State {
        name: "closing"
        when: root.closing
        PropertyChanges { target: root; opacity: 0; scale: 0.85 }
    }

    transitions: Transition {
        to: "closing"
        NumberAnimation { properties: "opacity,scale"; duration: 260; easing.type: Easing.InCubic }
    }

    Timer {
        id: hidePreviewTimer
        interval: 150
        onTriggered: {
            if (!root.iconHovered && !root.previewHovered)
                root.showPreview = false
        }
    }

    Timer {
        id: dockTimer
        interval: 300
        running: true
        onTriggered: root.visible = true
    }

    NumberAnimation on opacity { from: 0; to: 1; duration: 400 }
    NumberAnimation on scale   { from: 0.8; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.3 }

    Loader {
        id: previewLoader
        active: root.showPreview
        sourceComponent: DockPreview {
            anchorPoint: root.previewPos
            appEntry: root.hoveredAppEntry
            onHoverEntered: {
                hidePreviewTimer.stop()
                root.previewHovered = true
            }
            onHoverExited: {
                root.previewHovered = false
                if (!root.iconHovered)
                    hidePreviewTimer.restart()
            }
        }
    }

    RowLayout {
        id: dockRow
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 2

        // ── Menu button ───────────────────────────────────────────────────
        Item {
            Layout.preferredWidth: 44
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: 40; height: 40
                radius: 12
                color: menuBtn.containsMouse ? Colors.primaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                scale: menuBtn.containsMouse ? 1.15 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                }
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "grid_view"
                iconSize: 22
                customColor: menuBtn.containsMouse ? Colors.primaryContainerText : Colors.outline
                Behavior on customColor { ColorAnimation { duration: 150 } }

                scale: menuBtn.containsMouse ? 1.12 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                }
            }

            MouseArea {
                id: menuBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen
            }
        }

        // thin divider after menu button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 1; implicitHeight: 24
            color: Qt.alpha(Colors.outline, 0.2)
            radius: 1
        }

        // ── App icons ─────────────────────────────────────────────────────
        Repeater {
            id: dockRepeater
            model: ServiceApps.dockModel

            delegate: Item {
                id: dockItem
                required property var modelData

                readonly property bool isRunning: modelData.toplevels.length > 0
                readonly property bool isActive:  modelData.toplevels.some(t => t.activated)
                readonly property int  winCount:  Math.min(modelData.toplevels.length, 3)

                Layout.preferredWidth: 44
                Layout.fillHeight: true

                // Hover / active background
                Rectangle {
                    anchors.centerIn: parent
                    width: 40; height: 40
                    radius: 12
                    color: dockIconArea.containsMouse
                        ? Colors.primaryContainer
                        : dockItem.isActive
                            ? Qt.alpha(Colors.primaryContainer, 0.45)
                            : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    scale: dockIconArea.containsMouse ? 1.15 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                    }
                }

                // App icon
                Image {
                    anchors.centerIn: parent
                    width: 32; height: 32
                    source: Quickshell.iconPath(
                        DesktopEntries.heuristicLookup(dockItem.modelData.appId)?.icon,
                        "image-missing")
                    sourceSize.width: 32
                    sourceSize.height: 32
                    fillMode: Image.PreserveAspectFit

                    scale: dockIconArea.containsMouse ? 1.12 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                    }
                }

                // Running indicator pill
                Rectangle {
                    visible: dockItem.isRunning
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    width:  dockItem.winCount === 1 ? 6 : dockItem.winCount === 2 ? 12 : 18
                    height: 4
                    radius: 2
                    color:  dockItem.isActive ? Colors.primary : Qt.alpha(Colors.primary, 0.45)

                    Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color  { ColorAnimation  { duration: 150 } }
                }

                MouseArea {
                    id: dockIconArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: {
                        if (modelData.toplevels.length > 0) {
                            hidePreviewTimer.stop()
                            root.iconHovered    = true
                            root.hoveredAppEntry = dockItem.modelData
                            root.showPreview    = true
                            var gp = dockItem.mapToItem(panelWindow.container, 0, 0)
                            root.previewPos = Qt.point(gp.x, gp.y)
                        }
                    }

                    onExited: {
                        root.iconHovered = false
                        if (!root.previewHovered)
                            hidePreviewTimer.restart()
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (dockItem.modelData.toplevels.length > 0)
                                dockItem.modelData.toplevels[0].activate()
                            else
                                ServiceApps.launch(dockItem.modelData.appId)
                        } else if (mouse.button === Qt.RightButton) {
                            const pos = dockIconArea.mapToItem(root, mouse.x, mouse.y)
                            root.contextMenuRequested(pos.x, root.y, dockItem.modelData)
                        }
                    }
                }
            }
        }

        // ── Music player ──────────────────────────────────────────────────
        Loader {
            id: musicLoader
            active: SettingsConfig.general.dockMusicPlayer
            visible: active
            Layout.preferredWidth: 200
            Layout.preferredHeight: 46
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: DockMusicPlayer {}
        }
    }
}
