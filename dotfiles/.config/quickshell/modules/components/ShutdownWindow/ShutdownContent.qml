import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialSHapeFn

Item {
    id: root
    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: GlobalStates.shutdownWindow = false

    readonly property var permanentShapeGetters: [
        MatrialSHapeFn.getCircle,
        MatrialSHapeFn.getCircle,
        MatrialSHapeFn.getCircle,
        MatrialSHapeFn.getCircle
    ]

    readonly property var hoverShapeGetters: [
        MatrialSHapeFn.getArch,
        MatrialSHapeFn.getCookie7Sided,
        MatrialSHapeFn.getPill,
        MatrialSHapeFn.getCookie12Sided
    ]

    readonly property var actionIcons:    ["power_settings_new", "refresh", "logout", "lock"]
    readonly property var actionLabels:   ["Shut Down", "Restart", "Log Out", "Lock"]
    readonly property var actionCommands: [
        ["systemctl", "poweroff"],
        ["systemctl", "reboot"],
        ["hyprctl", "dispatch", "exit"],
        ["loginctl", "lock-session"]
    ]

    // ── Blurred wallpaper background ─────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: WallpaperTheme.wallpaper
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.9
            blurMax: 48
            autoPaddingEnabled: false
        }
        NumberAnimation on opacity { from: 0; to: 1; duration: 400 }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colors.surface, 0.72)
    }

    // ── Click-outside to dismiss ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.shutdownWindow = false
    }

    // ── Center column ─────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 52

        // ── Header ───────────────────────────────────────────────────────────
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            ClippingWrapperRectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72; height: 72
                radius: height

                border.width: 2
                border.color: Colors.primary

                Image {
                    anchors.fill: parent
                    source: SettingsConfig.general.profile
                    sourceSize.width: 144
                    sourceSize.height: 144
                    fillMode: Image.PreserveAspectCrop
                }

                NumberAnimation on scale {
                    from: 0.3; to: 1; duration: 500
                    easing.type: Easing.OutBack; easing.overshoot: 0.7
                }
                NumberAnimation on opacity { from: 0; to: 1; duration: 350 }
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: Quickshell.env("USER") || "user"
                size: 22; weight: 700
                color: Colors.surfaceText
                NumberAnimation on opacity { from: 0; to: 1; duration: 450 }
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: Qt.formatDate(new Date(), "dddd, MMMM d")
                size: 13
                color: Colors.outline
                NumberAnimation on opacity { from: 0; to: 1; duration: 550 }
            }
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Repeater {
                model: root.actionIcons.length

                delegate: Item {
                    id: btn
                    required property int index
                    property bool isHovered: false
                    width: 148; height: 196

                    MaterialShapes.ShapeCanvas {
                        id: shape
                        width: 148; height: 148
                        anchors.horizontalCenter: parent.horizontalCenter

                        color: btn.isHovered ? Colors.primary : Colors.surfaceContainerHigh
                        roundedPolygon: btn.isHovered
                            ? root.hoverShapeGetters[btn.index]()
                            : root.permanentShapeGetters[btn.index]()

                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: root.actionIcons[btn.index]
                            iconSize: 62
                            color: btn.isHovered ? Colors.primaryText : Colors.surfaceText
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: btn.isHovered = true
                            onExited:  btn.isHovered = false
                            onClicked: {
                                GlobalStates.shutdownWindow = false
                                Quickshell.execDetached(root.actionCommands[btn.index])
                            }
                        }

                        NumberAnimation on scale {
                            from: 0.4; to: 1
                            duration: 300 + btn.index * 55
                            easing.type: Easing.OutBack; easing.overshoot: 0.55
                        }
                        NumberAnimation on opacity {
                            from: 0; to: 1
                            duration: 220 + btn.index * 55
                        }
                    }

                    CustomText {
                        anchors {
                            top: shape.bottom
                            topMargin: 14
                            horizontalCenter: parent.horizontalCenter
                        }
                        content: root.actionLabels[btn.index]
                        size: 12; weight: 600
                        color: btn.isHovered ? Colors.primary : Colors.outline
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        // ── ESC hint ──────────────────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 22; radius: 6
                color: Colors.surfaceContainerHigh

                CustomText {
                    anchors.centerIn: parent
                    content: "ESC"; size: 9; weight: 700
                    color: Colors.outline
                }
            }

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: "to dismiss"; size: 12
                color: Qt.alpha(Colors.outline, 0.6)
            }
        }
    }
}
