import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item {
    id: root
    implicitWidth:  Appearance.size.vpnPanelWidth
    implicitHeight: contentColumn.implicitHeight + 20
    signal closed

    opacity: 0
    property real _slideX: 400
    transform: Translate { x: root._slideX }

    NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: true }
    NumberAnimation on _slideX { from: 400; to: 0; duration: 300; easing.type: Easing.OutCubic; running: true }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10

        // ── Header bar ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 20
            color: Colors.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 12

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 38; height: 38
                    radius: 19
                    color: ServiceVpn.connected ? Qt.alpha(Colors.primary, 0.16) : Colors.surfaceContainerHighest
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "vpn_lock"
                        iconSize: 19
                        fill: ServiceVpn.connected ? 1 : 0
                        customColor: ServiceVpn.connected ? Colors.primary : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    CustomText { content: "VPN"; size: 14; weight: 700 }
                    CustomText {
                        content: !ServiceVpn.installed ? "Not installed"
                               : ServiceVpn.busy       ? "Working…"
                               : ServiceVpn.connected   ? "Connected · " + ServiceVpn.country
                               :                          "Not connected"
                        size: 11
                        customColor: ServiceVpn.connected ? Colors.primary : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 32; height: 32
                    radius: 16
                    color: closeRipple.containsMouse ? Colors.surfaceContainerHighest : "transparent"

                    MaterialIconSymbol { anchors.centerIn: parent; content: "close"; iconSize: 17; customColor: Colors.outline }
                    RippleEffect {
                        id: closeRipple
                        anchors.fill: parent
                        radius: parent.width / 2
                        onClicked: root.closed()
                    }
                }
            }
        }

        // ── Not installed empty state ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            visible: !ServiceVpn.installed
            color: Colors.surfaceContainerHigh
            radius: 20

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 40

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 46; implicitHeight: 46

                    MaterialShapes.ShapeCanvas {
                        anchors.fill: parent
                        roundedPolygon: MaterialShapeFn.getCookie6Sided()
                        color: Colors.surfaceContainerHighest
                    }
                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "vpn_key_off"; iconSize: 22; customColor: Colors.outline
                    }
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "ProtonVPN CLI not installed"; size: 13; customColor: Colors.outline
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    content: "sudo pacman -S proton-vpn-cli"
                    size: 11; customColor: Colors.outline
                }
            }
        }

        // ── Error message ────────────────────────────────────────────────
        CustomText {
            Layout.fillWidth: true
            visible: ServiceVpn.installed && ServiceVpn.error !== ""
            content: ServiceVpn.error
            size: 11
            wrapMode: Text.WordWrap
            customColor: Colors.error
        }

        // ── Action ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            visible: ServiceVpn.installed
            radius: height / 2
            color: Colors.surfaceContainerHighest

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialIconSymbol {
                    visible: !ServiceVpn.busy
                    content: ServiceVpn.connected ? "vpn_key_off" : "vpn_key"
                    iconSize: 16
                    customColor: Colors.surfaceText
                }
                CustomText {
                    visible: !ServiceVpn.busy
                    content: ServiceVpn.connected ? "Disconnect" : "Connect"
                    size: 13; customColor: Colors.surfaceText
                }

                CustomCircularLoader {
                    visible: ServiceVpn.busy
                    size: 16; trackWidth: 2; waveAmplitude: 0; highlightColor: Colors.outline
                }
                CustomText {
                    visible: ServiceVpn.busy
                    content: ServiceVpn.connected ? "Disconnecting…" : "Connecting…"
                    size: 13; customColor: Colors.outline
                }
            }

            RippleEffect {
                anchors.fill: parent
                radius: parent.radius
                onClicked: {
                    if (ServiceVpn.busy) return
                    if (ServiceVpn.connected) ServiceVpn.disconnectVpn()
                    else ServiceVpn.connectFastest()
                }
            }
        }
    }
}
