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
    configKey: "sysMonitor"
    defaultPos: Qt.point(120, 120)

    // Previews read canned values and never start the pollers
    readonly property var si: root.preview ? PreviewData : ServiceSystemInfo

    // Not yet on the WidgetSizes ladder — see the size audit
    implicitWidth: 265
    implicitHeight: 288

    // TrapezoidChart binds to an array, unlike CustomSparkline's addValue ring
    // buffer, so the history lives here now
    property var netHist: []
    readonly property int netHistLength: 30

    function pushNet(v) {
        root.netHist = root.netHist.concat([v]).slice(-root.netHistLength)
    }

    Component.onCompleted: {
        root.si.retain()   // no-op on PreviewData
        if (root.preview) {
            root.netHist = [140, 220, 180, 90, 310, 420, 260, 180, 120, 200,
                            340, 480, 390, 250, 160, 110, 230, 300, 210, 150]
        }
    }
    Component.onDestruction: root.si.release()

    Connections {
        target: ServiceSystemInfo
        enabled: !root.preview
        function onNetSampled() {
            root.pushNet(root.si.netDownloadBps / 1024)
        }
    }

    // ── Card background ───────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            // ── Header ────────────────────────────────────────────────
            RowLayout {
                spacing: 8

                MaterialShapes.ShapeCanvas {
                    implicitWidth: 28
                    implicitHeight: 28
                    roundedPolygon: MaterialShapeFn.getCookie6Sided()
                    color: Colors.primaryContainer

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "memory"
                        iconSize: 14
                        customColor: Colors.primaryText
                    }
                }

                CustomText { content: "System"; size: 13; weight: 600; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                CustomText {
                    content: root.si.cpuName.length > 0
                        ? root.si.cpuName.split(" ").slice(0, 3).join(" ")
                        : ""
                    size: 9
                    customColor: Colors.outline
                }
            }

            // ── Three arc gauges ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                // ── CPU ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 76

                        CustomGaugeProgress {
                            anchors.fill: parent
                            progress: root.si.cpuUsage
                            thickness: 5
                            gap: 0.3
                            showData: false
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: -2

                            MaterialIconSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                content: "developer_board"
                                iconSize: 13
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: Math.round(root.si.cpuUsage * 100) + "%"
                                size: 15
                                weight: 700
                                customColor: Colors.primary
                            }
                        }
                    }

                    CustomText { Layout.alignment: Qt.AlignHCenter; content: "CPU"; size: 11; customColor: Colors.outline }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: Math.round(root.si.cpuTemp) + "°C"
                        size: 11
                        customColor: root.si.cpuTemp > 80 ? Colors.error : Colors.surfaceText
                    }
                }

                // ── RAM ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 76

                        CustomGaugeProgress {
                            anchors.fill: parent
                            progress: root.si.memUsage
                            thickness: 5
                            gap: 0.3
                            showData: false
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: -2

                            MaterialIconSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                content: "ad_units"
                                iconSize: 13
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: Math.round(root.si.memUsage * 100) + "%"
                                size: 15
                                weight: 700
                                customColor: Colors.primary
                            }
                        }
                    }

                    CustomText { Layout.alignment: Qt.AlignHCenter; content: "RAM"; size: 11; customColor: Colors.outline }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: root.si.memUsedGb.toFixed(1) + " GB"
                        size: 11
                        customColor: Colors.surfaceText
                    }
                }

                // ── GPU ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 76

                        CustomGaugeProgress {
                            anchors.fill: parent
                            progress: root.si.gpuUsage
                            thickness: 5
                            gap: 0.3
                            showData: false
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: -2

                            MaterialIconSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                content: "display_settings"
                                iconSize: 13
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: Math.round(root.si.gpuUsage * 100) + "%"
                                size: 15
                                weight: 700
                                customColor: Colors.primary
                            }
                        }
                    }

                    CustomText { Layout.alignment: Qt.AlignHCenter; content: "GPU"; size: 11; customColor: Colors.outline }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: Math.round(root.si.gpuTemp) + "°C"
                        size: 11
                        customColor: root.si.gpuTemp > 85 ? Colors.error : Colors.surfaceText
                    }
                }
            }

            // ── Separator ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.outlineVariant
                opacity: 0.4
            }

            // ── Network ───────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true

                    MaterialIconSymbol { content: "arrow_downward"; iconSize: 12; customColor: Colors.primary }
                    CustomText {
                        content: root.si.formatNetSpeed(root.si.netDownloadBps)
                        size: 11
                        customColor: Colors.surfaceText
                    }
                    Item { Layout.fillWidth: true }
                    CustomText {
                        content: root.si.formatNetSpeed(root.si.netUploadBps)
                        size: 11
                        customColor: Colors.surfaceText
                    }
                    MaterialIconSymbol { content: "arrow_upward"; iconSize: 12; customColor: Colors.tertiary }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 30

                    CustomSparkline {
                        id: netSparkline
                        anchors.fill: parent
                        values: root.netHist
                        maxPoints: root.netHistLength
                        lineColor: Colors.primary
                        lineWidth: 2
                        logScale: true
                    }
                }
            }

            // ── Disk ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialIconSymbol { content: "hard_drive"; iconSize: 12; customColor: Colors.outline }
                CustomText {
                    content: root.si.diskUsedGb.toFixed(0) + " / " + root.si.diskTotalGb.toFixed(0) + " GB"
                    size: 11
                    customColor: Colors.surfaceText
                }
                Item { Layout.fillWidth: true }

                // Pill progress bar
                Item {
                    implicitWidth: 60
                    implicitHeight: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Colors.surfaceContainerHighest
                    }
                    Rectangle {
                        width: Math.max(6, parent.width * root.si.diskUsage)
                        height: parent.height
                        radius: 3
                        color: root.si.diskUsage > 0.9 ? Colors.error : Colors.primary

                        Behavior on width {
                            NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
