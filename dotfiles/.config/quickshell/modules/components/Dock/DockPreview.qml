import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings

PopupWindow {
    id: root
    readonly property int cardWidth:    180
    readonly property int cardSpacing:  6
    readonly property int layoutMargins: 8

    implicitWidth: appEntry
        ? appEntry.toplevels.length * (cardWidth + cardSpacing) - cardSpacing + layoutMargins * 2
        : cardWidth + layoutMargins * 2
    implicitHeight: 180
    visible: true
    color: "transparent"

    property point anchorPoint: Qt.point(0, 0)
    property var appEntry: null

    signal hoverEntered
    signal hoverExited

    HoverHandler {
        onHoveredChanged: hovered ? root.hoverEntered() : root.hoverExited()
    }

    anchor {
        window: panelWindow
        rect: Qt.rect(anchorPoint.x + 20, anchorPoint.y - 15, 1, 1)
        gravity: Edges.Top
        edges: Edges.Bottom
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.surfaceContainer

        scale: 0.88
        opacity: 0
        NumberAnimation on scale   { from: 0.88; to: 1; duration: 180; easing.type: Easing.OutQuad; running: true }
        NumberAnimation on opacity { from: 0;    to: 1; duration: 150; running: true }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.layoutMargins
            spacing: 6

            // ── App name chip ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    width: 18; height: 18
                    source: Quickshell.iconPath(
                        DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.icon,
                        "image-missing")
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                }

                CustomText {
                    Layout.fillWidth: true
                    content: DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.name
                             ?? root.appEntry?.appId ?? ""
                    size: 12
                    weight: 700
                    elide: Text.ElideRight
                    customColor: Colors.outline
                }
            }

            // ── Window cards ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.cardSpacing

                Repeater {
                    model: root.appEntry.toplevels

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.cardWidth
                        color: Colors.surfaceContainerHigh
                        radius: 14
                        clip: true

                        RippleEffect {
                            anchors.fill: parent
                            radius: 14
                            onClicked: card.modelData.activate()
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // Title row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                CustomText {
                                    Layout.fillWidth: true
                                    content: card.modelData.title ?? ""
                                    size: 10
                                    weight: 600
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    color: closeRipple.containsMouse
                                           ? Colors.surfaceContainerHighest : "transparent"

                                    MaterialIconSymbol {
                                        anchors.centerIn: parent
                                        content: "close"
                                        iconSize: 13
                                        customColor: closeRipple.containsMouse ? Colors.error : Colors.outline
                                    }

                                    RippleEffect {
                                        id: closeRipple
                                        anchors.fill: parent
                                        radius: 11
                                        onClicked: card.modelData.close()
                                    }
                                }
                            }

                            // Preview
                            ScreencopyView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                captureSource: root.visible ? card.modelData : null
                                live: true
                                paintCursor: false
                                constraintSize: Qt.size(root.cardWidth, 120)
                            }
                        }
                    }
                }
            }
        }
    }
}
