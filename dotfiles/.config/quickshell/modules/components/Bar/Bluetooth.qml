import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import QtQuick.Effects
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialShapeFn

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 14
    spacing: 8

    signal backClicked

    property bool scanning: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothOn: root.adapter?.enabled ?? false

    function deviceIcon(icon) {
        switch (icon) {
        case "audio-headset":
        case "audio-headphones":
            return "headphones"
        case "audio-card":
        case "audio-speakers":
            return "speaker"
        case "input-keyboard":
            return "keyboard"
        case "input-mouse":
            return "mouse"
        case "input-gaming":
            return "stadia_controller"
        case "phone":
            return "smartphone"
        case "computer":
            return "computer"
        case "printer":
            return "print"
        default:
            return "bluetooth"
        }
    }

    function batteryIcon(level) {
        if (level >= 1) return "battery_android_full"
        if (level >= 0.9) return "battery_android_6"
        if (level >= 0.7) return "battery_android_5"
        if (level >= 0.5) return "battery_android_4"
        if (level >= 0.3) return "battery_android_3"
        if (level >= 0.2) return "battery_android_2"
        if (level > 0) return "battery_android_1"
        return "battery_android_0"
    }

    function startScan() {
        if (!root.adapter || !root.bluetoothOn) return
        root.adapter.discovering = true
        root.scanning = true
        scanTimer.restart()
    }

    Timer {
        id: scanTimer
        interval: 8000
        onTriggered: {
            root.scanning = false
            if (root.adapter) root.adapter.discovering = false
        }
    }

    opacity: 0
    EffectsAnim {
        target: root
        property: "opacity"
        from: 0; to: 1
        speed: "slow"
        running: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        spacing: 10

        M3IconButton {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 16
            icon: "chevron_backward"
            iconSize: 20
            onClicked: root.backClicked()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CustomText {
                Layout.fillWidth: true
                content: "Bluetooth"
                size: 17
                weight: 700
                elide: Text.ElideRight
            }

            CustomText {
                Layout.fillWidth: true
                content: !root.adapter ? "No adapter"
                    : !root.bluetoothOn ? "Off"
                    : ServiceBluetooth.connectedDevices === 1 ? "1 device connected"
                    : ServiceBluetooth.connectedDevices > 1 ? ServiceBluetooth.connectedDevices + " devices connected"
                    : "No devices connected"
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }

        CustomToogle {
            Layout.alignment: Qt.AlignVCenter
            isToggleOn: root.bluetoothOn
            opacity: root.adapter ? 1 : 0.4
            onToggled: function (state) {
                if (root.adapter) root.adapter.enabled = state
            }
        }
    }

    CustomText {
        content: "Saved Devices"
        size: 12
        weight: 700
        customColor: Colors.primary
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(Math.max(savedList.contentHeight, 56), 112)
        clip: true
        opacity: root.bluetoothOn ? 1 : 0.4
        Behavior on opacity { EffectsAnim {} }

        ListView {
            id: savedList
            anchors.fill: parent
            model: ScriptModel { values: ServiceBluetooth.connectedAndPairedDevices }
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: CustomScrollBar {}
            delegate: deviceRowComponent
            populate: StaggerTransition {}
            add: StaggerTransition {}
            displaced: Transition { SpatialAnim { properties: "y"; speed: "fast" } }
        }

        CustomText {
            anchors.centerIn: parent
            visible: ServiceBluetooth.connectedAndPairedDevices.length === 0
            content: root.bluetoothOn ? "No saved devices" : "Bluetooth is off"
            size: 12
            customColor: Colors.outline
        }
    }

    CustomSpermSeparator {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.preferredHeight: 6
        color: Colors.outlineVariant
        frequency: 14
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        CustomText {
            content: "Available Devices"
            size: 12
            weight: 700
            customColor: Colors.primary
        }

        Item { Layout.fillWidth: true }

        Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            M3IconButton {
                anchors.fill: parent
                radius: 15
                icon: "search"
                iconSize: 17
                enabled: root.bluetoothOn && !root.scanning
                opacity: root.scanning ? 0 : root.bluetoothOn ? 1 : 0.4
                onClicked: root.startScan()

                Behavior on opacity { EffectsAnim {} }
            }

            CustomCircularLoader {
                anchors.centerIn: parent
                size: 20
                trackWidth: 2
                waveAmplitude: 0
                highlightColor: Colors.primary
                trackColor: Colors.surfaceContainerHighest
                visible: root.scanning
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 96
        clip: true
        opacity: root.bluetoothOn ? 1 : 0.4
        Behavior on opacity { EffectsAnim {} }

        ColumnLayout {
            anchors.centerIn: parent
            visible: ServiceBluetooth.unpairedDevices.length === 0
            spacing: 10

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 52
                implicitHeight: 52

                MaterialShapes.ShapeCanvas {
                    anchors.fill: parent
                    roundedPolygon: MatrialShapeFn.getSunny()
                    color: Colors.surfaceContainerHighest
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: root.bluetoothOn ? "bluetooth_searching" : "bluetooth_disabled"
                    iconSize: 22
                    customColor: Colors.outline
                }
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: !root.bluetoothOn ? "Bluetooth is off"
                    : root.scanning ? "Scanning…"
                    : "Scan for devices"
                size: 12
                customColor: Colors.outline
            }
        }

        ListView {
            id: availableList
            anchors.fill: parent
            visible: ServiceBluetooth.unpairedDevices.length > 0
            model: ScriptModel { values: ServiceBluetooth.unpairedDevices }
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: CustomScrollBar {}
            delegate: deviceRowComponent
            populate: StaggerTransition {}
            add: StaggerTransition {}
            displaced: Transition { SpatialAnim { properties: "y"; speed: "fast" } }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.preferredHeight: 40
        radius: 20
        color: Colors.secondaryContainer

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            MaterialIconSymbol {
                content: "settings"
                iconSize: 17
                customColor: Colors.secondaryContainerText
            }

            CustomText {
                content: "Bluetooth Settings"
                size: 13
                weight: 700
                customColor: Colors.secondaryContainerText
            }
        }

        RippleEffect {
            anchors.fill: parent
            radius: parent.radius
            hoverColor: Qt.alpha(Colors.secondaryContainerText, 0.08)
            rippleColor: Qt.alpha(Colors.secondaryContainerText, 0.16)
            onClicked: {
                root.backClicked()
                GlobalStates.settingsPage = 5
                GlobalStates.settingsOpen = true
            }
        }
    }

    Component {
        id: deviceRowComponent

        Rectangle {
            id: devRow

            readonly property bool isActive: modelData?.state === BluetoothDeviceState.Connected
            readonly property bool isBusy: modelData?.state === BluetoothDeviceState.Connecting
                || modelData?.state === BluetoothDeviceState.Disconnecting
                || (modelData?.pairing ?? false)
            readonly property bool hasBattery: (modelData?.batteryAvailable ?? false) && devRow.isActive

            width: ListView.view ? ListView.view.width : 0
            implicitHeight: 54
            radius: 18
            color: devRow.isActive ? Qt.alpha(Colors.primary, 0.18)
                : devRipple.containsMouse ? Colors.surfaceContainerHighest
                : "transparent"

            Behavior on color { EffectsColorAnim {} }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: devRow.isActive ? Colors.primary : Colors.surfaceContainerHighest

                    Behavior on color { EffectsColorAnim {} }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: root.deviceIcon(modelData?.icon)
                        iconSize: 19
                        customColor: devRow.isActive ? Colors.primaryText : Colors.surfaceVariantText
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    CustomText {
                        Layout.fillWidth: true
                        content: modelData?.name ?? ""
                        size: 14
                        weight: 700
                        elide: Text.ElideRight
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: {
                            if (modelData?.pairing) return "Pairing…"
                            if (modelData?.state === BluetoothDeviceState.Connecting) return "Connecting…"
                            if (modelData?.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
                            if (devRow.isActive) return "Connected"
                            if (modelData?.paired) return "Saved"
                            return "Tap to pair"
                        }
                        size: 11
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3
                    visible: devRow.hasBattery && !devRow.isBusy

                    MaterialIconSymbol {
                        content: root.batteryIcon(modelData?.battery ?? 0)
                        iconSize: 18
                        customColor: Colors.outline
                    }

                    CustomText {
                        content: Math.round((modelData?.battery ?? 0) * 100) + "%"
                        size: 11
                        customColor: Colors.outline
                    }
                }

                CustomCircularLoader {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    visible: devRow.isBusy
                    size: 18
                    trackWidth: 2
                    waveAmplitude: 0
                    highlightColor: Colors.primary
                    trackColor: Colors.surfaceContainerHighest
                }
            }

            RippleEffect {
                id: devRipple
                anchors.fill: parent
                radius: parent.radius
                onClicked: {
                    if (devRow.isBusy) return
                    if (devRow.isActive) modelData?.disconnect()
                    else modelData?.connect()
                }
            }
        }
    }
}
