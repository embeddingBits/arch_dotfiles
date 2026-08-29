import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import Quickshell.Hyprland
import qs.modules.utils
import qs.modules.settings
import qs.modules.services

PopupWindow {
    id: root

    property var appEntry: null

    implicitWidth: 210
    implicitHeight: menuCol.implicitHeight + 16
    color: "transparent"

    signal close

    anchor {
        window: panelWindow
        edges: Edges.Top
        gravity: Edges.Top
    }

    HyprlandFocusGrab {
        active: true
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    Rectangle {
        id: menuRect
        anchors.fill: parent
        color: Colors.surfaceContainer
        radius: 20

        scale: 0.88
        opacity: 0
        NumberAnimation on scale   { from: 0.88; to: 1; duration: 180; easing.type: Easing.OutQuad; running: true }
        NumberAnimation on opacity { from: 0;    to: 1; duration: 150; running: true }

        ColumnLayout {
            id: menuCol
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                margins: 8
            }
            spacing: 6

            // ── App header ───────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 14
                color: Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Image {
                        width: 32; height: 32
                        source: Quickshell.iconPath(
                            DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.icon,
                            "image-missing")
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        CustomText {
                            Layout.fillWidth: true
                            content: DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.name
                                     ?? root.appEntry?.appId ?? ""
                            size: 13
                            weight: 700
                            elide: Text.ElideRight
                        }
                        CustomText {
                            content: {
                                var n = root.appEntry?.toplevels.length ?? 0
                                return n > 0 ? n + " window" + (n > 1 ? "s open" : " open") : "Not running"
                            }
                            size: 10
                            customColor: Colors.outline
                        }
                    }
                }
            }

            // ── Actions group ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: actionsCol.implicitHeight
                radius: 14
                color: Colors.surfaceContainerHigh
                clip: true

                ColumnLayout {
                    id: actionsCol
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    // Pin / Unpin
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            MaterialIconSymbol {
                                content: "push_pin"
                                iconSize: 16
                                fill: ServiceApps.isPinnedById(root.appEntry?.appId ?? "") ? 1 : 0
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: ServiceApps.isPinnedById(root.appEntry?.appId ?? "")
                                         ? "Unpin from dock" : "Pin to dock"
                                size: 12
                            }
                        }

                        RippleEffect {
                            anchors.fill: parent
                            onClicked: {
                                ServiceApps.togglePinById(root.appEntry?.appId ?? "")
                                root.close()
                            }
                        }
                    }

                    // Close / Close all  (only when running)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        color: "transparent"
                        visible: (root.appEntry?.toplevels.length ?? 0) > 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            MaterialIconSymbol {
                                content: "cancel"
                                iconSize: 16
                                customColor: Colors.error
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: (root.appEntry?.toplevels.length ?? 0) > 1 ? "Close all" : "Close"
                                size: 12
                                customColor: Colors.error
                            }
                        }

                        RippleEffect {
                            anchors.fill: parent
                            onClicked: {
                                for (const t of root.appEntry?.toplevels ?? [])
                                    t.close()
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
