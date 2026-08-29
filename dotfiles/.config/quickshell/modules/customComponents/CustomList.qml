import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings

Rectangle{
    id: root
    property bool isListClicked: false
    property var currentVal
    property var list: []
    color: Colors.surfaceContainerHighest
    radius: 10
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
        //visible: !root.isListClicked && root.height === 30
        anchors.fill: parent
        anchors.margins: 5
        anchors.leftMargin: 10
        CustomText{
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            content: root.currentVal
            size: 12
            weight: 600
        }

        MaterialIconSymbol{
            content: "keyboard_arrow_down"
            iconSize: 20
        } 

    }

    Loader{
        id: listLoader
        active: root.isListClicked
        sourceComponent: PopupWindow{
            id: popup
            anchor.window: layout
            visible: true
            implicitWidth: root.width
            implicitHeight: Math.min(listView.contentHeight + 10, 250)
            color: "transparent"


            HyprlandFocusGrab {
                active: true
                windows: [QsWindow.window]
                onCleared: morph.close()
            }



            property var windowPos: layout?.mapFromItem(root, 0, root.height) ?? Qt.point(0, 0)

            anchor{
                rect.x: windowPos.x
                rect.y: windowPos.y - root.height
            }

            MorphCard{
                id: morph
                anchors.fill: parent

                srcWidth:  root.width
                srcHeight: root.height
                srcRadius: root.radius

                contentHeight: Math.min(listView.contentHeight + 10, 250)
                cardRadius: 10
                cardColor: root.color
                cardBorderWidth: 1
                cardBorderColor: Colors.outline

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
                        color: root.currentVal === modelData.description ? Colors.primary : area.containsMouse ? Qt.alpha(Colors.primary, 0.5) : "transparent"
                        CustomText{
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 5
                            content: modelData.description
                            width: parent.width
                            size: 12
                            weight: 600
                            color: root.currentVal === modelData.description ? Colors.primaryText : Colors.surfaceVariantText
                        }

                        MouseArea{
                            id: area
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked:{
                                morph.close()
                                root.currentVal = modelData.description
                                root.listChildClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ColumnLayout{
    //     visible: root.isListClicked
    //     anchors.fill: parent
    //     anchors.margins: 10
    //
    //     Rectangle{
    //         Layout.preferredWidth: parent.width
    //         Layout.preferredHeight: 30
    //         radius: 10
    //         color: Colors.surfaceContainerHigh
    //
    //         RowLayout{
    //             anchors.fill: parent
    //             anchors.margins: 5
    //             CustomIconImage{
    //                 icon: "search"
    //                 size: 14
    //             }
    //
    //             TextInput{
    //                 Layout.fillWidth: true
    //                 Layout.fillHeight: true
    //                 verticalAlignment: TextInput.AlignVCenter
    //
    //                 focus: true
    //                 clip: true
    //                 text: root.currentVal
    //                 font.pixelSize: 12
    //                 color: Colors.inverseSurface
    //
    //             }
    //         }
    //     }
    //
    //     ListView{
    //         visible: root.isListClicked
    //         Layout.fillHeight: true
    //         Layout.topMargin: 5
    //         orientation: Qt.Vertical
    //         Layout.preferredWidth: parent.width
    //         model: root.list
    //         spacing: 5
    //
    //         delegate: Rectangle{
    //             implicitWidth: ListView.view.width
    //             implicitHeight: 20
    //             radius: 5
    //             color: root.currentVal === modelData.name ? Colors.primary : area.containsMouse ? Qt.alpha(Colors.primary, 0.5) : "transparent"
    //             CustomText{
    //                 anchors.left:parent.left
    //                 anchors.verticalCenter: parent.verticalCenter
    //                 anchors.leftMargin: 5
    //                 content: modelData.name
    //                 width: text.width
    //                 size: 12
    //                 weight: 600
    //                 color: root.currentVal === modelData.name ? Colors.primaryText : Colors.surfaceVariantText 
    //             }
    //
    //             MouseArea{
    //                 id: area
    //                 anchors.fill: parent
    //                 cursorShape: Qt.PointingHandCursor
    //                 hoverEnabled: true
    //
    //                 onClicked:{
    //                     root.isListClicked = false
    //
    //                     root.currentVal = modelData.name
    //                     root.listChildClicked(modelData.name)
    //                 }
    //             }
    //         }
    //     }
    //
    // }
}
