import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "weatherDetails"
    defaultPos: Qt.point(320, 200)
    implicitWidth: 220
    implicitHeight: 220

    // Cookie4Sided shape — 4 lobes align with the 2×2 tile grid
    MaterialShapes.ShapeCanvas {
        anchors.fill: parent
        roundedPolygon: MaterialShapeFn.getCookie4Sided()
        color: Colors.surfaceContainer
    }

    // 2×2 grid — tile centers align with cookie4 lobe centers (~25%/75% of shape)
    GridLayout {
        anchors.centerIn: parent
        columns: 2
        rows: 2
        columnSpacing: 30
        rowSpacing: 30

        // Humidity
        Rectangle {
            width: 72
            height: 72
            radius: 36
            color: Colors.primaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: "humidity_mid"
                    iconSize: 20
                    customColor: Colors.primary
                    fill: 1
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceWeather.humidity + "%"
                    size: 15
                    weight: 700
                    customColor: Colors.primaryContainerText
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "Humidity"
                    size: 9
                    weight: 500
                    customColor: Colors.primaryContainerText
                    opacity: 0.65
                }
            }
        }

        // Wind
        Rectangle {
            width: 72
            height: 72
            radius: 36
            color: Colors.secondaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: "air"
                    iconSize: 20
                    customColor: Colors.secondary
                    fill: 1
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceWeather.windSpeed.split(" ")[0]
                    size: 15
                    weight: 700
                    customColor: Colors.secondaryContainerText
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "km/h Wind"
                    size: 9
                    weight: 500
                    customColor: Colors.secondaryContainerText
                    opacity: 0.65
                }
            }
        }

        // UV Index
        Rectangle {
            width: 72
            height: 72
            radius: 36
            color: Colors.tertiaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: "wb_sunny"
                    iconSize: 20
                    customColor: Colors.tertiary
                    fill: 1
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceWeather.uvindex
                    size: 15
                    weight: 700
                    customColor: Colors.tertiaryContainerText
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "UV Index"
                    size: 9
                    weight: 500
                    customColor: Colors.tertiaryContainerText
                    opacity: 0.65
                }
            }
        }

        // Feels Like
        Rectangle {
            width: 72
            height: 72
            radius: 36
            color: Colors.surfaceVariant

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: "thermostat"
                    iconSize: 20
                    customColor: Colors.primary
                    fill: 1
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: ServiceWeather.feelsLike
                    size: 15
                    weight: 700
                    customColor: Colors.surfaceVariantText
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "Feels Like"
                    size: 9
                    weight: 500
                    customColor: Colors.surfaceVariantText
                    opacity: 0.65
                }
            }
        }
    }
}
