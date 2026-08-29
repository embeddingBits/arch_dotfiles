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
    tile: WidgetSizes.small
    defaultPos: Qt.point(300, 300)

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            // Day name — small, spaced out, primary
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.day.toUpperCase()
                size: 11
                weight: 700
                color: Colors.primary
                font.letterSpacing: 3
            }

            // Huge date — takes up most of the card
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -6
                content: ServiceClock.date
                size: 115
                weight: 700
                color: Colors.primary
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
            }

            // Month · Year — compact below
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -14
                spacing: 8

                CustomText {
                    content: ServiceClock.month
                    size: 13
                    weight: 600
                    color: Colors.surfaceText
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                }

                Rectangle {
                    implicitWidth: 3
                    implicitHeight: 3
                    radius: 2
                    color: Colors.outline
                }

                CustomText {
                    content: ServiceClock.year
                    size: 13
                    weight: 600
                    color: Colors.outline
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                }
            }
        }
    }
}
