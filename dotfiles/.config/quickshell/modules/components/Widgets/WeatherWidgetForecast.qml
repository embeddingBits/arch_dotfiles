import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "weatherForecast"
    defaultPos: Qt.point(120, 300)
    implicitWidth: 320
    implicitHeight: 185

    function getDayName(dateStr) {
        if (!dateStr) return "---"
        const d = new Date(dateStr)
        return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d.getDay()]
    }

    function getDayIcon(day) {
        if (!day || !day.hourly || day.hourly.length === 0) return ""
        const h = day.hourly[Math.min(4, day.hourly.length - 1)]
        return IconUtil.getSystemIcon(ServiceWeather.getWeatherIcon(h.weatherCode).svg)
    }

    function getDayMax(day) {
        if (!day) return "--°"
        return (ServiceWeather.useMetric ? (day.maxtempC ?? "--") : (day.maxtempF ?? "--")) + "°"
    }

    function getDayMin(day) {
        if (!day) return "--°"
        return (ServiceWeather.useMetric ? (day.mintempC ?? "--") : (day.mintempF ?? "--")) + "°"
    }

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Colors.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Current weather header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                    width: 44
                    height: 44
                    sourceSize.width: 44
                    sourceSize.height: 44
                    source: IconUtil.getSystemIcon(ServiceWeather.weatherIconPath.svg)
                }

                ColumnLayout {
                    spacing: 1

                    CustomText {
                        content: ServiceWeather.temperature
                        size: 30
                        weight: 700
                        customColor: Colors.surfaceText
                    }

                    CustomText {
                        content: ServiceWeather.description
                        size: 11
                        customColor: Colors.outline
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    CustomText {
                        Layout.alignment: Qt.AlignRight
                        content: ServiceWeather.cityName
                        size: 12
                        weight: 600
                        customColor: Colors.surfaceText
                    }

                    CustomText {
                        Layout.alignment: Qt.AlignRight
                        content: Qt.formatDate(new Date(), "dddd")
                        size: 11
                        customColor: Colors.outline
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.outlineVariant
                opacity: 0.4
            }

            // 3-day forecast row
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: Math.min(3, ServiceWeather.forecastDays?.length ?? 0)

                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 72

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: index === 0
                                    ? "Today"
                                    : getDayName(ServiceWeather.forecastDays[index]?.date)
                                size: 11
                                weight: 600
                                customColor: index === 0 ? Colors.primary : Colors.outline
                            }

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                width: 28
                                height: 28
                                sourceSize.width: 28
                                sourceSize.height: 28
                                source: getDayIcon(ServiceWeather.forecastDays[index])
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 5

                                CustomText {
                                    content: getDayMax(ServiceWeather.forecastDays[index])
                                    size: 13
                                    weight: 700
                                    customColor: Colors.surfaceText
                                }

                                CustomText {
                                    content: getDayMin(ServiceWeather.forecastDays[index])
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }
                        }

                        Rectangle {
                            visible: index < 2
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 36
                            color: Colors.outlineVariant
                            opacity: 0.35
                        }
                    }
                }
            }
        }
    }
}
