import QtQuick
import Quickshell
import "../../config/Theme.qml" as Theme

Item {
    id: root

    width: 30
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: powerMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: "󰐥"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.barFontSize
        color: powerMouse.containsMouse ? Theme.accent : Theme.fg
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlinePower
        opacity: powerMouse.containsMouse ? 1 : 0.92
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "wlogout &"])
    }
}
