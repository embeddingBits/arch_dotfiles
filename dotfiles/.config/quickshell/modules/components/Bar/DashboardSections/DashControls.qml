import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

Rectangle{
    id: controleRectangle
    property bool compact: false
    property Item coordSpace: null
    property string panelMode: ""
    signal openPanel(string mode, var parentPos, var pos, var srcSize, real srcRadius)
    signal toggleDashboard()
    property int modeRowPressed: -1

    implicitHeight: colu.implicitHeight
    color: "transparent"
    radius: 20

    Behavior on implicitHeight { SpatialAnim { speed: "default" } }

    component Tile: Rectangle {
        id: tile
        property string title: ""
        property string subtitle: ""
        property string icon: ""
        property bool on: false
        signal activated

        Layout.fillWidth: true
        Layout.preferredHeight: controleRectangle.compact ? 54 : 62
        radius: 26
        color: Colors.surfaceContainerHigh
        Behavior on opacity { EffectsAnim { speed: "fast" } }

        RowLayout{
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 10
            spacing: 8

            Rectangle{
                Layout.preferredHeight: controleRectangle.compact ? 36 : 42
                Layout.preferredWidth:  controleRectangle.compact ? 36 : 42
                radius: 14
                color: tile.on ? Colors.primary : Colors.surfaceContainerHighest
                Behavior on color { EffectsColorAnim { speed: "fast" } }

                MaterialIconSymbol{
                    anchors.centerIn: parent
                    iconSize: controleRectangle.compact ? 19 : 22
                    content: tile.icon
                    customColor: tile.on ? Colors.primaryText : Colors.surfaceVariantText
                }
            }

            ColumnLayout{
                Layout.fillWidth: true
                spacing: 0

                CustomText{
                    Layout.fillWidth: true
                    content: tile.title
                    size: 13
                    weight: 700
                    elide: Text.ElideRight
                }

                CustomText{
                    Layout.fillWidth: true
                    visible: tile.subtitle !== ""
                    content: tile.subtitle
                    size: 11
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea{
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.activated()
        }
    }

    ColumnLayout{
        id: colu
        anchors.fill: parent
        anchors.margins: 0
        spacing: controleRectangle.compact ? 7 : 9

        RowLayout{
            Layout.fillWidth: true
            spacing: controleRectangle.compact ? 6 : 8

            M3Slider {
                property var brightnessMonitor: ServiceBrightness.getMonitorForScreen(screen)
                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 42 : 48
                icon: "brightness_7"
                iconAtEnd: true
                showStopIndicator: false
                trackOuterCorner: 14
                showValueLabel: true
                trackHeight: Math.min(40, height - 8)
                handleHeight: height
                handleWidth: 6
                pressedHandleWidth: 4
                handleGap: 4
                progress: ServiceBrightness.getMonitorForScreen(screen).brightness
                onMoved: brightnessMonitor.setBrightness(progress)
            }

            M3Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 42 : 48
                icon: ServicePipewire.muted ? "volume_off" : "volume_up"
                iconAtEnd: true
                showStopIndicator: false
                trackOuterCorner: 14
                showValueLabel: true
                trackHeight: Math.min(40, height - 8)
                handleHeight: height
                handleWidth: 6
                pressedHandleWidth: 4
                handleGap: 4
                progress: ServicePipewire.volume
                onMoved: ServicePipewire.setVolume(progress)
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: controleRectangle.compact ? 6 : 8

            Tile{
                id: wifi
                title: ServiceNetwork.connectionType
                subtitle: ServiceNetwork.currentSSID || "no device"
                icon: ServiceNetwork.icon
                on: ServiceNetwork.wifiEnabled
                opacity: controleRectangle.panelMode === "wifi" ? 0 : 1
                onActivated: {
                    const space = controleRectangle.coordSpace ?? controleRectangle
                    controleRectangle.openPanel("wifi",
                        controleRectangle.mapToItem(space, 0, 0),
                        wifi.mapToItem(space, 0, 0),
                        Qt.size(wifi.width, wifi.height),
                        wifi.radius)
                }
            }

            Tile{
                id: bluetooth
                title: "Bluetooth"
                subtitle: ServiceBluetooth.connectedDevices + " connected"
                icon: ServiceBluetooth.connectedDevices > 0 ? "bluetooth" : "bluetooth_disabled"
                on: ServiceBluetooth.connectedDevices > 0
                opacity: controleRectangle.panelMode === "bluetooth" ? 0 : 1
                onActivated: {
                    const space = controleRectangle.coordSpace ?? controleRectangle
                    controleRectangle.openPanel("bluetooth",
                        controleRectangle.mapToItem(space, 0, 0),
                        bluetooth.mapToItem(space, 0, 0),
                        Qt.size(bluetooth.width, bluetooth.height),
                        bluetooth.radius)
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: controleRectangle.compact ? 6 : 8

            component SideButton: Rectangle {
                id: side
                property string icon: ""
                property bool on: false
                signal activated

                property int slot: 0
                readonly property real baseW: controleRectangle.compact ? 60 : 72
                readonly property bool isPressed: controleRectangle.modeRowPressed === side.slot

                Layout.preferredHeight: controleRectangle.compact ? 46 : 54
                Layout.preferredWidth: {
                    if (controleRectangle.modeRowPressed < 0) return side.baseW
                    return side.isPressed ? side.baseW * 1.26 : side.baseW * 0.86
                }
                Behavior on Layout.preferredWidth { SpatialAnim { speed: "fast" } }
                radius: side.isPressed ? side.height * 0.22
                      : side.on ? side.height * 0.32
                      : side.height / 2
                Behavior on radius { SpatialAnim { speed: "fast" } }
                color: side.on ? Colors.primary
                     : sideArea.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh
                Behavior on color { EffectsColorAnim { speed: "fast" } }

                MaterialIconSymbol{
                    anchors.centerIn: parent
                    iconSize: 23
                    content: side.icon
                    customColor: side.on ? Colors.primaryText : Colors.surfaceText
                    fill: side.on ? 1 : 0
                    Behavior on fill { EffectsAnim { speed: "fast" } }
                    scale: sideArea.pressed ? 0.86 : 1
                    Behavior on scale { SpatialAnim { speed: "fast" } }
                }

                MouseArea{
                    id: sideArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: controleRectangle.modeRowPressed = side.slot
                    onReleased: controleRectangle.modeRowPressed = -1
                    onCanceled: controleRectangle.modeRowPressed = -1
                    onClicked: side.activated()
                }
            }

            Rectangle{
                id: modes
                readonly property bool isPressed: controleRectangle.modeRowPressed === 1

                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 46 : 54
                radius: modes.isPressed ? modes.height * 0.22 : modes.height / 2
                Behavior on radius { SpatialAnim { speed: "fast" } }
                color: modeArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                Behavior on color { EffectsColorAnim { speed: "fast" } }
                opacity: controleRectangle.panelMode === "modes" ? 0 : 1
                Behavior on opacity { EffectsAnim { speed: "fast" } }

                readonly property var profile: ServiceUPower.powerProfiles[ServiceUPower.powerProfile]
                    ?? ServiceUPower.powerProfiles[0]

                RowLayout{
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 14
                    spacing: 10

                    Rectangle{
                        Layout.preferredHeight: controleRectangle.compact ? 38 : 44
                        Layout.preferredWidth:  controleRectangle.compact ? 38 : 44
                        radius: height / 2
                        color: Colors.primary

                        MaterialIconSymbol{
                            anchors.centerIn: parent
                            iconSize: controleRectangle.compact ? 18 : 20
                            content: modes.profile.icon
                            customColor: Colors.primaryText
                        }
                    }

                    CustomText{
                        Layout.fillWidth: true
                        content: modes.profile.name
                        size: 13
                        weight: 600
                        elide: Text.ElideRight
                    }
                }

                MouseArea{
                    id: modeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: controleRectangle.modeRowPressed = 1
                    onReleased: controleRectangle.modeRowPressed = -1
                    onCanceled: controleRectangle.modeRowPressed = -1
                    onClicked: {
                        const space = controleRectangle.coordSpace ?? controleRectangle
                        controleRectangle.openPanel("modes",
                            controleRectangle.mapToItem(space, 0, 0),
                            modes.mapToItem(space, 0, 0),
                            Qt.size(modes.width, modes.height),
                            modes.height / 2)
                    }
                }
            }

            SideButton{
                slot: 2
                icon: ServiceTools.isRecording ? "stop_circle" : "screen_record"
                on: ServiceTools.isRecording
                onActivated: {
                    GlobalStates.toolsWidgetOpen = true
                    controleRectangle.toggleDashboard()
                }
            }
        }
    }
}
