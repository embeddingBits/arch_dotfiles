import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

// Top-left weather readout. Collapses to nothing until ServiceWeather has data,
// so a failed fetch leaves the corner empty rather than showing "No data".
Rectangle {
    id: root

    visible: ServiceWeather.currentCondition !== null
    implicitWidth: visible ? row.implicitWidth + 32 : 0
    implicitHeight: visible ? 62 : 0
    radius: 20

    color: Qt.alpha(Colors.surfaceContainer, 0.55)
    border.width: 1
    border.color: Qt.alpha(Colors.outlineVariant, 0.35)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12

        MaterialIconSymbol {
            content: ServiceWeather.weatherIconPath.icon
            iconSize: 30
            customColor: Colors.primary
        }

        ColumnLayout {
            spacing: 1

            RowLayout {
                spacing: 6
                CustomText {
                    content: ServiceWeather.temperature
                    size: 18
                    weight: 700
                }
                CustomText {
                    content: ServiceWeather.description
                    size: 12
                    weight: 500
                    customColor: Colors.outline
                }
            }

            CustomText {
                content: ServiceWeather.cityName
                size: 11
                weight: 500
                customColor: Colors.outline
            }
        }
    }
}
