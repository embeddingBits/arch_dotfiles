import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    property bool qrCode: false
    property bool passwordPrompt: false
    property var network: null
    property bool scanning: false

    function submitPassword() {
        if (pwField.text.length === 0) return
        if (root.network) root.network.connectWithPsk(pwField.text)
        root.passwordPrompt = false
    }

    // Never carry a previous attempt's password into the next prompt
    onPasswordPromptChanged: {
        if (passwordPrompt) {
            pwField.clear()
            pwField.forceActiveFocus()
        }
    }

    Timer {
        id: scanTimer
        interval: 5000
        onTriggered: root.scanning = false
    }

    property bool hasSavedNetworks: {
        const ns = ServiceNetwork.networks ?? []
        for (let i = 0; i < ns.length; i++) {
            if (ns[i].known && !ns[i].connected) return true
        }
        return false
    }
    property bool hasAvailableNetworks: {
        const ns = ServiceNetwork.networks ?? []
        for (let i = 0; i < ns.length; i++) {
            if (!ns[i].known && !ns[i].connected) return true
        }
        return false
    }

    // ── QR overlay ───────────────────────────────────────────────
    Loader {
        anchors.fill: parent
        active: root.qrCode
        visible: active
        z: 10
        sourceComponent: QrCode {
            network: root.network
            onClose: root.qrCode = false
        }
    }

    // ── Password dialog ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        visible: root.passwordPrompt
        z: 11
        color: Qt.alpha(Colors.surface, 0.75)
        radius: 20

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
        }

        Rectangle {
            anchors.centerIn: parent
            width: 380; height: 150
            radius: 20
            color: Colors.surfaceContainer

            NumberAnimation on scale {
                from: 0.85; to: 1; duration: 200
                easing.type: Easing.OutQuad
                running: root.passwordPrompt
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 8
                        MaterialIconSymbol { content: "lock"; iconSize: 16; customColor: Colors.outline }
                        CustomText { content: "Enter password"; size: 15 }
                    }
                    Item { Layout.fillWidth: true }
                    MaterialIconSymbol {
                        content: "close"; iconSize: 18; customColor: Colors.outline
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.passwordPrompt = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 12
                    color: Colors.surfaceContainerHighest

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 10
                        spacing: 8

                        TextField {
                            id: pwField
                            Layout.fillWidth: true
                            background: null
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            font.pixelSize: 14
                            color: Colors.surfaceText
                            verticalAlignment: TextInput.AlignVCenter
                            onAccepted: root.submitPassword()
                        }

                        MaterialIconSymbol {
                            content: "send"; iconSize: 20
                            customColor: pwField.text.length > 0 ? Colors.primary
                                                                 : Qt.alpha(Colors.primary, 0.4)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitPassword()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Main content ─────────────────────────────────────────────
    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            spacing: 0

            // ── Page header ──────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "android_wifi_4_bar"; iconSize: 20 }
                CustomText { content: "Networking"; size: 20; customColor: Colors.primary }
            }

            // ── Available Nodes ──────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Available Nodes"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Wi-Fi"; size: 14 }
                        CustomText {
                            content: Networking.wifiHardwareEnabled ? "Enable or disable the Wi-Fi radio"
                                                                    : "Blocked by hardware switch"
                            size: 12; customColor: Colors.outline
                        }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: Networking.wifiEnabled
                        opacity: Networking.wifiHardwareEnabled ? 1 : 0.4
                        onToggled: function(state) {
                            if (!Networking.wifiHardwareEnabled) return
                            Networking.wifiEnabled = state
                        }
                    }
                }
            }

            // ── Connected ────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Connected"; size: 13; customColor: Colors.primary }

            // Empty state — not connected
            Rectangle {
                Layout.topMargin: 6
                Layout.fillWidth: true
                implicitHeight: 90
                visible: ServiceNetwork.connectedNetwork == null
                color: Colors.surfaceContainerHigh
                radius: 20

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 46; implicitHeight: 46

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie6Sided()
                            color: Colors.surfaceContainerHighest
                        }
                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "wifi_off"; iconSize: 22; customColor: Colors.outline
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: "Not connected"; size: 13; customColor: Colors.outline
                    }
                }
            }

            NetworkPill {
                Layout.topMargin: 6
                Layout.fillWidth: true
                visible: ServiceNetwork.connectedNetwork != null
                network: ServiceNetwork.connectedNetwork
                onNeedsPassword: function(net) { root.network = net; root.passwordPrompt = true }
                onQrCode: function(network) { root.network = network; root.qrCode = true }
            }

            // ── Saved Networks ───────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Saved Networks"; size: 13; customColor: Colors.primary }

            // Empty state — no saved
            Rectangle {
                Layout.topMargin: 6
                Layout.fillWidth: true
                implicitHeight: 90
                visible: !root.hasSavedNetworks
                color: Colors.surfaceContainerHigh
                radius: 20

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 46; implicitHeight: 46

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie6Sided()
                            color: Colors.surfaceContainerHighest
                        }
                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "wifi_off"; iconSize: 22; customColor: Colors.outline
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: "No saved networks"; size: 13; customColor: Colors.outline
                    }
                }
            }

            ColumnLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 3
                visible: root.hasSavedNetworks

                Repeater {
                    model: ServiceNetwork.networks
                    delegate: NetworkPill {
                        Layout.fillWidth: true
                        network: (modelData?.known && !modelData?.connected) ? modelData : null
                        topRadius: {
                            const ns = ServiceNetwork.networks ?? []
                            for (let i = 0; i < ns.length; i++) {
                                if (ns[i].known && !ns[i].connected) return (i === index) ? 20 : 5
                            }
                            return 20
                        }
                        bottomRadius: {
                            const ns = ServiceNetwork.networks ?? []
                            let last = -1
                            for (let i = 0; i < ns.length; i++) {
                                if (ns[i].known && !ns[i].connected) last = i
                            }
                            return (last === index) ? 20 : 5
                        }
                        onNeedsPassword: function(net) { root.network = net; root.passwordPrompt = true }
                        onQrCode: function(network) { root.network = network; root.qrCode = true }
                    }
                }
            }

            // ── Available Networks ───────────────────────────────
            RowLayout {
                Layout.topMargin: 16
                Layout.fillWidth: true
                CustomText { content: "Available Networks"; size: 13; customColor: Colors.primary }
                Item { Layout.fillWidth: true }

                Loader {
                    active: root.scanning
                    visible: active
                    sourceComponent: CustomCircularLoader {
                        size: 18; trackWidth: 2
                        waveAmplitude: 0
                        highlightColor: Colors.outline
                    }
                }

                MaterialIconSymbol {
                    visible: !root.scanning
                    content: "refresh"; iconSize: 18
                    customColor: Networking.wifiEnabled ? Colors.outline : Qt.alpha(Colors.outline, 0.4)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Networking.wifiEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (!Networking.wifiEnabled) return
                            if (!ServiceNetwork.currentNetwork) return
                            ServiceNetwork.currentNetwork.scannerEnabled = true
                            root.scanning = true
                            scanTimer.restart()
                        }
                    }
                }
            }

            // Empty state — none found
            Rectangle {
                Layout.topMargin: 6
                Layout.fillWidth: true
                implicitHeight: 90
                visible: !root.hasAvailableNetworks
                color: Colors.surfaceContainerHigh
                radius: 20

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 46; implicitHeight: 46

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie6Sided()
                            color: Colors.surfaceContainerHighest
                        }
                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "wifi_find"; iconSize: 22; customColor: Colors.outline
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: "No networks found"; size: 13; customColor: Colors.outline
                    }
                }
            }

            ColumnLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 3
                visible: root.hasAvailableNetworks

                Repeater {
                    model: ServiceNetwork.networks
                    delegate: NetworkPill {
                        Layout.fillWidth: true
                        network: (!modelData?.known && !modelData?.connected) ? modelData : null
                        topRadius: {
                            const ns = ServiceNetwork.networks ?? []
                            for (let i = 0; i < ns.length; i++) {
                                if (!ns[i].known && !ns[i].connected) return (i === index) ? 20 : 5
                            }
                            return 20
                        }
                        bottomRadius: {
                            const ns = ServiceNetwork.networks ?? []
                            let last = -1
                            for (let i = 0; i < ns.length; i++) {
                                if (!ns[i].known && !ns[i].connected) last = i
                            }
                            return (last === index) ? 20 : 5
                        }
                        onNeedsPassword: function(net) { root.network = net; root.passwordPrompt = true }
                        onQrCode: function(network) { root.network = network; root.qrCode = true }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }
}
