import QtQuick
import QtQuick.Layouts
import "../../config/Theme.qml" as Theme

RowLayout {
    id: root

    required property var niriService

    spacing: 6

    Repeater {
        model: root.niriService.niriWorkspaces

        delegate: Item {
            id: wsDelegate

            required property var modelData
            property bool focused: modelData.is_focused
            property bool occupied: modelData.occupied

            Layout.preferredWidth: focused ? 30 : 26
            Layout.preferredHeight: 26

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: wsMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : focused ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10) : "transparent"
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: focused ? "󰝥" : String(modelData.idx)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.barFontSize
                font.weight: focused ? 700 : 600
                color: focused ? Theme.accent : occupied ? Theme.fg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.55)
                opacity: occupied || focused ? 1 : 0.60
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: focused ? 2.5 : 2
                radius: 1
                color: focused ? Theme.underlineWorkspaces : occupied ? Qt.rgba(Theme.underlineWorkspaces.r, Theme.underlineWorkspaces.g, Theme.underlineWorkspaces.b, 0.85) : Qt.rgba(Theme.underlineWorkspaces.r, Theme.underlineWorkspaces.g, Theme.underlineWorkspaces.b, 0.35)
                opacity: wsMouse.containsMouse ? 1 : 0.9
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.niriService.focusWorkspace(String(modelData.idx))
            }
        }
    }
}
