import QtQuick
import Quickshell
import "../../config/Theme.qml" as Theme

Item {
    id: root

    width: 28
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: menuMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
    }

    Text {
        anchors.centerIn: parent
        text: "󰣇"
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
        color: Theme.underlineMenu
        opacity: menuMouse.containsMouse ? 1.0 : 0.95
    }

    MouseArea {
        id: menuMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "rofi -show drun &"])
    }
}
