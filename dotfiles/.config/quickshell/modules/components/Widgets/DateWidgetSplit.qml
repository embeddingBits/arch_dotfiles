import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "dateWidget"
    defaultPos: Qt.point(300, 300)
    implicitWidth: 210
    implicitHeight: 110

    Row {
        anchors.fill: parent
        spacing: 0

        // Left — date number on primary background
        Rectangle {
            width: 90
            height: parent.height
            topLeftRadius: 22
            bottomLeftRadius: 22
            color: Colors.primary

            CustomText {
                anchors.centerIn: parent
                content: ServiceClock.date
                size: 54
                weight: 700
                color: Colors.primaryText
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.2)
            }
        }

        // Right — day name + month + year stacked
        Rectangle {
            width: parent.width - 90
            height: parent.height
            topRightRadius: 22
            bottomRightRadius: 22
            color: Colors.surfaceContainerHigh

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 3

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.day.toUpperCase().slice(0, 3)
                    size: 10
                    weight: 700
                    color: Colors.outline
                    font.letterSpacing: 2
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.month
                    size: 17
                    weight: 700
                    color: Colors.surfaceText
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.year
                    size: 11
                    color: Colors.outline
                }
            }
        }
    }
}
