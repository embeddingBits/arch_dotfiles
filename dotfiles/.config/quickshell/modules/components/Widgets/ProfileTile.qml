import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

// Square portrait counterpart to the ProfileCard strip: avatar-led rather than
// text-led, for sitting alongside the other square tiles.
WidgetHost {
    id: root
    configKey: "profileCard"
    tile: WidgetSizes.small
    defaultPos: Qt.point(100, 400)

    Component.onCompleted: ServiceSystemInfo.getUptime()

    Timer {
        interval: 60000
        repeat: true
        running: !root.preview
        onTriggered: ServiceSystemInfo.getUptime()
    }

    readonly property string userName: {
        const u = Quickshell.env("USER") ?? ""
        return u.length > 0 ? u.charAt(0).toUpperCase() + u.slice(1) : "user"
    }

    // Re-evaluated every minute via the ServiceClock.minute dependency
    readonly property string greeting: {
        ServiceClock.minute
        const h = new Date().getHours()
        if (h < 5)  return "Still up"
        if (h < 12) return "Good morning"
        if (h < 17) return "Good afternoon"
        if (h < 21) return "Good evening"
        return "Good night"
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: root.greeting
                size: 11
                customColor: Colors.outline
            }

            // ── Avatar ────────────────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                implicitWidth: 84
                implicitHeight: 84

                Item {
                    id: avatarMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    MaterialShapes.ShapeCanvas {
                        anchors.fill: parent
                        roundedPolygon: MaterialShapeFn.getCookie6Sided()
                        color: "white"
                    }
                }

                Item {
                    id: avatarContent
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.surfaceContainerHighest
                    }

                    Image {
                        anchors.fill: parent
                        sourceSize.width: 168
                        sourceSize.height: 168
                        fillMode: Image.PreserveAspectCrop
                        source: SettingsConfig.general.profile ?? ""
                        visible: status === Image.Ready
                    }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "person"
                        iconSize: 34
                        customColor: Colors.outline
                        visible: (SettingsConfig.general.profile ?? "") === ""
                    }
                }

                MultiEffect {
                    source: avatarContent
                    anchors.fill: avatarContent
                    maskEnabled: true
                    maskSource: avatarMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                content: root.userName
                size: 22
                weight: 700
                customColor: Colors.primary
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 5

                MaterialIconSymbol { content: "schedule"; iconSize: 12; customColor: Colors.primary }
                CustomText {
                    content: "up " + (ServiceSystemInfo.uptime ?? "—")
                    size: 11
                    customColor: Colors.outline
                }
            }
        }
    }
}
