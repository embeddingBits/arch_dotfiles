import QtQuick
import QtQuick.Layouts
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property var memoryService

    Layout.preferredWidth: 78
    Layout.preferredHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: memMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: 4

        Text {
            text: "󰍛"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: Theme.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.memoryService.memUsedText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            font.weight: 600
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.90)
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlineMemory
        opacity: memMouse.containsMouse ? 1 : 0.92
    }

    MouseArea {
        id: memMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.memoryService.refresh()
    }

    ToolTip {
        visible: memMouse.containsMouse
        delay: 400
        text: root.memoryService.memTooltip
        contentItem: Text {
            text: memMouse.containsMouse ? root.memoryService.memTooltip : ""
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.fg
        }
        background: Rectangle {
            color: Theme.bg
            border.color: Theme.border
            border.width: 1
            radius: 4
        }
    }
}
