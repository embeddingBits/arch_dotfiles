import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../config/Theme.qml" as Theme

PopupWindow {
    id: root

    required property var bar
    required property bool bluetoothPopupOpen

    property var btAdapter: Bluetooth.defaultAdapter
    property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []

    visible: root.bluetoothPopupOpen
    color: "transparent"

    anchor.window: root.bar
    anchor.rect.x: bar.width - implicitWidth - 12
    anchor.rect.y: bar.height + 6
    anchor.rect.width: 1
    anchor.rect.height: 1

    implicitWidth: 360
    implicitHeight: btCol.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        Column {
            id: btCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Row {
                width: parent.width

                Text {
                    text: "󰂯  Bluetooth"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: 700
                    color: Theme.fg
                }

                Item {
                    width: 8
                    height: 1
                }

                Text {
                    text: root.btAdapter && root.btAdapter.enabled ? "ON" : "OFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: root.btAdapter && root.btAdapter.enabled ? Theme.accent : Qt.darker(Theme.fg, 1.4)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 20
                    height: 1
                }

                Rectangle {
                    width: 44
                    height: 22
                    radius: Theme.radius
                    color: root.btAdapter && root.btAdapter.enabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                    border.color: Theme.borderMuted
                    border.width: 1

                    Rectangle {
                        width: 16
                        height: 16
                        radius: Theme.radius
                        color: Theme.fg
                        x: root.btAdapter && root.btAdapter.enabled ? parent.width - width - 3 : 3
                        y: 3

                        Behavior on x {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.btAdapter)
                            root.btAdapter.enabled = !root.btAdapter.enabled
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.borderMuted
                opacity: 0.5
            }

            Column {
                width: parent.width
                spacing: 4
                visible: {
                    for (let i = 0; i < root.btDevices.length; i++)
                        if (root.btDevices[i] && root.btDevices[i].connected)
                            return true;
                    return false;
                }

                Text {
                    text: "CONNECTED"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: Qt.darker(Theme.fg, 1.3)
                }

                Repeater {
                    model: {
                        let out = [];
                        for (let i = 0; i < root.btDevices.length; i++)
                            if (root.btDevices[i] && root.btDevices[i].connected)
                                out.push(root.btDevices[i]);
                        return out.slice(0, 4);
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 32
                        radius: Theme.radius
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                        border.color: Theme.borderMuted
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰂱"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name || modelData.deviceName || modelData.address || "Device"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: 600
                                color: Theme.fg
                                elide: Text.ElideRight
                                width: parent.width - 80
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Qt.darker(Theme.fg, 1.2)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (modelData.disconnect)
                                modelData.disconnect();
                            else if (modelData.connected)
                                Quickshell.execDetached(["bluetoothctl", "disconnect", modelData.address]);
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "DEVICES"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: Qt.darker(Theme.fg, 1.3)
                }

                Repeater {
                    model: root.btDevices.slice(0, 8)

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 28
                        radius: Theme.radius
                        color: btRowMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                        border.color: modelData.connected ? Theme.borderMuted : btRowMouse.containsMouse ? Theme.borderMuted : "transparent"
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.connected ? "󰂱" : modelData.paired ? "󰂯" : "󰂲"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: modelData.connected ? Theme.accent : Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name || modelData.deviceName || modelData.address || "Unknown"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.fg
                                elide: Text.ElideRight
                                width: parent.width - 70
                                anchors.verticalCenter: parent.verticalCenter
                                font.weight: modelData.connected ? 600 : 400
                            }

                            Text {
                                text: modelData.connected ? "●" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: btRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    if (modelData.disconnect)
                                        modelData.disconnect();
                                    else
                                        Quickshell.execDetached(["bluetoothctl", "disconnect", modelData.address]);
                                } else {
                                    if (modelData.paired) {
                                        if (modelData.connect)
                                            modelData.connect();
                                        else
                                            Quickshell.execDetached(["bluetoothctl", "connect", modelData.address]);
                                    } else {
                                        Quickshell.execDetached(["bluetoothctl", "pair", modelData.address]);
                                        if (modelData.connect)
                                            Qt.callLater(function () {
                                                modelData.connect();
                                            });
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: root.btDevices.length === 0
                    text: !root.btAdapter ? "No adapter" : !root.btAdapter.enabled ? "Bluetooth off" : "Scanning…"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Qt.darker(Theme.fg, 1.5)
                    font.italic: true
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 26
                    radius: Theme.radius
                    color: footBtMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰂯 Scan"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }

                    MouseArea {
                        id: footBtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.btAdapter)
                            root.btAdapter.discovering = !root.btAdapter.discovering
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 26
                    radius: Theme.radius
                    color: footBt2Mouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰂯 Settings"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }

                    MouseArea {
                        id: footBt2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", "-c", "blueman-manager &"])
                    }
                }
            }
        }
    }
}
