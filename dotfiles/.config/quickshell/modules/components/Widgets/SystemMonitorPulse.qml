import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// CPU history as the hero, with the other metrics demoted to a footer strip.
// The existing default/compact styles are both gauge grids — this one is about
// the trend over time rather than the instant reading.
WidgetHost {
    id: root
    configKey: "sysMonitor"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(120, 120)

    // Previews read canned values and never start the pollers
    readonly property var si: root.preview ? PreviewData : ServiceSystemInfo

    Component.onCompleted: {
        root.si.retain()   // no-op on PreviewData
        if (root.preview) {
            // Canned curve so the gallery card reads as a chart rather than a flat line
            const seed = [22, 28, 25, 34, 44, 39, 48, 61, 55, 42, 38, 46, 52, 49,
                          41, 35, 30, 27, 33, 45, 58, 66, 59, 47, 40, 36, 31, 42]
            for (let i = 0; i < seed.length; i++) cpuSpark.addValue(seed[i])
        }
    }
    Component.onDestruction: root.si.release()

    readonly property string loadColor: {
        const c = root.si.cpuUsage
        if (c > 0.85) return Colors.error
        if (c > 0.60) return Colors.tertiary
        return Colors.primary
    }

    Connections {
        target: ServiceSystemInfo
        enabled: !root.preview
        function onCpuUsageChanged() {
            cpuSpark.addValue(root.si.cpuUsage * 100)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 8

            MaterialIconSymbol { content: "monitoring"; iconSize: 16; customColor: Colors.primary }
            CustomText { content: "Load"; size: 13; customColor: Colors.primary }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol { content: "thermostat"; iconSize: 14; customColor: Colors.outline }
            CustomText {
                content: Math.round(root.si.cpuTemp) + "°C"
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Hero reading ──────────────────────────────────────────────
        RowLayout {
            id: hero
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.top: header.bottom
            anchors.topMargin: 6
            spacing: 8

            CustomText {
                content: Math.round(root.si.cpuUsage * 100) + "%"
                size: 34
                weight: 400
                customColor: root.loadColor
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 7
                content: "CPU"
                size: 12
                customColor: Colors.outline
            }
        }

        // ── History ───────────────────────────────────────────────────
        CustomSparkline {
            id: cpuSpark
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.top: hero.bottom
            anchors.topMargin: 4
            height: 46
            maxPoints: 60
            lineColor: root.loadColor
            lineWidth: 1.5
            filled: true
        }

        // ── Footer metrics ────────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.bottomMargin: 14
            spacing: 0

            Repeater {
                model: [
                    { icon: "memory_alt", label: "RAM",  value: Math.round(root.si.memUsage  * 100) + "%" },
                    { icon: "auto_awesome_mosaic", label: "GPU", value: Math.round(root.si.gpuUsage * 100) + "%" },
                    { icon: "hard_drive", label: "DISK", value: Math.round(root.si.diskUsage * 100) + "%" }
                ]

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIconSymbol {
                        content: modelData.icon
                        iconSize: 13
                        customColor: Colors.outline
                    }
                    CustomText { content: modelData.label; size: 11; customColor: Colors.outline }
                    CustomText { content: modelData.value; size: 12 }
                }
            }
        }
    }
}
