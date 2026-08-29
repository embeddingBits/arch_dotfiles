import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Item {
    id: root
    required property var context
    focus: true

    Keys.onPressed: event => { passInput.forceActiveFocus() }

    readonly property string _font: SettingsConfig.general.displayFont ?? "Titan One"
    readonly property string _profile: SettingsConfig.general.profile ?? ""

    readonly property int _h24: parseInt(ServiceClock.hour)
    readonly property int _h12: { let h = _h24 % 12; return h === 0 ? 12 : h }
    readonly property string _period: _h24 < 12 ? "AM" : "PM"
    readonly property string _hours: (_h12 < 10 ? "0" : "") + _h12
    readonly property string _minutes: ServiceClock.minute
    readonly property string _initial: (root.context.currentUser || "?").charAt(0).toUpperCase()

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: WallpaperTheme.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 1920
        sourceSize.height: 1080
        asynchronous: true
        cache: false
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true; blur: 0.9; blurMax: 48; autoPaddingEnabled: false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, wallpaper.visible ? 0.34 : 0.0)
    }

    // ── Everything, centred as one stack ──────────────────────────────────────
    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: 0
        opacity: 0

        transform: Translate { id: entryTx; y: 60 }

        NumberAnimation on opacity {
            from: 0; to: 1; duration: 480; easing.type: Easing.OutCubic; running: true
        }
        NumberAnimation {
            target: entryTx; property: "y"
            from: 60; to: 0; duration: 520; easing.type: Easing.OutCubic; running: true
        }

        // ── Clock ─────────────────────────────────────────────────────────────
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            CustomText {
                id: hoursText
                content: root._hours
                size: 104; weight: 700
                font.family: root._font
                customColor: Colors.surfaceText
            }

            CustomText {
                content: ":"
                size: 104; weight: 700
                font.family: root._font
                customColor: Colors.outline

                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 0.25; duration: 520; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 520; easing.type: Easing.InOutSine }
                }
            }

            CustomText {
                content: root._minutes
                size: 104; weight: 700
                font.family: root._font
                customColor: Colors.primary
            }

            Item {
                width: periodText.implicitWidth + 6
                height: hoursText.implicitHeight

                CustomText {
                    id: periodText
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 26
                    anchors.right: parent.right
                    content: root._period
                    size: 15; weight: 700
                    customColor: Colors.outline
                    font.letterSpacing: 2
                }
            }
        }

        Item { Layout.preferredHeight: 2 }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            content: ServiceClock.day + "  ·  " + ServiceClock.month + " " + ServiceClock.date + ", " + ServiceClock.year
            size: 14
            customColor: Colors.surfaceVariantText
        }

        Item { Layout.preferredHeight: 44 }

        // ── Login card ────────────────────────────────────────────────────────
        Rectangle {
            id: panel
            Layout.alignment: Qt.AlignHCenter
            width: 400
            height: inner.implicitHeight + 52
            radius: 28
            color: Colors.surfaceContainer

            ColumnLayout {
                id: inner
                anchors {
                    top: parent.top; left: parent.left; right: parent.right
                    topMargin: 26; leftMargin: 26; rightMargin: 26
                }
                spacing: 0

                // ── Avatar ────────────────────────────────────────────────────
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 72; implicitHeight: 72

                    Rectangle {
                        anchors.fill: parent
                        radius: height
                        color: Colors.primaryContainer

                        CustomText {
                            anchors.centerIn: parent
                            content: root._initial
                            size: 28; weight: 700
                            font.family: root._font
                            customColor: Colors.primaryContainerText
                        }
                    }

                    ClippingWrapperRectangle {
                        anchors.fill: parent
                        radius: parent.height
                        color: "transparent"
                        visible: avatar.status === Image.Ready

                        Image {
                            id: avatar
                            anchors.fill: parent
                            source: root._profile
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 144
                            sourceSize.height: 144
                            asynchronous: true
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height
                        color: "transparent"
                        border.width: 2.5
                        border.color: Colors.primary
                    }
                }

                Item { Layout.preferredHeight: 12 }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.context.currentUser
                    size: 19; weight: 700
                }

                Item { Layout.preferredHeight: 2 }

                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "Hyprland"
                    size: 12
                    customColor: Colors.outline
                }

                Item { Layout.preferredHeight: 22 }

                // ── Password input ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 52; radius: 16
                    color: Colors.surfaceContainerHighest

                    transform: Translate { id: shakeTx; x: 0 }
                    SequentialAnimation {
                        running: root.context.showFailure
                        NumberAnimation { target: shakeTx; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shakeTx; property: "x"; to: 10;  duration: 90; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeTx; property: "x"; to: -8;  duration: 90; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeTx; property: "x"; to: 8;   duration: 90; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeTx; property: "x"; to: 0;   duration: 50 }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Rectangle {
                            width: 34; height: 34; radius: 10
                            color: root.context.showFailure
                                ? Qt.alpha(Colors.error, 0.15)
                                : root.context.unlockInProgress
                                    ? Qt.alpha(Colors.primary, 0.15)
                                    : "transparent"
                            Behavior on color { ColorAnimation { duration: 180 } }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: root.context.unlockInProgress ? "lock_open" : "lock"
                                iconSize: 20
                                customColor: root.context.showFailure
                                    ? Colors.error
                                    : root.context.unlockInProgress ? Colors.primary : Colors.outline
                                Behavior on customColor { ColorAnimation { duration: 180 } }
                            }
                        }

                        CustomShapeInput {
                            id: passInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: root.context.showFailure
                                ? "Wrong password — try again"
                                : "Enter password"
                            placeholderColor: root.context.showFailure ? Colors.error : Colors.outline
                            enabled: !root.context.unlockInProgress

                            onTextChanged: root.context.currentText = text
                            onAccepted:    root.context.tryUnlock()

                            Connections {
                                target: root.context
                                function onCurrentTextChanged() {
                                    passInput.text = root.context.currentText
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 14 }

                // ── Power actions ─────────────────────────────────────────────
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Item {
                        id: restartBtn
                        width: restartInner.implicitWidth + 26; height: 38
                        property bool hovered: false

                        Rectangle {
                            anchors.fill: parent; radius: 12
                            color: restartBtn.hovered
                                ? Qt.alpha(Colors.primary, 0.14)
                                : Colors.surfaceContainerHighest
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                id: restartInner
                                anchors.centerIn: parent; spacing: 6

                                MaterialIconSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: "restart_alt"; iconSize: 18
                                    customColor: restartBtn.hovered ? Colors.primary : Colors.outline
                                    Behavior on customColor { ColorAnimation { duration: 150 } }
                                }
                                CustomText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: "Restart"; size: 13; weight: 600
                                    customColor: restartBtn.hovered ? Colors.primary : Colors.outline
                                }
                            }
                        }

                        CustomMouseArea {
                            anchors.fill: parent; radius: 12; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: restartBtn.hovered = true
                            onExited:  restartBtn.hovered = false
                            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                        }
                    }

                    Item {
                        id: shutdownBtn
                        width: shutdownInner.implicitWidth + 26; height: 38
                        property bool hovered: false

                        Rectangle {
                            anchors.fill: parent; radius: 12
                            color: shutdownBtn.hovered
                                ? Qt.alpha(Colors.error, 0.14)
                                : Colors.surfaceContainerHighest
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                id: shutdownInner
                                anchors.centerIn: parent; spacing: 6

                                MaterialIconSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: "power_settings_new"; iconSize: 18
                                    customColor: shutdownBtn.hovered ? Colors.error : Colors.outline
                                    Behavior on customColor { ColorAnimation { duration: 150 } }
                                }
                                CustomText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: "Shut Down"; size: 13; weight: 600
                                    customColor: shutdownBtn.hovered ? Colors.error : Colors.outline
                                }
                            }
                        }

                        CustomMouseArea {
                            anchors.fill: parent; radius: 12; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: shutdownBtn.hovered = true
                            onExited:  shutdownBtn.hovered = false
                            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                        }
                    }
                }
            }
        }
    }
}
