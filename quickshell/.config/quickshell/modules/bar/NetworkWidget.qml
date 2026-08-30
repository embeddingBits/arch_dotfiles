import QtQuick
import Quickshell.Networking
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property bool wifiPopupOpen
    signal toggleWifi

    // Resolve via Networking service properties — passed through root context
    property var netDevices: Networking.devices ? Networking.devices.values : []
    property var wifiDev: {
        for (let i = 0; i < netDevices.length; i++)
            if (netDevices[i] && netDevices[i].type === DeviceType.Wifi)
                return netDevices[i];
        return null;
    }
    property var wifiNets: wifiDev && wifiDev.networks ? wifiDev.networks.values : []

    width: 28
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: netMouse.containsMouse || root.wifiPopupOpen ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: {
            let d = root.wifiDev;
            if (!d)
                return "󰤯";
            if (!Networking.wifiEnabled)
                return "󰤮";
            for (let i = 0; i < root.wifiNets.length; i++)
                if (root.wifiNets[i] && root.wifiNets[i].connected) {
                    let s = root.wifiNets[i].signalStrength || 0;
                    if (s > 0.66)
                        return "󰤨";
                    if (s > 0.33)
                        return "󰤥";
                    return "󰤢";
                }
            return "󰤯";
        }
        font.family: Theme.fontFamily
        font.pixelSize: Theme.barFontSize
        color: Theme.fg
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlineNetwork
        opacity: netMouse.containsMouse || root.wifiPopupOpen ? 1 : 0.92
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleWifi()
    }
}
