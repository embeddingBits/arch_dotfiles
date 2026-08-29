import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: root

    implicitWidth: parent?.width ?? 0
    implicitHeight: bluetooth !== null ? mainLayout.implicitHeight + 24 : 0
    clip: true

    property int topRadius: 20
    property int bottomRadius: 20
    topLeftRadius: topRadius
    topRightRadius: topRadius
    bottomLeftRadius: bottomRadius
    bottomRightRadius: bottomRadius

    color: Colors.surfaceContainerHigh

    property var bluetooth: null
    property bool expanded: false
    property string actionError: ""

    readonly property bool isConnected: bluetooth?.state === BluetoothDeviceState.Connected
    readonly property bool isPaired: bluetooth?.paired ?? bluetooth?.bonded ?? false
    readonly property bool isPairing: bluetooth?.pairing ?? false
    readonly property bool isBusy: bluetooth?.state === BluetoothDeviceState.Connecting
                                || bluetooth?.state === BluetoothDeviceState.Disconnecting
                                || isPairing

    property var buttonModel: {
        if (!bluetooth) return []
        const m = []
        if (isPairing) {
            m.push({ value: "cancelPair", label: "Cancel", icon: "close" })
            return m
        }
        if (isConnected) {
            m.push({ value: "disconnect", label: "Disconnect", icon: "bluetooth_disabled" })
        } else if (isPaired) {
            m.push({ value: "connect", label: "Connect", icon: "bluetooth" })
        } else {
            m.push({ value: "pair", label: "Pair", icon: "bluetooth_searching" })
        }
        if (isPaired) {
            m.push({ value: bluetooth.trusted ? "untrust" : "trust",
                     label: bluetooth.trusted ? "Untrust" : "Trust",
                     icon: bluetooth.trusted ? "shield_lock" : "verified_user" })
            m.push({ value: "forget", label: "Forget", icon: "link_off" })
        }
        return m
    }

    visible: bluetooth !== null

    // Action currently awaiting a result, so we can report one that silently fails
    property string pendingAction: ""

    onBluetoothChanged: {
        if (!bluetooth) expanded = false
        actionError = ""
        pendingAction = ""
        actionTimeout.stop()
    }

    function runAction(action) {
        const dev = root.bluetooth
        if (!dev) return
        root.actionError = ""
        root.pendingAction = action
        actionTimeout.restart()

        switch (action) {
        case "connect":    dev.connect();    break
        case "disconnect": dev.disconnect(); break
        case "pair":       dev.pair();       break
        case "cancelPair": dev.cancelPair(); break
        case "forget":     root.expanded = false; dev.forget(); break
        case "trust":      dev.trusted = true;  root.pendingAction = ""; actionTimeout.stop(); break
        case "untrust":    dev.trusted = false; root.pendingAction = ""; actionTimeout.stop(); break
        }
    }

    Timer {
        id: actionTimeout
        interval: 15000
        onTriggered: {
            switch (root.pendingAction) {
            case "connect":    if (!root.isConnected) root.actionError = "Couldn't connect"; break
            case "disconnect": if (root.isConnected)  root.actionError = "Couldn't disconnect"; break
            case "pair":       if (!root.isPaired)    root.actionError = "Pairing failed"; break
            case "forget":     if (root.isPaired)     root.actionError = "Couldn't forget device"; break
            }
            root.pendingAction = ""
        }
    }

    // The device reaching a new state means the action landed — clear the watchdog
    Connections {
        target: root.bluetooth
        ignoreUnknownSignals: true
        function onStateChanged() {
            if (root.bluetooth?.state === BluetoothDeviceState.Connecting
             || root.bluetooth?.state === BluetoothDeviceState.Disconnecting) return
            root.pendingAction = ""
            root.actionError = ""
            actionTimeout.stop()
        }
        function onPairedChanged() {
            root.pendingAction = ""
            root.actionError = ""
            actionTimeout.stop()
        }
    }

    Behavior on implicitHeight {
        enabled: root.bluetooth !== null
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on color { ColorAnimation { duration: 200 } }

    function deviceIcon(iconStr) {
        if (!iconStr) return "bluetooth"
        if (iconStr.includes("headphone") || iconStr.includes("headset")) return "headphones"
        if (iconStr.includes("mouse"))    return "mouse"
        if (iconStr.includes("keyboard")) return "keyboard"
        if (iconStr.includes("phone"))    return "smartphone"
        if (iconStr.includes("speaker") || iconStr.includes("audio")) return "speaker"
        if (iconStr.includes("gamepad") || iconStr.includes("joystick")) return "sports_esports"
        if (iconStr.includes("computer") || iconStr.includes("laptop")) return "laptop"
        return "bluetooth"
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 12
        spacing: 0

        // ── Header ────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 10

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    content: root.deviceIcon(bluetooth?.icon ?? "")
                    fill: isConnected ? 1 : 0
                    iconSize: 26
                    customColor: isConnected ? Colors.primary : Colors.outline
                    Behavior on customColor { ColorAnimation { duration: 200 } }
                    Behavior on fill { NumberAnimation { duration: 200 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    CustomText {
                        Layout.fillWidth: true
                        content: bluetooth?.name ?? ""
                        size: 14
                    }
                    CustomText {
                        Layout.fillWidth: true
                        content: root.bluetooth?.state === BluetoothDeviceState.Connecting    ? "Connecting…"
                               : root.bluetooth?.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                               : root.isPairing ? "Pairing…"
                               : isConnected    ? "Connected"
                               : isPaired       ? "Paired"
                               :                  "Nearby"
                        size: 12
                        customColor: isConnected ? Colors.primary : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }

                    CustomText {
                        Layout.fillWidth: true
                        visible: root.actionError !== ""
                        content: root.actionError
                        size: 11
                        customColor: Colors.error
                    }
                }

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    content: root.expanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                    iconSize: 18
                    customColor: Colors.outline
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        // ── Expanded detail section ────────────────────────────────
        ColumnLayout {
            id: detailSection
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: 6
            visible: root.expanded
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.outline
                opacity: 0.3
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                CustomText { content: "Address"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText { content: bluetooth?.address ?? "—"; size: 12 }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: bluetooth?.batteryAvailable ?? false
                CustomText { content: "Battery"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: Math.round((bluetooth?.battery ?? 0) * 100) + "%"
                    size: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                CustomText { content: "Trusted"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText { content: (bluetooth?.trusted ?? false) ? "Yes" : "No"; size: 12 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Colors.outline
                opacity: 0.3
            }

            M3ButtonGroup {
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                height: 30
                model: root.buttonModel
                activeCheck: function(v) { return false }
                inactiveColor: Colors.surfaceContainerHighest

                onSegmentClicked: function(action) { root.runAction(action) }
            }
        }
    }
}
