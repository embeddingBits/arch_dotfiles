import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.services
import qs.modules.utils

RowLayout {
    id: root
    spacing: 2

    property bool menuClicked: false
    property QsMenuHandle menuData
    property real menuIconCenterX: 0

    Loader {
        active: root.menuClicked
        sourceComponent: SystemTrayMenu {
            menuData: root.menuData
            iconCenterX: root.menuIconCenterX
            onClose: root.menuClicked = false
        }
    }

    Repeater {
        model: ServiceSystemTray.items

        delegate: Rectangle {
            id: trayItem
            required property var modelData

            implicitWidth: 30; implicitHeight: 30
            radius: 15
            color: iconArea.containsMouse ? Colors.primaryContainer : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            CustomIconImage {
                anchors.centerIn: parent
                isColor: false
                source: trayItem.modelData.icon
                size: 18
            }

            MouseArea {
                id: iconArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.RightButton | Qt.LeftButton

                onClicked: event => {
                    if (event.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                        root.menuIconCenterX = trayItem.mapToItem(null, trayItem.width / 2, 0).x
                        root.menuClicked = true
                        root.menuData    = trayItem.modelData.menu
                    } else if (event.button === Qt.LeftButton) {
                        trayItem.modelData.activate()
                    }
                }
            }
        }
    }
}
