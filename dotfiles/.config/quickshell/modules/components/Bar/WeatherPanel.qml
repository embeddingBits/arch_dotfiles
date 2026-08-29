import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item{
    id: root
    anchors.fill: parent
    signal closed
    property bool compact: false

    opacity: 0
    property real _slideX: 400
    transform: Translate { x: root._slideX }

    NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: true }
    NumberAnimation on _slideX { from: 400; to: 0; duration: 300; easing.type: Easing.OutCubic; running: true }

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ── Header bar ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 50 : 60
            radius: 20
            color: Colors.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                spacing: 10

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    content: "location_on"
                    iconSize: root.compact ? 16 : 20
                    customColor: Colors.primary
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    CustomText {
                        content: ServiceWeather.cityName !== "Unknown"
                            ? ServiceWeather.cityName
                            : ServiceWeather.location
                        size: root.compact ? 12 : 14
                        weight: 700
                    }
                    CustomText {
                        content: Qt.formatDate(new Date(), "dddd, MMMM d")
                        size: root.compact ? 10 : 11
                        customColor: Colors.outline
                    }
                }

                Item { Layout.fillWidth: true }

                Timer {
                    id: tickTimer
                    interval: 60000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: root.compact ? 28 : 36
                    implicitWidth: refreshRow.implicitWidth + 20
                    radius: implicitHeight / 2
                    color: refreshRipple.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainerHighest

                    RowLayout {
                        id: refreshRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIconSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            content: "refresh"
                            iconSize: root.compact ? 13 : 16
                            customColor: ServiceWeather.isLoading ? Colors.primary : Colors.outline
                        }

                        CustomText {
                            Layout.alignment: Qt.AlignVCenter
                            content: {
                                tickTimer.running
                                if (!ServiceWeather.lastUpdated) return ServiceWeather.isLoading ? "updating…" : "—"
                                if (ServiceWeather.isLoading) return "updating…"
                                var mins = Math.floor((new Date() - ServiceWeather.lastUpdated) / 60000)
                                if (mins < 1) return "just now"
                                if (mins < 60) return mins + "m ago"
                                return Math.floor(mins / 60) + "h ago"
                            }
                            size: root.compact ? 10 : 11
                            customColor: Colors.outline
                        }
                    }

                    RippleEffect {
                        id: refreshRipple
                        anchors.fill: parent
                        radius: parent.implicitHeight / 2
                        onClicked: ServiceWeather.refresh()
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: root.compact ? 28 : 36
                    height: root.compact ? 28 : 36
                    radius: width / 2
                    color: closeRipple.containsMouse ? Colors.surfaceContainerHigh : "transparent"

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "close"
                        iconSize: root.compact ? 14 : 18
                    }
                    RippleEffect {
                        id: closeRipple
                        anchors.fill: parent
                        radius: parent.width / 2
                        onClicked: root.closed()
                    }
                }
            }
        }

        // ── Hero card ────────────────────────────────────────────────────
        ClippingWrapperRectangleInternal {
            Layout.fillWidth: true
            implicitHeight: heroColumn.implicitHeight + 40
            radius: 20
            color: Colors.surfaceContainer

            MaterialShapes.ShapeCanvas {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -30
                anchors.topMargin: -25
                implicitWidth: 140
                implicitHeight: 140
                roundedPolygon: MaterialShapeFn.getSoftBurst()
                color: Qt.alpha(Colors.primary, 0.09)
            }

            ColumnLayout {
                id: heroColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins:  20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Item {
                        Layout.preferredWidth:  80
                        Layout.preferredHeight:  80
                        Layout.alignment: Qt.AlignVCenter

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie7Sided()
                            color: Qt.alpha(Colors.primary, 0.18)
                        }
                        Image {
                            anchors.centerIn: parent
                            width:  52
                            height:  52
                            source: IconUtil.getSystemIcon(ServiceWeather.weatherIconPath.svg)
                            sourceSize.width: 52
                            sourceSize.height: 52
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        CustomText {
                            content: ServiceWeather.temperature
                            size:  50
                            color: Colors.primary
                            weight: 900
                        }

                        RowLayout {
                            spacing: 10
                            CustomText {
                                content: "↑ " + (ServiceWeather.useMetric
                                    ? (ServiceWeather.forecastDays[0]?.maxtempC ?? "--") + "°"
                                    : (ServiceWeather.forecastDays[0]?.maxtempF ?? "--") + "°")
                                size:  13
                                color: Colors.inverseSurface
                            }
                            CustomText {
                                content: "↓ " + (ServiceWeather.useMetric
                                    ? (ServiceWeather.forecastDays[0]?.mintempC ?? "--") + "°"
                                    : (ServiceWeather.forecastDays[0]?.mintempF ?? "--") + "°")
                                size:  13
                                color: Colors.outline
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: ServiceWeather.description
                            size:  14
                            color: Colors.inverseSurface
                        }

                        CustomText {
                            content: "Feels like " + ServiceWeather.feelsLike
                            size:  12
                            color: Colors.outline
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Colors.outline
                    opacity: 0.25
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.compact ? 0 : 4
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "wb_sunny",   label: "UV Index",   val: ServiceWeather.uvindex              },
                            { icon: "cloud",      label: "Cloud",      val: ServiceWeather.cloudcover            },
                            { icon: "visibility", label: "Visibility", val: ServiceWeather.visibility + " km"   },
                            { icon: "water_drop", label: "Rain",       val: ServiceWeather.precipitation + " in"}
                        ]

                        delegate: Item {
                            Layout.fillWidth: true
                            implicitHeight: root.compact ? 48 : 58

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 3

                                MaterialIconSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    content: modelData.icon
                                    iconSize: 15
                                    color: Colors.primary
                                }
                                CustomText {
                                    Layout.alignment: Qt.AlignHCenter
                                    content: modelData.val
                                    size:  12
                                    weight: 700
                                    color: Colors.inverseSurface
                                }
                                CustomText {
                                    Layout.alignment: Qt.AlignHCenter
                                    content: modelData.label
                                    size:  10
                                    color: Colors.outline
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Hourly forecast ──────────────────────────────────────────────
        Rectangle{
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 200 : 200
            color: Colors.surfaceContainer
            radius: 20
            clip: true

            ColumnLayout{
                anchors.fill: parent
                anchors.margins: 10
                spacing: root.compact ? 6 : 10

                RowLayout{
                    MaterialIconSymbol{ content: "schedule"; iconSize: root.compact ? 16 : 20 }
                    CustomText{ content: "Hourly forecast"; size: root.compact ? 12 : 14 }
                }

                Item{
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Rectangle{
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: 30
                        z: 2
                        opacity: hourlyList.atXEnd ? 0 : 1
                        Behavior on opacity { EffectsAnim { speed: "fast" } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.alpha(Colors.surfaceContainer, 0) }
                            GradientStop { position: 1.0; color: Colors.surfaceContainer }
                        }
                    }

                    Rectangle{
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 30
                        z: 2
                        opacity: hourlyList.atXBeginning ? 0 : 1
                        Behavior on opacity { EffectsAnim { speed: "fast" } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Colors.surfaceContainer }
                            GradientStop { position: 1.0; color: Qt.alpha(Colors.surfaceContainer, 0) }
                        }
                    }

                ListView{
                    id: hourlyList
                    anchors.fill: parent
                    clip: true
                    orientation: Qt.Horizontal
                    spacing: 10

                    model: ServiceWeather.todayHourly
                    delegate: Item{
                        implicitHeight: parent.height
                        implicitWidth: 50

                        ColumnLayout{
                            anchors.fill: parent
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10

                            Item{
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth:   40
                                Layout.preferredHeight:  40

                                Loader{
                                    active: index === 0
                                    visible: active
                                    anchors.fill: parent
                                    sourceComponent: MaterialShapes.ShapeCanvas{
                                        anchors.fill: parent
                                        roundedPolygon: MaterialShapeFn.getCookie4Sided()
                                        color: Colors.primary
                                    }
                                }

                                CustomText{
                                    anchors.centerIn: parent
                                    content: modelData.tempC
                                    size: 16
                                    color: index === 0 ? Colors.primaryText : Colors.surfaceText
                                }
                            }
                            Item{ Layout.fillHeight: true }

                            Image{
                                Layout.alignment: Qt.AlignCenter
                                source: IconUtil.getSystemIcon(ServiceWeather.getWeatherIcon(modelData.weatherCode).svg)
                                width:   20
                                height: 20
                                sourceSize.width: 20
                                sourceSize.height: 20
                            }

                            CustomText{
                                Layout.alignment: Qt.AlignCenter
                                content: modelData.chanceofrain + "%"
                                size:  14
                                color: Colors.primary
                            }
                            Item{ Layout.fillHeight: true }
                            CustomText{
                                Layout.alignment: Qt.AlignCenter
                                content: modelData.time
                                size: 14
                                color: Colors.outline
                            }
                        }
                    }
                }
                }
            }
        }

        // ── Precipitation + Wind ─────────────────────────────────────────
        RowLayout{
            Layout.fillWidth: true
            spacing: 10

            Rectangle{
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: 20
                color: Colors.surfaceContainer

                ColumnLayout{
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: root.compact ? 6 : 10

                    RowLayout{
                        MaterialIconSymbol{ content: "rainy_heavy"; iconSize: root.compact ? 16 : 20 }
                        CustomText{ content: "Precipitation"; size: root.compact ? 14 : 16 }
                    }
                    RowLayout{
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        CustomText{ content: ServiceWeather.precipitation; size: root.compact ? 24 : 28; color: Colors.primary }
                        CustomText{
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: root.compact ? 3 : 5
                            content: "in"; size: root.compact ? 13 : 16
                        }
                    }

                    RowLayout{
                        Layout.fillWidth: true
                        CustomText{
                            Layout.preferredWidth: 80
                            content: "Total rain for the day"
                            size: root.compact ? 12 : 14
                            elide: Text.ElideNone
                            wrapMode: Text.WordWrap
                        }
                        Item{ Layout.fillWidth: true }
                        Image{
                            Layout.preferredWidth:  root.compact ? 34 : 40
                            Layout.preferredHeight: root.compact ? 34 : 40
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 80
                            sourceSize.height: 80
                            source: IconUtil.getSystemIcon("heavy_rain")
                        }
                    }
                }
            }

            Rectangle{
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: width / 2
                color: Colors.surfaceContainer
                clip: true

                MaterialShapes.ShapeCanvas{
                    rotation: ServiceWeather.windDegree
                    anchors.centerIn: parent
                    implicitHeight: root.compact ? 145 : 150
                    implicitWidth:  root.compact ? 117 : 135
                    roundedPolygon: MaterialShapeFn.getArrow()
                    color: Qt.alpha(Colors.primary, 0.25)
                }

                ColumnLayout{
                    anchors.centerIn: parent
                    spacing: root.compact ? 14 : 20

                    RowLayout{
                        Layout.alignment: Qt.AlignCenter
                        MaterialIconSymbol{ content: "air"; iconSize: root.compact ? 16 : 20 }
                        CustomText{ content: "Wind"; size: root.compact ? 14 : 16 }
                    }

                    CustomText{
                        Layout.alignment: Qt.AlignCenter
                        content: ServiceWeather.windSpeed
                        size: root.compact ? 18 : 20
                        color: Colors.primary
                        weight: 700
                    }

                    CustomText{
                        Layout.alignment: Qt.AlignCenter
                        content: "From " + ServiceWeather.windDirection
                        size: root.compact ? 12 : 14
                    }
                }
            }
        }

        // ── Sunrise/Sunset + Visibility ──────────────────────────────────
        RowLayout{
            Layout.fillWidth: true
            spacing: 10

            Rectangle{
                 Layout.fillHeight: true
                Layout.fillWidth: true
                radius: 20
                color: Colors.surfaceContainer

                ColumnLayout{
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: root.compact ? 6 : 10

                    RowLayout{
                        Layout.alignment: Qt.AlignCenter
                        spacing: root.compact ? 14 : 20

                        Rectangle{
                            Layout.preferredWidth:  root.compact ? 40 : 50
                            Layout.preferredHeight: root.compact ? 40 : 50
                            radius: width / 2
                            color: "#FFE97D"
                        }
                        ColumnLayout{
                            spacing: 0
                            CustomText{ content: "Sunrise"; size: root.compact ? 14 : 16 }
                            CustomText{ content: ServiceWeather.astronomy.sunrise; size: root.compact ? 12 : 14; color: Colors.outline }
                        }
                    }

                    CustomSpermSeparator{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        frequency: 10
                        color: Colors.outline
                    }

                    RowLayout{
                        Layout.alignment: Qt.AlignCenter
                        spacing: root.compact ? 14 : 20

                        ColumnLayout{
                            spacing: 0
                            CustomText{ content: "Sunset"; size: root.compact ? 14 : 16 }
                            CustomText{ content: ServiceWeather.astronomy.sunset; size: root.compact ? 12 : 14; color: Colors.outline }
                        }
                        Rectangle{
                            Layout.preferredWidth:  root.compact ? 40 : 50
                            Layout.preferredHeight: root.compact ? 40 : 50
                            radius: width / 2
                            color: "#D51C39"
                        }
                    }
                }
            }

            Rectangle{
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: width / 2
                color: Colors.surfaceContainer
                clip: true

                MaterialShapes.ShapeCanvas{
                    anchors.fill: parent
                    anchors.margins: 10
                    roundedPolygon: MaterialShapeFn.getCookie12Sided()
                    color: Qt.alpha(Colors.primary, 0.25)
                }

                ColumnLayout{
                    anchors.centerIn: parent
                    spacing: root.compact ? 6 : 10

                    RowLayout{
                        spacing: 2
                        MaterialIconSymbol{ content: "visibility"; iconSize: root.compact ? 16 : 20 }
                        CustomText{ content: "Visibility"; size: root.compact ? 13 : 14 }
                    }

                    RowLayout{
                        Layout.alignment: Qt.AlignCenter
                        spacing: 5
                        CustomText{
                            content: ServiceWeather.visibility
                            size: root.compact ? 36 : 40
                            color: Colors.primary
                            weight: 700
                        }
                        CustomText{
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: root.compact ? 7 : 10
                            content: "km"; size: root.compact ? 13 : 16
                        }
                    }

                    Item{ Layout.fillHeight: true }
                }
            }
        }

        // ── Humidity + Pressure ──────────────────────────────────────────
        RowLayout{
            Layout.fillWidth: true
            spacing: 10

            ClippingWrapperRectangleInternal{
                 Layout.fillHeight: true
                Layout.fillWidth: true
                radius: 20
                color: Colors.surfaceContainer

                Canvas {
                    id: wave
                    property color color: Qt.alpha(Colors.primary, 0.5)
                    property real amplitude: 3
                    property real frequency: 6
                    property real lineWidth: 0
                    anchors.bottom: parent.bottom
                    implicitWidth: parent.width
                    implicitHeight: parent.height * ServiceWeather.humidity / 100

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                    onColorChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var waveY
                        ctx.beginPath()
                        for (var x = 0; x <= width; x += 1) {
                            waveY = amplitude + amplitude * Math.sin(frequency * 2 * Math.PI * x / width)
                            if (x === 0) ctx.moveTo(x, waveY)
                            else         ctx.lineTo(x, waveY)
                        }
                        ctx.lineTo(width, height)
                        ctx.lineTo(0, height)
                        ctx.closePath()
                        ctx.fillStyle = wave.color
                        ctx.fill()
                    }
                }

                ColumnLayout{
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: root.compact ? 20 : 30

                    RowLayout{
                        MaterialIconSymbol{ content: "humidity_low"; iconSize: root.compact ? 16 : 20 }
                        CustomText{ content: "Humidity"; size: root.compact ? 14 : 16 }
                    }

                    CustomText{
                        content: ServiceWeather.humidity + "%"
                        size: root.compact ? 36 : 40
                        color: Colors.primary
                        weight: 700
                    }

                    Item{ Layout.fillHeight: true }
                }
            }

            Rectangle{
                  Layout.fillHeight: true
                Layout.fillWidth: true
                radius: width / 2
                color: Colors.surfaceContainer
                clip: true

                CustomGaugeProgress {
                    anchors.centerIn: parent
                    width:  Math.max(40, parent.width - 16)
                    height: width
                    progress: ServiceWeather.pressure
                    thickness: 8
                    gap: 0.1
                    showData: false
                    sperm: false

                    ColumnLayout{
                        anchors.centerIn: parent
                        spacing: root.compact ? 3 : 4

                        RowLayout{
                            spacing: 2
                            MaterialIconSymbol{ content: "compress"; iconSize: root.compact ? 16 : 20 }
                            CustomText{ content: "Pressure"; size: root.compact ? 12 : 14 }
                        }

                        CustomText{
                            Layout.alignment: Qt.AlignCenter
                            content: ServiceWeather.pressureInches
                            size: root.compact ? 26 : 30
                            color: Colors.primary
                            weight: 700
                        }

                        CustomText{
                            Layout.alignment: Qt.AlignCenter
                            content: "in"; size: root.compact ? 15 : 18
                        }
                    }
                }
            }
        }

    }
}
