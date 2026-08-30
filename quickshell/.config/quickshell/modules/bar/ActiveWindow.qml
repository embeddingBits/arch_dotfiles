import QtQuick
import QtQuick.Layouts
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property var niriService

    visible: niriService.activeWindowTitle !== ""
    Layout.preferredWidth: Math.min(activeWinText.implicitWidth + 32, 280)
    Layout.preferredHeight: 26
    Layout.maximumWidth: 280

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: awMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        Text {
            text: "󰖲"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: Theme.muted
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: activeWinText
            text: root.niriService.activeWindowTitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            font.weight: 500
            color: Theme.fg
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            maximumLineCount: 1
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlineActiveWindow
        opacity: awMouse.containsMouse ? 1 : 0.9
    }

    MouseArea {
        id: awMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
