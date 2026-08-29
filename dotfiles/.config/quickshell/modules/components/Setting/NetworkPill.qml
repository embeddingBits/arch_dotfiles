import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: root

    implicitWidth: parent?.width ?? 0
    implicitHeight: network !== null ? mainLayout.implicitHeight + 24 : 0
    clip: true

    property int topRadius: 20
    property int bottomRadius: 20
    topLeftRadius: topRadius
    topRightRadius: topRadius
    bottomLeftRadius: bottomRadius
    bottomRightRadius: bottomRadius

    color: Colors.surfaceContainerHigh

    property var network: null
    property bool expanded: false
    property string connectionError: ""

    property var buttonModel: {
        if (!network) return []
        const connected = network.connected
        const known = network.known
        const m = []
        if (network.state === ConnectionState.Connecting) {
            m.push({ value: "cancel", label: "Cancel", icon: "close" })
            if (known) m.push({ value: "forget", label: "Forget", icon: "link_off" })
            return m
        }
        if (connected) {
            m.push({ value: "disconnect", label: "Disconnect", icon: "wifi_off" })
        } else {
            m.push({ value: "connect", label: "Connect", icon: "wifi" })
        }
        if (known) {
            m.push({ value: "forget", label: "Forget", icon: "link_off" })
        }
        if (connected) {
            m.push({ value: "qr", label: "QR Code", icon: "qr_code" })
        }
        return m
    }

    visible: network !== null

    signal needsPassword(var network)
    signal qrCode(var network)

    onNetworkChanged: {
        if (!network) {
            expanded = false
            connectionError = ""
        }
    }

    Behavior on implicitHeight {
        enabled: root.network !== null
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    function wifiIcon(strength, security) {
        const bars = Math.round((strength ?? 0) * 4)
        // Open/Owe/Unknown are the unsecured cases — every other enum value is encrypted.
        // (Wpa3SuiteB192 is 0, so a `security !== 0` test gets this exactly backwards.)
        const locked = security !== undefined
                    && security !== WifiSecurityType.Open
                    && security !== WifiSecurityType.Owe
                    && security !== WifiSecurityType.Unknown
        if (bars >= 4) return locked ? "wifi_lock"                    : "wifi"
        if (bars === 3) return locked ? "network_wifi_3_bar_locked"   : "network_wifi_3_bar"
        if (bars === 2) return locked ? "network_wifi_2_bar_locked"   : "network_wifi_2_bar"
        if (bars === 1) return locked ? "network_wifi_1_bar_locked"   : "network_wifi_1_bar"
        return locked ? "wifi_lock" : "signal_wifi_off"
    }

    Connections {
        target: root.network
        ignoreUnknownSignals: true

        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                root.connectionError = ""
                root.needsPassword(root.network)
                return
            }

            switch (reason) {
            case ConnectionFailReason.WifiAuthTimeout:
                root.connectionError = "Wrong password"; break
            case ConnectionFailReason.WifiNetworkLost:
                root.connectionError = "Network out of range"; break
            case ConnectionFailReason.WifiClientDisconnected:
                root.connectionError = "Disconnected by the network"; break
            case ConnectionFailReason.WifiClientFailed:
                root.connectionError = "Connection failed"; break
            default:
                root.connectionError = "Connection failed"; break
            }
            root.expanded = true
        }

        // A successful connection clears any leftover error
        function onConnectedChanged() {
            if (root.network?.connected) root.connectionError = ""
        }
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
                    content: root.wifiIcon(network?.signalStrength, network?.security)
                    fill: network?.connected ? 1 : 0
                    iconSize: 26
                    customColor: network?.connected ? Colors.primary : Colors.outline
                    Behavior on customColor { ColorAnimation { duration: 200 } }
                    Behavior on fill { NumberAnimation { duration: 200 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    CustomText {
                        Layout.fillWidth: true
                        content: network?.name ?? ""
                        size: 14
                    }
                    CustomText {
                        Layout.fillWidth: true
                        content: network?.state === ConnectionState.Connecting    ? "Connecting…"
                               : network?.state === ConnectionState.Disconnecting ? "Disconnecting…"
                               : network?.connected ? "Connected"
                               : network?.known     ? "Saved"
                               :                      "Available"
                        size: 12
                        customColor: network?.connected ? Colors.primary : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }
                    CustomText {
                        Layout.fillWidth: true
                        visible: root.connectionError !== ""
                        content: root.connectionError
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
                CustomText { content: "Signal strength"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: Math.floor((network?.signalStrength ?? 0) * 100) + "%"
                    size: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                CustomText { content: "Security"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: WifiSecurityType.toString(network?.security ?? 0)
                    size: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                CustomText { content: "Saved network"; size: 12; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: (network?.known ?? false) ? "Yes" : "No"
                    size: 12
                }
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

                onSegmentClicked: function(action) {
                    const net = root.network
                    if (!net) return

                    switch (action) {
                    case "connect":
                        root.connectionError = ""
                        net.connect()
                        break
                    case "disconnect":
                    case "cancel":
                        net.disconnect()
                        break
                    case "forget":
                        root.connectionError = ""
                        root.expanded = false
                        net.forget()
                        break
                    case "qr":
                        root.qrCode(root.network)
                        break
                    }
                }
            }
        }
    }
}
