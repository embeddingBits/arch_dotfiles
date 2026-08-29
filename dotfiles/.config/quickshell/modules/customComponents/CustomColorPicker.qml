import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import Quickshell.Wayland
import Quickshell.Hyprland

// ColorPicker - Simple color picker with palettes and hex input
// Usage: ColorPicker { onColorPicked: (c) => console.log(c) }

PopupWindow {
    id: root
    implicitWidth: 220
    implicitHeight: 420
    color: "transparent"
    visible: true
    signal close
    signal colorPicked(color c)
    anchor{
        window: panelWindow
        rect.x: root.width / 2 + 110
        rect.y: root.height / 2
    }

    HyprlandFocusGrab {
        active: true
        windows: [QsWindow.window]
        onCleared: root.close()
    }        property color selectedColor: "#89b4fa"

    property var colors: [
        "#f38ba8","#fab387","#f9e2af","#a6e3a1","#94e2d5","#89dceb","#89b4fa","#cba6f7",
        "#ff5555","#ffb86c","#f1fa8c","#50fa7b","#8be9fd","#bd93f9","#ff79c6","#f8f8f2"
    ]

    function isValidHex(str) {
        return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(str)
    }

    function normalizeHex(str) {
        if (str.length === 4) {
            return "#" + str[1]+str[1] + str[2]+str[2] + str[3]+str[3]
        }
        return str
    }

    function pickColor(c) {
        root.selectedColor = c
        root.colorPicked(c)
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // ── Color Preview & Info ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: root.selectedColor
                    border.color: Qt.rgba(1,1,1,0.15)
                    border.width: 2
                }

                ColumnLayout {
                    spacing: 4
                    CustomText{
                        content: root.selectedColor.toString().toUpperCase()
                        size: 16
                    }
                    CustomText {
                        content: {
                            var c = root.selectedColor
                            var r = Math.round(c.r * 255)
                            var g = Math.round(c.g * 255)
                            var b = Math.round(c.b * 255)
                            return "rgb(" + r + ", " + g + ", " + b + ")"
                        }
                        color: Colors.outline
                        size: 12
                    }
                }

                Item { Layout.fillWidth: true }

            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline }

            // ── Hex Color Input ───────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                CustomText {
                    content: "Enter Hex Color"
                    size: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: Colors.surfaceContainer
                        border.color: hexInput.activeFocus ? Colors.tertiary
                        : (hexInput.text.length > 0 && !root.isValidHex("#" + hexInput.text) ? "#f38ba8" : "#313244")
                        border.width: hexInput.activeFocus ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 6

                            CustomText {
                                content: "#"
                                size: 16
                            }

                            TextInput {
                                id: hexInput
                                Layout.fillWidth: true
                                color: Colors.surfaceText
                                font.pixelSize: 12
                                font.family: "monospace"
                                maximumLength: 6

                                CustomText {
                                    anchors.fill: parent
                                    content: "ff79c6"
                                    font: parent.font
                                    visible: parent.text.length === 0
                                }

                                onTextChanged: {
                                    if (text.startsWith("#")) {
                                        text = text.slice(1)
                                    }
                                }

                                Keys.onReturnPressed: {
                                    var t = "#" + text
                                    if (root.isValidHex(t)) {
                                        root.pickColor(root.normalizeHex(t))
                                        text = ""
                                    }
                                }
                                Keys.onEnterPressed: Keys.onReturnPressed(event)
                            }
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 8
                        color: {
                            var t = "#" + hexInput.text
                            return root.isValidHex(t) ? t : "#313244"
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 8
                        color: Colors.tertiary
                        opacity: root.isValidHex("#" + hexInput.text) ? 1.0 : 0.5

                        CustomText {
                            anchors.centerIn: parent
                            content: "✓"
                            size: 20
                        }

                        MouseArea {
                            id: addHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.isValidHex("#" + hexInput.text)
                            onClicked: {
                                var t = "#" + hexInput.text
                                if (root.isValidHex(t)) {
                                    root.pickColor(root.normalizeHex(t))
                                    hexInput.text = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline }

            // ── Color Swatches ────────────────────────────────────────
            CustomText {
                content: "Colors"
                size: 12
            }

            Grid {
                Layout.fillWidth: true
                columns: 4
                spacing: 10

                Repeater {
                    model: root.colors

                    delegate: Rectangle {
                        property bool hov: swatchHover.containsMouse
                        property bool sel: root.selectedColor.toString().toLowerCase() === modelData.toLowerCase()

                        width: (parent.width - 3 * 10) / 4
                        height: width
                        radius: 8
                        color: modelData

                        border.color: sel ? Colors.inverseSurface : (hov ? Qt.rgba(1,1,1,0.4) : "transparent")
                        border.width: sel ? 3 : 2

                        scale: hov ? 1.1 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Rectangle {
                            anchors.bottom: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 6
                            width: tipText.implicitWidth + 12
                            height: 22
                            radius: 5
                            color: "#181825"
                            border.color: "#313244"
                            border.width: 1
                            visible: swatchHover.containsMouse
                            z: 10

                            Text {
                                id: tipText
                                anchors.centerIn: parent
                                text: modelData.toUpperCase()
                                color: "#cdd6f4"
                                font.pixelSize: 10
                                font.family: "monospace"
                            }
                        }

                        MouseArea {
                            id: swatchHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickColor(modelData)
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
