import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import QtQuick.Effects
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialShapeFn

Item {
    id: root
    anchors.fill: parent

    signal backClicked

    property bool scanning: false
    property bool passwordPrompt: false
    property var pendingNetwork: null
    property string connectionError: ""

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool hardwareOn: Networking.wifiHardwareEnabled

    function strengthLabel(strength) {
        const v = (strength ?? 0) * 100
        if (v >= 75) return "Excellent"
        if (v >= 50) return "Good"
        if (v >= 25) return "Fair"
        return "Weak"
    }

    function strengthIcon(strength) {
        const v = (strength ?? 0) * 100
        if (v >= 90) return "signal_wifi_4_bar"
        if (v >= 60) return "network_wifi_3_bar"
        if (v >= 30) return "network_wifi_2_bar"
        return "network_wifi_1_bar"
    }

    function isSecured(security) {
        if (security === undefined || security === null) return false
        return security !== WifiSecurityType.Open
            && security !== WifiSecurityType.Owe
            && security !== WifiSecurityType.Unknown
    }

    function askPassword(network) {
        root.pendingNetwork = network
        root.passwordPrompt = true
    }

    function submitPassword(psk) {
        if (root.pendingNetwork) root.pendingNetwork.connectWithPsk(psk)
        root.passwordPrompt = false
    }

    function dismissPassword() {
        root.passwordPrompt = false
        root.pendingNetwork = null
        root.connectionError = ""
    }

    function activate(network) {
        if (!network) return
        root.connectionError = ""
        if (network.connected) {
            network.disconnect()
            return
        }
        if (!network.known && root.isSecured(network.security)) {
            root.askPassword(network)
            return
        }
        network.connect()
    }

    function handleFailure(network, reason) {
        if (reason === ConnectionFailReason.NoSecrets) {
            root.connectionError = ""
            root.askPassword(network)
            return
        }
        if (root.pendingNetwork !== network && root.passwordPrompt) return
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
        if (reason === ConnectionFailReason.WifiAuthTimeout) root.askPassword(network)
    }

    function startScan() {
        if (!root.wifiOn || !ServiceNetwork.currentNetwork) return
        ServiceNetwork.currentNetwork.scannerEnabled = true
        root.scanning = true
        scanTimer.restart()
    }

    Loader {
        active: root.passwordPrompt
        sourceComponent: WifiPasswordPrompt {
            network: root.pendingNetwork
            errorText: root.connectionError
            onSubmitted: psk => root.submitPassword(psk)
            onDismissed: root.dismissPassword()
        }
    }

    Timer {
        id: scanTimer
        interval: 8000
        onTriggered: root.scanning = false
    }

    opacity: 0
    EffectsAnim {
        target: root
        property: "opacity"
        from: 0; to: 1
        speed: "slow"
        running: true
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

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
                    content: "Wi-Fi"
                    size: 17
                    weight: 700
                    elide: Text.ElideRight
                }

                CustomText {
                    Layout.fillWidth: true
                    content: !root.hardwareOn ? "Blocked by hardware switch"
                        : !root.wifiOn ? "Off"
                        : ServiceNetwork.currentSSID !== "" ? ServiceNetwork.currentSSID
                        : "Not connected"
                    size: 11
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }
            }

            CustomToogle {
                Layout.alignment: Qt.AlignVCenter
                isToggleOn: Networking.wifiEnabled
                opacity: root.hardwareOn ? 1 : 0.4
                onToggled: function (state) {
                    if (!root.hardwareOn) return
                    Networking.wifiEnabled = state
                }
            }
        }

        CustomText {
            content: "Saved Networks"
            size: 12
            weight: 700
            customColor: Colors.primary
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Math.max(savedList.contentHeight, 56), 112)
            clip: true
            opacity: root.wifiOn ? 1 : 0.4
            Behavior on opacity { EffectsAnim {} }

            ListView {
                id: savedList
                anchors.fill: parent
                model: ScriptModel { values: ServiceNetwork.connectedAndSavedNetworks }
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: CustomScrollBar {}
                delegate: networkRowComponent
                populate: StaggerTransition {}
                add: StaggerTransition {}
                displaced: Transition { SpatialAnim { properties: "y"; speed: "fast" } }
            }

            CustomText {
                anchors.centerIn: parent
                visible: ServiceNetwork.connectedAndSavedNetworks.length === 0
                content: root.wifiOn ? "No saved networks" : "Wi-Fi is off"
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
                content: "Available Networks"
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
                    enabled: root.wifiOn && !root.scanning
                    opacity: root.scanning ? 0 : root.wifiOn ? 1 : 0.4
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
            opacity: root.wifiOn ? 1 : 0.4
            Behavior on opacity { EffectsAnim {} }

            ColumnLayout {
                anchors.centerIn: parent
                visible: ServiceNetwork.available.length === 0
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
                        content: root.wifiOn ? "wifi_find" : "wifi_off"
                        iconSize: 22
                        customColor: Colors.outline
                    }
                }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: !root.wifiOn ? "Wi-Fi is off"
                        : root.scanning ? "Scanning…"
                        : "Scan for networks"
                    size: 12
                    customColor: Colors.outline
                }
            }

            ListView {
                id: availableList
                anchors.fill: parent
                visible: ServiceNetwork.available.length > 0
                model: ScriptModel { values: ServiceNetwork.available }
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: CustomScrollBar {}
                delegate: networkRowComponent
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
                    content: "Wi-Fi Settings"
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
                    GlobalStates.settingsPage = 4
                    GlobalStates.settingsOpen = true
                }
            }
        }
    }

    Component {
        id: networkRowComponent

        Rectangle {
            id: netRow

            readonly property bool isActive: modelData?.connected ?? false
            readonly property bool isBusy: modelData?.state === ConnectionState.Connecting
                || modelData?.state === ConnectionState.Disconnecting

            width: ListView.view ? ListView.view.width : 0
            implicitHeight: 54
            radius: 18
            color: netRow.isActive ? Qt.alpha(Colors.primary, 0.18)
                : netRipple.containsMouse ? Colors.surfaceContainerHighest
                : "transparent"

            Behavior on color { EffectsColorAnim {} }

            Connections {
                target: modelData
                ignoreUnknownSignals: true
                function onConnectionFailed(reason) {
                    root.handleFailure(modelData, reason)
                }
                function onConnectedChanged() {
                    if (modelData?.connected) {
                        root.connectionError = ""
                        if (root.pendingNetwork === modelData) root.passwordPrompt = false
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: netRow.isActive ? Colors.primary : Colors.surfaceContainerHighest

                    Behavior on color { EffectsColorAnim {} }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: root.strengthIcon(modelData?.signalStrength)
                        iconSize: 19
                        customColor: netRow.isActive ? Colors.primaryText : Colors.surfaceVariantText
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
                            if (modelData?.state === ConnectionState.Connecting) return "Connecting…"
                            if (modelData?.state === ConnectionState.Disconnecting) return "Disconnecting…"
                            const strength = root.strengthLabel(modelData?.signalStrength)
                            if (netRow.isActive) return "Connected · " + strength
                            if (modelData?.known) return "Saved · " + strength
                            return strength
                        }
                        size: 11
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        visible: !netRow.isBusy && root.isSecured(modelData?.security)
                        content: "lock"
                        iconSize: 16
                        customColor: Colors.outline
                    }

                    CustomCircularLoader {
                        anchors.centerIn: parent
                        visible: netRow.isBusy
                        size: 18
                        trackWidth: 2
                        waveAmplitude: 0
                        highlightColor: Colors.primary
                        trackColor: Colors.surfaceContainerHighest
                    }
                }
            }

            RippleEffect {
                id: netRipple
                anchors.fill: parent
                radius: parent.radius
                onClicked: {
                    if (netRow.isBusy) return
                    root.activate(modelData)
                }
            }
        }
    }
}
