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
    implicitWidth: 200
    implicitHeight: 110

    // Left accent bar — only visual element besides text
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        radius: 2
        color: Colors.primary
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Day name
        CustomText {
            content: ServiceClock.day.toUpperCase()
            size: 10
            weight: 700
            customColor: Colors.outline
            font.letterSpacing: 3
        }

        // Date + month/year side by side
        RowLayout {
            spacing: 10
            Layout.topMargin: -2

            CustomText {
                content: ServiceClock.date
                size: 64
                weight: 700
                customColor: Colors.primary
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Qt.alpha(Colors.primary, 0.2)
            }

            ColumnLayout {
                spacing: 1
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 10

                CustomText {
                    content: ServiceClock.month
                    size: 14
                    weight: 600
                    customColor: Colors.surfaceText
                }

                CustomText {
                    content: ServiceClock.year
                    size: 11
                    weight: 400
                    customColor: Colors.outline
                }
            }
        }
    }
}
