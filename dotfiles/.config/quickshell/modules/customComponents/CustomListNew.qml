import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings

Item{
    id: root
    property bool isListClicked: false
    property var currentVal: null
    property var objectVal: null
    property var list: []
    property color color: Colors.surfaceContainerHigh
    z: isListClicked ? 1000 : 0
    signal listClicked
    signal listChildClicked(var child)
    height: 30

    MouseArea{
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked:{
            root.isListClicked = true
            root.listClicked()
        }
    }


    RowLayout{
        visible: !root.isListClicked && root.height === 30
        anchors.fill: parent
        Rectangle{
            Layout.fillHeight: true
            Layout.fillWidth: true
            topLeftRadius: 15
            bottomLeftRadius: 15
            topRightRadius: 5
            bottomRightRadius: 5
            color: root.color
            clip: true
            CustomText{
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                content: root.currentVal ?? root.objectVal?.name ?? ""
                size: 12
                weight: 600
            }
        }
        Rectangle{
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            topLeftRadius: 5
            bottomLeftRadius: 5
            topRightRadius: 15
            bottomRightRadius: 15
            color: root.color
            MaterialIconSymbol{
                anchors.centerIn: parent
                content: "keyboard_arrow_down"
                iconSize: 20
            } 
        }

    }

    Loader{
        id: listLoader
        active: root.isListClicked
        sourceComponent: PopupWindow{
            id: popup
            anchor.window: root.QsWindow.window
            visible: true
            implicitWidth: root.width
            implicitHeight: Math.min(listView.contentHeight + 10, 250)
            color: "transparent"

            HyprlandFocusGrab {
                active: true
                windows: [QsWindow.window]
                onCleared: morph.close()
            }

            property var windowPos: root.mapToItem(null, 0, root.height)

            anchor{
                rect.x: windowPos.x
                rect.y: windowPos.y - root.height
            }

            MorphCard{
                id: morph
                anchors.fill: parent

                srcWidth:  root.width
                srcHeight: root.height
                srcRadius: 15

                contentHeight: Math.min(listView.contentHeight + 10, 250)
                cardRadius: 10
                cardColor: root.color

                onCloseFinished: root.isListClicked = false
                Component.onCompleted: Qt.callLater(morph.open)

                ListView{
                    id: listView
                    anchors{
                        fill: parent
                        margins: 5
                    }
                    orientation: Qt.Vertical
                    model: root.list
                    spacing: 5
                    clip: true

                    delegate: Rectangle{
                        implicitWidth: ListView.view.width
                        implicitHeight: 20
                        radius: 5
                        color: (root.currentVal ? root.currentVal === modelData.name : root.objectVal?.name === modelData.name) ? Colors.primary : area.containsMouse ? Qt.alpha(Colors.primary, 0.5) : "transparent"
                        CustomText{
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 5
                            anchors.rightMargin: 5
                            content: modelData.name
                            size: 12
                            weight: 600
                            color: (root.currentVal ? root.currentVal === modelData.name : root.objectVal?.name === modelData.name) ? Colors.primaryText : Colors.surfaceVariantText
                        }

                        MouseArea{
                            id: area
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked:{
                                morph.close()
                                root.currentVal = modelData.name
                                root.listChildClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
