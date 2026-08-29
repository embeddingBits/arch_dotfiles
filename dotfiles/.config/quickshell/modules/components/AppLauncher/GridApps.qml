import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

GridView {
    id: appList
    anchors.fill: parent
    cellWidth:  Math.floor(width / 4)
    cellHeight: 90
    clip: true
    property int activeIndex: 0
    property bool animationsEnabled: false

    model: ScriptModel {
        values: appLauncher.filteredApps
        onValuesChanged: appList.animationsEnabled = true
    }

    add: Transition {
        enabled: appList.animationsEnabled
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
    }
    remove: Transition {
        enabled: appList.animationsEnabled
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
    }

    delegate: Item {
        width:  appList.cellWidth
        height: appList.cellHeight

        readonly property bool isActive: appList.activeIndex === index
        readonly property bool isPinned: ServiceApps.isPinned(modelData)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 14

            color: isActive
                ? Colors.primaryContainer
                : appArea.containsMouse
                    ? Qt.alpha(Colors.primary, 0.08)
                    : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 6
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 4

                // Icon
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    Rectangle {
                        anchors.centerIn: parent
                        width: 46; height: 46; radius: 13
                        color: isActive
                            ? Qt.alpha(Colors.primary, 0.2)
                            : Qt.alpha(Colors.surfaceText, 0.05)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Image {
                            anchors.centerIn: parent
                            width: 30; height: 30
                            sourceSize.width: 30
                            sourceSize.height: 30
                            source: IconUtil.getIconPath(modelData.icon)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        // Pin dot
                        Rectangle {
                            anchors.right: parent.right; anchors.top: parent.top
                            anchors.topMargin: -2; anchors.rightMargin: -2
                            width: 8; height: 8; radius: 4
                            color: Colors.primary
                            visible: isPinned
                        }
                    }
                }

                // Label
                CustomText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    content: modelData.name
                    size: 11; weight: 500
                    elide: Text.ElideRight
                    customColor: isActive ? Colors.primaryContainerText : Colors.surfaceText
                    Behavior on customColor { ColorAnimation { duration: 100 } }
                }
            }

            MouseArea {
                id: appArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onEntered: appList.activeIndex = index

                onClicked: event => {
                    if (event.button === Qt.RightButton) {
                        var pos = mapToItem(appLauncher, event.x, event.y)
                        appLauncher.showContextMenu(pos.x, pos.y, modelData)
                    } else {
                        if (modelData) {
                            modelData.execute()
                            appLauncher.closed()
                        }
                    }
                }
            }
        }
    }
}
