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
    implicitWidth: row.implicitWidth + 48
    implicitHeight: 72

    Rectangle {
        anchors.fill: parent
        radius: 36
        color: Colors.surface

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 20

            // Day name
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.day.slice(0, 3).toUpperCase()
                    size: 10
                    weight: 700
                    color: Colors.outline
                    font.letterSpacing: 1.5
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceClock.month.slice(0, 3).toUpperCase()
                    size: 10
                    weight: 700
                    color: Colors.primary
                    font.letterSpacing: 1.5
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 36
                color: Qt.alpha(Colors.outline, 0.25)
            }

            // Date number
            CustomText {
                content: ServiceClock.date
                size: 38
                weight: 700
                color: Colors.surfaceText
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 36
                color: Qt.alpha(Colors.outline, 0.25)
            }

            // Year
            CustomText {
                content: ServiceClock.year
                size: 12
                weight: 600
                color: Colors.outline
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }
        }
    }
}
