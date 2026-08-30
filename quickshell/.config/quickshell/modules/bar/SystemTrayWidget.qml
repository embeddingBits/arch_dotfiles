import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config/Theme.qml" as Theme

RowLayout {
    id: root

    visible: SystemTray.items.values.length > 0
    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: Item {
            required property var modelData

            Layout.preferredWidth: 24
            Layout.preferredHeight: 26

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: trayMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                width: 16
                height: 16
                source: modelData.icon
                asynchronous: true
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                radius: 1
                color: Theme.underlineTray
                opacity: trayMouse.containsMouse ? 1 : 0.85
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.LeftButton)
                        modelData.activate();
                    else if (mouse.button === Qt.RightButton && modelData.hasMenu)
                        modelData.display(Qt.point(width / 2, height));
                }
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
        visible: SystemTray.items.values.length > 0
    }
}
