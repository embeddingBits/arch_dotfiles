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

WidgetHost {
    id: root
    configKey: "profileCard"
    tile: WidgetSizes.strip
    defaultPos: Qt.point(100, 400)

    Component.onCompleted: ServiceSystemInfo.getUptime()

    // ServiceSystemInfo only refreshes uptime when getUptime() is called, and its
    // _refCount timers drive cpu/mem/disk polling we don't need here — so poll just this.
    Timer {
        interval: 60000
        repeat: true
        running: !root.preview
        onTriggered: ServiceSystemInfo.getUptime()
    }

    // ── Identity ──────────────────────────────────────────────────────
    readonly property string userName: {
        const u = Quickshell.env("USER") ?? ""
        return u.length > 0 ? u.charAt(0).toUpperCase() + u.slice(1) : "user"
    }

    property string hostName: ""

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostName = text().trim()
    }

    // Re-evaluated every minute via the ServiceClock.minute dependency
    readonly property string greeting: {
        ServiceClock.minute
        const h = new Date().getHours()
        if (h < 5)  return "Still up,"
        if (h < 12) return "Good morning,"
        if (h < 17) return "Good afternoon,"
        if (h < 21) return "Good evening,"
        return "Good night,"
    }

    // ── Card ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // ── Avatar ────────────────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 80
                implicitHeight: 80

                Item {
                    id: avatarMask
                    anchors.centerIn: parent
                    width: 80; height: 80
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
                    anchors.centerIn: parent
                    width: 80; height: 80
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.surfaceContainerHighest
                    }

                    Image {
                        anchors.fill: parent
                        sourceSize.width: 160
                        sourceSize.height: 160
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

            // ── Text column ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                CustomText {
                    content: root.greeting
                    size: 12
                    customColor: Colors.outline
                }

                CustomText {
                    Layout.fillWidth: true
                    Layout.topMargin: -2
                    content: root.userName
                    size: 26
                    weight: 700
                    customColor: Colors.primary
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    implicitHeight: 1
                    color: Colors.outlineVariant
                    opacity: 0.4
                }

                // Single row spread to both edges — stacking these left-aligned
                // left the right third of the card empty.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIconSymbol { content: "schedule"; iconSize: 13; customColor: Colors.primary }
                    CustomText {
                        content: "up " + (ServiceSystemInfo.uptime ?? "—")
                        size: 12
                        customColor: Colors.outline
                    }

                    Item { Layout.fillWidth: true; implicitWidth: 10 }

                    MaterialIconSymbol { content: "dns"; iconSize: 13; customColor: Colors.primary }
                    CustomText {
                        content: (Quickshell.env("USER") ?? "user") + "@" + root.hostName
                        size: 12
                        customColor: Colors.outline
                    }
                }
            }
        }
    }
}
