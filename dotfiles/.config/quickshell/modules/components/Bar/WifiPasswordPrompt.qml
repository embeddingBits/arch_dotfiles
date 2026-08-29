import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.settings

PanelWindow {
    id: promptWindow

    property var network: null
    property string errorText: ""

    signal submitted(string psk)
    signal dismissed

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.namespace: "quickshell:wifiPrompt"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    function submit() {
        if (pwField.text.length === 0) return
        promptWindow.submitted(pwField.text)
    }

    Timer {
        interval: 60
        running: true
        onTriggered: pwField.forceActiveFocus()
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.alpha(Colors.scrim, 0.55)

        opacity: 0
        EffectsAnim {
            target: scrim
            property: "opacity"
            from: 0; to: 1
            speed: "slow"
            running: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: promptWindow.dismissed()
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 380
            implicitHeight: promptColumn.implicitHeight + 44
            radius: 28
            color: Colors.surfaceContainerHigh

            scale: 0.9
            SpatialAnim {
                target: card
                property: "scale"
                from: 0.9; to: 1
                speed: "fast"
                running: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                id: promptColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: promptWindow.errorText !== "" ? Colors.errorContainer
                                                             : Colors.primaryContainer

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: promptWindow.errorText !== "" ? "error" : "wifi_lock"
                            iconSize: 20
                            customColor: promptWindow.errorText !== "" ? Colors.errorContainerText
                                                                       : Colors.primaryContainerText
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        CustomText {
                            Layout.fillWidth: true
                            content: promptWindow.network?.name ?? "Wi-Fi network"
                            size: 16
                            weight: 700
                            elide: Text.ElideRight
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: promptWindow.errorText !== "" ? promptWindow.errorText
                                                                   : "This network is password protected"
                            size: 12
                            customColor: promptWindow.errorText !== "" ? Colors.error : Colors.outline
                            elide: Text.ElideRight
                        }
                    }

                    M3IconButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        icon: "close"
                        iconSize: 18
                        onClicked: promptWindow.dismissed()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 16
                    color: Colors.surfaceContainerHighest
                    border.width: 2
                    border.color: pwField.activeFocus ? Colors.primary : "transparent"

                    Behavior on border.color { EffectsColorAnim {} }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 10
                        spacing: 8

                        TextField {
                            id: pwField
                            Layout.fillWidth: true
                            background: null
                            padding: 0
                            placeholderText: "Password"
                            placeholderTextColor: Colors.outline
                            echoMode: revealToggle.revealed ? TextInput.Normal : TextInput.Password
                            inputMethodHints: Qt.ImhSensitiveData
                            font.pixelSize: 15
                            font.weight: 600
                            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                            color: Colors.surfaceText
                            selectionColor: Qt.alpha(Colors.primary, 0.35)
                            selectedTextColor: Colors.surfaceText
                            verticalAlignment: TextInput.AlignVCenter
                            onAccepted: promptWindow.submit()
                            Keys.onEscapePressed: promptWindow.dismissed()
                        }

                        MaterialIconSymbol {
                            id: revealToggle
                            property bool revealed: false
                            content: revealToggle.revealed ? "visibility_off" : "visibility"
                            iconSize: 18
                            customColor: Colors.outline

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: revealToggle.revealed = !revealToggle.revealed
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: cancelLabel.implicitWidth + 36
                        radius: 20
                        color: "transparent"

                        CustomText {
                            id: cancelLabel
                            anchors.centerIn: parent
                            content: "Cancel"
                            size: 13
                            weight: 700
                            customColor: Colors.primary
                        }

                        RippleEffect {
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: promptWindow.dismissed()
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: connectLabel.implicitWidth + 44
                        radius: 20
                        color: pwField.text.length > 0 ? Colors.primary
                                                       : Colors.surfaceContainerHighest

                        Behavior on color { EffectsColorAnim {} }

                        CustomText {
                            id: connectLabel
                            anchors.centerIn: parent
                            content: "Connect"
                            size: 13
                            weight: 700
                            customColor: pwField.text.length > 0 ? Colors.primaryText : Colors.outline
                        }

                        RippleEffect {
                            anchors.fill: parent
                            radius: parent.radius
                            hoverColor: Qt.alpha(Colors.primaryText, 0.1)
                            rippleColor: Qt.alpha(Colors.primaryText, 0.2)
                            onClicked: promptWindow.submit()
                        }
                    }
                }
            }
        }
    }
}
