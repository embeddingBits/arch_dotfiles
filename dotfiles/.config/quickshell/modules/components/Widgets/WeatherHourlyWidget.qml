import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Today's temperature curve with rain chance underneath.
//
// ServiceWeather already fetches the hourly forecast and nothing displayed it —
// the other weather widgets all show a single moment. Temperatures arrive as
// strings with the degree sign attached, so they have to be stripped before
// anything can be plotted.
WidgetHost {
    id: root
    configKey: "weatherHourly"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(420, 200)

    readonly property bool metric: SettingsConfig.weather.useMetric ?? true

    readonly property var hours: {
        const h = ServiceWeather.todayHourly ?? []
        var out = []
        for (var i = 0; i < h.length; i++) {
            const raw = root.metric ? h[i].tempC : h[i].tempF
            const t = parseInt(String(raw).replace("°", ""), 10)
            if (isNaN(t)) continue
            out.push({
                time: h[i].time,
                temp: t,
                rain: parseInt(h[i].chanceofrain ?? 0, 10) || 0
            })
        }
        return out
    }

    readonly property bool hasData: root.hours.length >= 2

    // Horizontal inset of the plot area, shared by the canvas and the hour
    // labels so a label sits under the point it names.
    readonly property int chartPadX: 7

    readonly property int minTemp: {
        if (!root.hasData) return 0
        var m = root.hours[0].temp
        for (var i = 1; i < root.hours.length; i++) m = Math.min(m, root.hours[i].temp)
        return m
    }
    readonly property int peakRain: {
        if (!root.hasData) return 0
        var m = 0
        for (var i = 0; i < root.hours.length; i++) m = Math.max(m, root.hours[i].rain)
        return m
    }

    readonly property var gridTemps: {
        if (!root.hasData) return []
        const mid = Math.round((root.minTemp + root.maxTemp) / 2)
        const out = [root.minTemp]
        if (mid !== root.minTemp && mid !== root.maxTemp) out.push(mid)
        if (root.maxTemp !== root.minTemp) out.push(root.maxTemp)
        return out
    }

    readonly property int maxTemp: {
        if (!root.hasData) return 0
        var m = root.hours[0].temp
        for (var i = 1; i < root.hours.length; i++) m = Math.max(m, root.hours[i].temp)
        return m
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            y: 14
            spacing: 6

            CustomText { content: "Today"; size: 13; customColor: Colors.primary }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol {
                visible: root.hasData && root.peakRain > 0
                content: "water_drop"
                iconSize: 12
                customColor: Colors.tertiary
            }

            CustomText {
                visible: root.hasData && root.peakRain > 0
                content: root.peakRain + "%"
                size: 12
                customColor: Colors.tertiary
            }

            CustomText {
                content: root.hasData ? root.maxTemp + "° / " + root.minTemp + "°" : "—"
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Chart ─────────────────────────────────────────────────────
        TrapezoidChart {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 14
            y: 42
            height: 126
            visible: root.hasData

            values: root.hours.map(h => h.temp)
            labels: root.hours.map((h, i) => i % 2 === 0 ? h.time.replace(" ", "") : "")

            lo: root.minTemp - Math.max(2, Math.round((root.maxTemp - root.minTemp) * 0.4))
            hi: root.maxTemp + 1
            gridValues: root.gridTemps
            suffix: "°"
            barColor: Colors.primary
        }

        // ── Empty state ───────────────────────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            visible: !root.hasData

            MaterialIconSymbol {
                Layout.alignment: Qt.AlignHCenter
                content: "cloud_off"
                iconSize: 26
                customColor: Colors.outline
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: "No hourly forecast"
                size: 12
                customColor: Colors.outline
            }
        }
    }
}
