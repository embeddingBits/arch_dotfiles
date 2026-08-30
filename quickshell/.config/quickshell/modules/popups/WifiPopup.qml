import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../config/Theme.qml" as Theme

PopupWindow {
    id: root

    required property var bar
    required property bool wifiPopupOpen

    // Derived networking state (mirrors NetworkWidget logic)
    property var netDevices: Networking.devices ? Networking.devices.values : []
    property var wifiDev: {
        for (let i = 0; i < netDevices.length; i++)
            if (netDevices[i] && netDevices[i].type === DeviceType.Wifi)
                return netDevices[i];
        return null;
    }
    property var wifiNets: wifiDev && wifiDev.networks ? wifiDev.networks.values : []

    visible: root.wifiPopupOpen
    color: "transparent"

    anchor.window: root.bar
    anchor.rect.x: bar.width - implicitWidth - 48
    anchor.rect.y: bar.height + 6
    anchor.rect.width: 1
    anchor.rect.height: 1

    implicitWidth: 360
    implicitHeight: wifiCol.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        Column {
            id: wifiCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            // ── Header ──
            Row {
                width: parent.width

                Text {
                    text: "󰖩  Wi-Fi"
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
                    text: Networking.wifiEnabled ? "ON" : "OFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: Networking.wifiEnabled ? Theme.accent : Qt.darker(Theme.fg, 1.4)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 20
                    height: 1
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 44
                    height: 22
                    radius: Theme.radius
                    color: Networking.wifiEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                    border.color: Theme.borderMuted
                    border.width: 1

                    Rectangle {
                        width: 16
                        height: 16
                        radius: Theme.radius
                        color: Theme.fg
                        x: Networking.wifiEnabled ? parent.width - width - 3 : 3
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
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.borderMuted
                opacity: 0.5
            }

            // ── Connected ──
            Column {
                width: parent.width
                spacing: 4
                visible: {
                    for (let i = 0; i < root.wifiNets.length; i++)
                        if (root.wifiNets[i] && root.wifiNets[i].connected)
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
                        for (let i = 0; i < root.wifiNets.length; i++)
                            if (root.wifiNets[i] && root.wifiNets[i].connected)
                                out.push(root.wifiNets[i]);
                        return out.slice(0, 1);
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
                                text: "󰤨"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.ssid || modelData.name || "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: 600
                                color: Theme.fg
                                elide: Text.ElideRight
                                width: parent.width - 80
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: Math.round((modelData.signalStrength || 0) * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Qt.darker(Theme.fg, 1.2)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // ── Available ──
            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "AVAILABLE"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: Qt.darker(Theme.fg, 1.3)
                }

                Repeater {
                    model: {
                        let all = root.wifiNets.slice(0);
                        all.sort((a, b) => (b.signalStrength || 0) - (a.signalStrength || 0));
                        return all.slice(0, 8);
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 28
                        radius: Theme.radius
                        color: wifiRowMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                        border.color: modelData.connected ? Theme.borderMuted : wifiRowMouse.containsMouse ? Theme.borderMuted : "transparent"
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: {
                                    let s = modelData.signalStrength || 0;
                                    if (s > 0.66)
                                        return "󰤨";
                                    if (s > 0.33)
                                        return "󰤥";
                                    return "󰤢";
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: modelData.connected ? Theme.accent : Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.ssid || modelData.name || "Hidden"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.fg
                                elide: Text.ElideRight
                                width: parent.width - 90
                                anchors.verticalCenter: parent.verticalCenter
                                font.weight: modelData.connected ? 600 : 400
                            }

                            Text {
                                text: modelData.security !== 0 ? "󰌾" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Qt.darker(Theme.fg, 1.4)
                                anchors.verticalCenter: parent.verticalCenter
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
                            id: wifiRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else {
                                    if (modelData.known)
                                        modelData.connect();
                                    else {
                                        if (modelData.security === 0)
                                            modelData.connect();
                                        else
                                            Quickshell.execDetached(["bash", "-c", "alacritty -e nmtui &"]);
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: root.wifiNets.length === 0
                    text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi disabled"
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
                    color: footWifiMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰑓 Refresh"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }

                    MouseArea {
                        id: footWifiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.wifiDev)
                            root.wifiDev.scannerEnabled = true
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 26
                    radius: Theme.radius
                    color: footWifi2Mouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰖩 Settings"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }

                    MouseArea {
                        id: footWifi2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", "-c", "nm-connection-editor &"])
                    }
                }
            }
        }
    }
}
