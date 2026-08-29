import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Battery as a 270° gauge. Unlike the default (liquid fill) and minimal (bar)
// styles, this one surfaces the live draw from UPower's changeRate — the other
// two only ever show the percentage.
WidgetHost {
    id: root
    configKey: "battery"
    tile: WidgetSizes.small
    defaultPos: Qt.point(600, 200)

    readonly property real pct: ServiceUPower.powerLevel
    readonly property bool charging: ServiceUPower.isCharging

    // String, not color: CustomGaugeProgress takes its colours as strings
    readonly property string levelColor: pct < 0.15 ? Colors.error
                                       : pct < 0.30 ? Colors.tertiary
                                                    : Colors.primary

    // changeRate is signed by direction — magnitude is what we want to show
    readonly property real watts: Math.abs(ServiceUPower.changeRate ?? 0)

    readonly property string statusLine: {
        if (charging)
            return ServiceUPower.timeToFull.length > 0 ? ServiceUPower.timeToFull + " to full"
                                                       : "Charging"
        return "On battery"
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface
    }

    // ── Gauge ─────────────────────────────────────────────────────────
    Item {
        id: gauge
        width: 152; height: 152
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 12

        CustomGaugeProgress {
            anchors.fill: parent
            progress: root.pct
            thickness: 7
            showData: false
            lineColor: root.levelColor
            baseColor: Colors.surfaceContainerHighest
        }

        // The percentage is the whole point — give it the centre alone and put
        // the charge icon down in the footer beside the status it describes.
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: Math.round(root.pct * 100) + "%"
                size: 34
                weight: 400
                customColor: root.levelColor
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -4
                visible: root.watts > 0.05
                content: root.watts.toFixed(1) + " W"
                size: 11
                customColor: Colors.outline
            }
        }
    }

    // ── Footer ────────────────────────────────────────────────────────
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.bottomMargin: 15
        spacing: 6

        MaterialIconSymbol {
            content: root.charging ? "bolt" : (
                root.pct < 0.15 ? "battery_alert" :
                root.pct < 0.35 ? "battery_2_bar" :
                root.pct < 0.55 ? "battery_3_bar" :
                root.pct < 0.75 ? "battery_5_bar" : "battery_full"
            )
            iconSize: 14
            customColor: root.levelColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.charging && !root.preview
                NumberAnimation { to: 0.25; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 800; easing.type: Easing.InOutSine }
            }
        }

        CustomText {
            content: root.statusLine
            size: 12
            customColor: Colors.outline
        }

        Item { Layout.fillWidth: true }

        MaterialIconSymbol {
            content: "favorite"
            iconSize: 12
            customColor: ServiceUPower.health > 0.8 ? Colors.primary : Colors.error
        }
        CustomText {
            content: Math.round(ServiceUPower.health * 100) + "%"
            size: 12
            customColor: Colors.outline
        }
    }
}
