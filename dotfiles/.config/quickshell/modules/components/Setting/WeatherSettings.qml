import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            spacing: 0

            // ── Page header ──────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "partly_cloudy_day"; iconSize: 20 }
                CustomText { content: "Weather"; size: 20; customColor: Colors.primary }
            }

            // ── Location ─────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Location"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "City"; size: 14 }
                        CustomText { content: "City name or coordinates e.g. 51.5,-0.1"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 180; implicitHeight: 32
                        radius: 10
                        color: Colors.surfaceContainerHighest

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 6

                            MaterialIconSymbol { content: "location_on"; iconSize: 16; customColor: Colors.outline }

                            TextInput {
                                id: locationInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: SettingsConfig.weather.location
                                color: Colors.inverseSurface
                                font.pixelSize: 13
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onEditingFinished: {
                                    if (text.trim().length > 0)
                                        SettingsConfig.weather = Object.assign({}, SettingsConfig.weather, { location: text.trim() })
                                }
                            }
                        }
                    }
                }
            }

            // ── Units ────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Units"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Temperature Unit"; size: 14 }
                        CustomText { content: "Applies to temperature, wind speed, and distance"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    M3ButtonGroup {
                        model: [
                            { value: true,  label: "Metric (°C)",   icon: "thermometer" },
                            { value: false, label: "Imperial (°F)", icon: "thermometer" }
                        ]
                        activeCheck: function(v) { return SettingsConfig.weather.useMetric === v }
                        onSegmentClicked: function(v) {
                            SettingsConfig.weather = Object.assign({}, SettingsConfig.weather, { useMetric: v })
                        }
                    }
                }
            }

            // ── Refresh ──────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Refresh"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Refresh Interval"; size: 14 }
                            CustomText { content: "Minutes between automatic updates (min 5)"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            inc: 5; limit: 120
                            Component.onCompleted: val = SettingsConfig.weather.refreshInterval
                            onValChanged: SettingsConfig.weather = Object.assign({}, SettingsConfig.weather, { refreshInterval: val })
                        }
                    }
                }

                // Status card
                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                spacing: 6
                                MaterialIconSymbol {
                                    content: ServiceWeather.hasError ? "error" : "check_circle"
                                    iconSize: 15
                                    customColor: ServiceWeather.hasError ? Colors.error : Colors.outline
                                }
                                CustomText {
                                    content: ServiceWeather.hasError
                                             ? "Last fetch failed"
                                             : "Showing: " + ServiceWeather.cityName
                                    size: 12
                                    customColor: ServiceWeather.hasError ? Colors.error : Colors.outline
                                }
                            }

                            RowLayout {
                                spacing: 6
                                MaterialIconSymbol { content: "info"; iconSize: 15; customColor: Colors.outline }
                                CustomText {
                                    content: "Location changes take effect on the next refresh"
                                    size: 12; customColor: Colors.outline
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 36; implicitHeight: 36
                            radius: 10
                            color: refreshArea.containsMouse ? Colors.primary : Colors.surfaceContainerHighest
                            Behavior on color { ColorAnimation { duration: 150 } }
                            enabled: !ServiceWeather.isLoading

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "refresh"; iconSize: 18
                                customColor: refreshArea.containsMouse ? Colors.primaryText : Colors.outline
                                Behavior on customColor { ColorAnimation { duration: 150 } }
                                RotationAnimation on rotation {
                                    running: ServiceWeather.isLoading
                                    from: 0; to: 360; duration: 800
                                    loops: Animation.Infinite
                                }
                            }

                            MouseArea {
                                id: refreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ServiceWeather.refresh()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }
}
