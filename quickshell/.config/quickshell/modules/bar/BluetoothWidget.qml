import QtQuick
import Quickshell.Bluetooth
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property bool bluetoothPopupOpen
    signal toggleBluetooth

    property var btAdapter: Bluetooth.defaultAdapter
    property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []

    width: 28
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: btMouse.containsMouse || root.bluetoothPopupOpen ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: {
            let a = root.btAdapter;
            if (!a)
                return "󰂯";
            if (!a.enabled)
                return "󰂲";
            for (let i = 0; i < root.btDevices.length; i++)
                if (root.btDevices[i] && root.btDevices[i].connected)
                    return "󰂱";
            return "󰂯";
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
        color: Theme.underlineBluetooth
        opacity: btMouse.containsMouse || root.bluetoothPopupOpen ? 1 : 0.92
    }

    MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleBluetooth()
    }
}
