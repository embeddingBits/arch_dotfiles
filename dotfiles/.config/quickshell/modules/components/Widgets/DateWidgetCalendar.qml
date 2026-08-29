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
    implicitWidth: 170
    implicitHeight: 205

    // Card body
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.surface

        // Month header strip
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 58
            topLeftRadius: 20
            topRightRadius: 20
            color: Colors.primaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.month.toUpperCase()
                    size: 14
                    weight: 700
                    color: Colors.primary
                    font.letterSpacing: 2
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.year
                    size: 11
                    color: Colors.outline
                }
            }
        }

        // Date number
        CustomText {
            anchors.top: header.bottom
            anchors.bottom: dayLabel.top
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            content: ServiceClock.date
            size: 86
            weight: 700
            color: Colors.surfaceText
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
            style: Text.Raised
            styleColor: Colors.outline
        }

        // Day of week at bottom
        CustomText {
            id: dayLabel
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            content: ServiceClock.day.toUpperCase()
            size: 11
            weight: 600
            color: Colors.outline
            font.letterSpacing: 2
        }
    }
}
