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
    implicitWidth: 240
    implicitHeight: 210

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // ── Header ────────────────────────────────────────────────
            RowLayout {
                spacing: 8
                MaterialShapes.ShapeCanvas {
                    implicitWidth: 26; implicitHeight: 26
                    roundedPolygon: MaterialShapeFn.getCookie6Sided()
                    color: Colors.primaryContainer
                    MaterialIconSymbol {
                        anchors.centerIn: parent; content: "memory"
                        iconSize: 13; customColor: Colors.primaryText
                    }
                }
                CustomText { content: "System"; size: 13; weight: 600; customColor: Colors.primary }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: root.si.cpuName.length > 0
                        ? root.si.cpuName.split(" ").slice(0, 2).join(" ") : ""
                    size: 9; customColor: Colors.outline
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.outlineVariant; opacity: 0.4 }

            // ── Stat rows ─────────────────────────────────────────────
            // CPU
            RowLayout { Layout.fillWidth: true; spacing: 8
                MaterialIconSymbol { content: "developer_board"; iconSize: 13; customColor: Colors.primary }
                CustomText { content: "CPU"; size: 11; customColor: Colors.outline; Layout.preferredWidth: 26 }
                Item {
                    Layout.fillWidth: true; implicitHeight: 6
                    Rectangle { anchors.fill: parent; radius: 3; color: Colors.surfaceContainerHighest }
                    Rectangle {
                        width: Math.max(6, parent.width * root.si.cpuUsage)
                        height: parent.height; radius: 3; color: Colors.primary
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                    }
                }
                CustomText {
                    content: Math.round(root.si.cpuUsage * 100) + "%"
                    size: 11; weight: 600; customColor: Colors.primary; Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
                CustomText {
                    content: Math.round(root.si.cpuTemp) + "°"
                    size: 11; Layout.preferredWidth: 26
                    customColor: root.si.cpuTemp > 80 ? Colors.error : Colors.outline
                }
            }

            // RAM
            RowLayout { Layout.fillWidth: true; spacing: 8
                MaterialIconSymbol { content: "ad_units"; iconSize: 13; customColor: Colors.primary }
                CustomText { content: "RAM"; size: 11; customColor: Colors.outline; Layout.preferredWidth: 26 }
                Item {
                    Layout.fillWidth: true; implicitHeight: 6
                    Rectangle { anchors.fill: parent; radius: 3; color: Colors.surfaceContainerHighest }
                    Rectangle {
                        width: Math.max(6, parent.width * root.si.memUsage)
                        height: parent.height; radius: 3; color: Colors.primary
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                    }
                }
                CustomText {
                    content: Math.round(root.si.memUsage * 100) + "%"
                    size: 11; weight: 600; customColor: Colors.primary; Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
                CustomText {
                    content: root.si.memUsedGb.toFixed(1) + "G"
                    size: 11; customColor: Colors.outline; Layout.preferredWidth: 26
                }
            }

            // GPU
            RowLayout { Layout.fillWidth: true; spacing: 8
                MaterialIconSymbol { content: "display_settings"; iconSize: 13; customColor: Colors.primary }
                CustomText { content: "GPU"; size: 11; customColor: Colors.outline; Layout.preferredWidth: 26 }
                Item {
                    Layout.fillWidth: true; implicitHeight: 6
                    Rectangle { anchors.fill: parent; radius: 3; color: Colors.surfaceContainerHighest }
                    Rectangle {
                        width: Math.max(6, parent.width * root.si.gpuUsage)
                        height: parent.height; radius: 3; color: Colors.primary
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                    }
                }
                CustomText {
                    content: Math.round(root.si.gpuUsage * 100) + "%"
                    size: 11; weight: 600; customColor: Colors.primary; Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
                CustomText {
                    content: Math.round(root.si.gpuTemp) + "°"
                    size: 11; Layout.preferredWidth: 26
                    customColor: root.si.gpuTemp > 85 ? Colors.error : Colors.outline
                }
            }

            // Disk
            RowLayout { Layout.fillWidth: true; spacing: 8
                MaterialIconSymbol { content: "hard_drive"; iconSize: 13; customColor: Colors.primary }
                CustomText { content: "Disk"; size: 11; customColor: Colors.outline; Layout.preferredWidth: 26 }
                Item {
                    Layout.fillWidth: true; implicitHeight: 6
                    Rectangle { anchors.fill: parent; radius: 3; color: Colors.surfaceContainerHighest }
                    Rectangle {
                        width: Math.max(6, parent.width * root.si.diskUsage)
                        height: parent.height; radius: 3
                        color: root.si.diskUsage > 0.9 ? Colors.error : Colors.primary
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                    }
                }
                CustomText {
                    content: root.si.diskUsedGb.toFixed(0) + "G"
                    size: 11; weight: 600; customColor: Colors.primary; Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
                CustomText {
                    content: "/" + root.si.diskTotalGb.toFixed(0) + "G"
                    size: 11; customColor: Colors.outline; Layout.preferredWidth: 30
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.outlineVariant; opacity: 0.4 }

            // ── Network ───────────────────────────────────────────────
            RowLayout { Layout.fillWidth: true; spacing: 4
                MaterialIconSymbol { content: "arrow_downward"; iconSize: 11; customColor: Colors.primary }
                CustomText {
                    content: root.si.formatNetSpeed(root.si.netDownloadBps)
                    size: 11; customColor: Colors.surfaceText
                }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: root.si.formatNetSpeed(root.si.netUploadBps)
                    size: 11; customColor: Colors.surfaceText
                }
                MaterialIconSymbol { content: "arrow_upward"; iconSize: 11; customColor: Colors.tertiary }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
