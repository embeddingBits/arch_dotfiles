import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 14
    spacing: 8
    signal backClicked

    opacity: 0
    EffectsAnim on opacity {
        speed: "slow"
        from: 0; to: 1
        running: true
    }

    readonly property var descriptions: [
        "Lowest power draw",
        "Default balance",
        "Maximum performance"
    ]

    CustomText {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        content: "Modes"
        size: 17
        weight: 700
        horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
        model: ServiceUPower.powerProfiles

        delegate: Rectangle {
            id: modeRow
            required property var modelData
            required property int index

            readonly property bool active: ServiceUPower.powerProfile === modeRow.index

            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 18
            color: modeRow.active ? Qt.alpha(Colors.primary, 0.18)
                 : modeArea.containsMouse ? Colors.surfaceContainerHighest
                 : Colors.surfaceContainerHigh
            Behavior on color {
                EffectsColorAnim {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 14
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: modeRow.active ? Colors.primary : Colors.surfaceContainerHighest
                    Behavior on color {
                        EffectsColorAnim {}
                    }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: modeRow.modelData.icon
                        iconSize: 19
                        customColor: modeRow.active ? Colors.primaryText : Colors.surfaceVariantText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    CustomText {
                        Layout.fillWidth: true
                        content: modeRow.modelData.name
                        size: 14
                        weight: 700
                        elide: Text.ElideRight
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: modeRow.active ? "On"
                            : (root.descriptions[modeRow.index] ?? "Off")
                        size: 11
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: modeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ServiceUPower.setPowerProfile(modeRow.index)
            }
        }
    }

    Item { Layout.fillHeight: true }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.preferredHeight: 40
            Layout.preferredWidth: doneLabel.implicitWidth + 40
            radius: 20
            color: Colors.primary

            CustomText {
                id: doneLabel
                anchors.centerIn: parent
                content: "Done"
                size: 13
                weight: 700
                customColor: Colors.primaryText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backClicked()
            }
        }
    }
}
