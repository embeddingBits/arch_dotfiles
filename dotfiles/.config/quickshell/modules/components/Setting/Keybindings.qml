import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import QtQuick.Controls

Item{
    id: root
    anchors.fill: parent
    anchors.margins: 5

    // Parsing lives in ServiceKeybinds so this page and the cheat sheet
    // overlay cannot drift apart.
    readonly property var keybindingGroups: ServiceKeybinds.groups

    Flickable{
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout{
            id: column
            width: parent.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            spacing: 0

            RowLayout{
                spacing: 10
                MaterialIconSymbol{
                    content: "keyboard"
                    iconSize: 20
                }

                CustomText{
                    content: "Keybindings"
                    size: 20
                    color: Colors.primary
                }
            }

            CustomText{
                Layout.topMargin: 5
                content: "All configured keybindings from your Hyprland config"
                size: 14
                color: Colors.outline
            }

            Repeater{
                model: root.keybindingGroups

                delegate: ColumnLayout{
                    Layout.fillWidth: true
                    spacing: 0

                    property var group: modelData

                    CustomText{
                        Layout.topMargin: 20
                        content: group.name
                        size: 16
                        color: Colors.primary
                    }

                    Rectangle{
                        Layout.topMargin: 8
                        Layout.fillWidth: true
                        Layout.preferredHeight: bindCol.implicitHeight + 10
                        radius: 12
                        color: Colors.surfaceContainerHigh

                        ColumnLayout{
                            id: bindCol
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 0

                            Repeater{
                                model: group.binds

                                delegate: Item{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35

                                    RowLayout{
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        CustomText{
                                            Layout.fillWidth: true
                                            content: modelData.description
                                            size: 12
                                        }

                                        Row{
                                            spacing: 4

                                            Repeater{
                                                model: modelData.shortcut.split(" + ")

                                                delegate: Rectangle{
                                                    width: keyLabel.implicitWidth + 14
                                                    height: 22
                                                    radius: 5
                                                    color: Colors.surfaceContainer
                                                    border.color: Colors.outline
                                                    border.width: 1

                                                    CustomText{
                                                        id: keyLabel
                                                        anchors.centerIn: parent
                                                        content: modelData
                                                        size: 10
                                                        font.family: "monospace"
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle{
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        height: 1
                                        color: Colors.outline
                                        opacity: 0.2
                                        visible: index < group.binds.length - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item{ Layout.preferredHeight: 20 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }
}
