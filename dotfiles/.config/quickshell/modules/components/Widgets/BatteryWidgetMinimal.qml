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
    configKey: "battery"
    defaultPos: Qt.point(600, 200)
    implicitWidth: 190
    implicitHeight: 68

    readonly property real pct: ServiceUPower.powerLevel
    readonly property bool charging: ServiceUPower.isCharging
    readonly property color levelColor: {
        if (pct < 0.15) return Qt.color(Colors.error)
        if (pct < 0.30) return Qt.color(Colors.tertiary)
        return Qt.color(Colors.primary)
    }

    // ── Background card ────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // Subtle level fill — tinted from left edge. Kept light: at 100% it
        // covers the whole card, and with a near-white primary a heavier tint
        // reads as a different surface colour rather than a fill.
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.pct
            radius: parent.radius
            color: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.09)
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }
    }

    // ── Content ────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10

        // Icon badge
        Item {
            implicitWidth: 40; implicitHeight: 40

            MaterialShapes.ShapeCanvas {
                anchors.fill: parent
                roundedPolygon: MaterialShapeFn.getCookie6Sided()
                color: Qt.rgba(root.levelColor.r, root.levelColor.g, root.levelColor.b, 0.22)
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: root.charging ? "bolt" : (
                    root.pct < 0.15 ? "battery_alert" :
                    root.pct < 0.35 ? "battery_2_bar" :
                    root.pct < 0.55 ? "battery_3_bar" :
                    root.pct < 0.75 ? "battery_5_bar" : "battery_full"
                )
                iconSize: 20
                customColor: root.levelColor

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.charging
                    NumberAnimation { to: 0.2; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }

        // Percentage + status
        ColumnLayout {
            spacing: -1
            CustomText {
                content: Math.round(root.pct * 100) + "%"
                size: 22; weight: 700; customColor: root.levelColor
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }
            CustomText {
                content: root.charging
                    ? (ServiceUPower.timeToFull.length > 0 ? ServiceUPower.timeToFull : "Charging")
                    : "On Battery"
                size: 10; customColor: Colors.outline
            }
        }

        Item { Layout.fillWidth: true }

        // Health
        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            MaterialIconSymbol {
                Layout.alignment: Qt.AlignHCenter
                content: "favorite"; iconSize: 12
                customColor: ServiceUPower.health > 0.8 ? Colors.primary : Colors.error
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: Math.round(ServiceUPower.health * 100) + "%"
                size: 10; customColor: Colors.outline
            }
        }
    }
}
