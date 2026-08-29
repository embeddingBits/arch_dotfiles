import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings

PopupWindow{
    id: root
    implicitWidth: 240
    implicitHeight: container.implicitHeight + 10
    //implicitHeight: 320
    visible: true
    signal close
    color: "transparent"
    property QsMenuHandle menuData
    property real iconCenterX: 0
    anchor{
        window: layout
        rect.x: iconCenterX - root.implicitWidth / 2
        rect.y: sectionsRow.y + utility.y + utility.height + (SettingsConfig.general.barMode === "pill" ? 8 : 4)
    }

    HyprlandFocusGrab {
        active: true
        windows: [QsWindow.window]
        onCleared: root.close()
    }


    Item{
        id: container
        anchors{
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 2
        }
        implicitHeight: stackView.implicitHeight

        scale: 0.8
        opacity: 0

        NumberAnimation on opacity{
            from: 0
            to: 1
            duration: 100
            running: true
        }

        NumberAnimation on scale{
            from: 0.8
            to: 1
            duration: 100
            running: true
        }

        StackView{
            id: stackView

            implicitHeight: currentItem.implicitHeight
            implicitWidth: currentItem.implicitWidth

            pushEnter: Transition {
                NumberAnimation {
                    duration: 0
                }                    
            }

            pushExit: Transition {
                NumberAnimation {
                    duration: 0
                }                    
            }

            popEnter: Transition {
                NumberAnimation {
                    duration: 0
                }                    
            }

            popExit: Transition {
                NumberAnimation {
                    duration: 0
                }                    
            }


            initialItem: SubMenu{
                handle: root.menuData
            }

            component SubMenu: Column{
                property QsMenuHandle handle
                property bool show
                property bool isSubMenu

                spacing: 4

                opacity: show ? 1 : 0
                scale: show ? 1 : 0.8

                Component.onCompleted: show = true
                StackView.onActivating: show = true
                StackView.onDeactivating: show = false

                QsMenuOpener{
                    id: menuOpener
                    menu: handle
                }




                Behavior on opacity{
                    NumberAnimation{
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on scale{
                    NumberAnimation{
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Loader{
                    active: isSubMenu
                    visible: active

                    sourceComponent: Rectangle{
                        implicitWidth: 230
                        implicitHeight: 40
                        radius: 15
                        color: Colors.surface

                        RowLayout{
                            anchors.fill: parent
                            anchors.margins: 5
                            anchors.leftMargin: 10

                            MaterialIconSymbol{
                                content: "arrow_back"
                                iconSize: 18
                            }

                            CustomText{
                                Layout.fillWidth: true
                                content: "Back"
                                size: 12
                            }
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stackView.pop()
                        }
                    }
                }

                Repeater {
                    model: ScriptModel {
                        values: {
                            var _ = menuOpener.children.values.length
                            var groups = []
                            var current = []
                            var c = menuOpener.children.values
                            for (var i = 0; i < c.length; i++) {
                                if (!c[i]) continue
                                if (c[i].isSeparator) {
                                    if (current.length > 0) { groups.push(current); current = [] }
                                } else {
                                    current.push(c[i])
                                }
                            }
                            if (current.length > 0) groups.push(current)
                            return groups
                        }
                    }

                    Rectangle {
                        implicitWidth: 230
                        implicitHeight: groupCol.implicitHeight + 10
                        radius: 15
                        color: Colors.surface
                        clip: true

                        Column {
                            id: groupCol
                            anchors.fill: parent
                            anchors.margins: 5

                            Repeater {
                                model: modelData

                                Rectangle {
                                    id: itemRow
                                    property var entry: modelData
                                    width: 220
                                    height: 35
                                    radius: 10
                                    color: itemArea.containsMouse ? Colors.surfaceContainer : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        anchors.leftMargin: 10
                                        spacing: 10

                                        CustomText {
                                            Layout.fillWidth: true
                                            content: itemRow.entry.text
                                            size: 12
                                        }
                                        Loader {
                                            active: itemRow.entry.hasChildren
                                            visible: active
                                            sourceComponent: MaterialIconSymbol {
                                                content: "chevron_right"
                                                iconSize: 18
                                            }
                                        }
                                        Loader {
                                            active: itemRow.entry.buttonType === 1
                                            visible: active
                                            sourceComponent: CustomCheckbox {
                                                checkState: itemRow.entry.checkState === 2 ? true : false
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: itemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (itemRow.entry.hasChildren) {
                                                stackView.push(subMenuComp.createObject(null, {
                                                    handle: itemRow.entry,
                                                    isSubMenu: true
                                                }))
                                            } else {
                                                root.close()
                                                itemRow.entry.triggered()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }


            }

            Component{
                id: subMenuComp
                SubMenu{}
            }
        }




    }
}
