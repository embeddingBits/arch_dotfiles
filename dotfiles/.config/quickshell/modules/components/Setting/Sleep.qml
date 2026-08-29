import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import QtQuick.Controls

// Idle behaviour. Writing here regenerates ~/.config/hypr/hypridle.conf and
// restarts hypridle — see ServiceIdle.
Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    function patch(key, value) {
        var p = {}
        p[key] = value
        SettingsConfig.sleep = Object.assign({}, SettingsConfig.sleep, p)
    }

    // Each stage should fire after the one before it. Flagging the conflict is
    // more useful than silently reordering the user's numbers.
    readonly property bool orderOk: {
        const s = SettingsConfig.sleep
        if (!s) return true
        var last = 0
        if (s.dimEnabled)       { if (s.dimMinutes      < last) return false; last = s.dimMinutes }
        if (s.lockEnabled)      { if (s.lockMinutes     < last) return false; last = s.lockMinutes }
        if (s.screenOffEnabled) { if (s.screenOffMinutes < last) return false; last = s.screenOffMinutes }
        if (s.suspendEnabled)   { if (s.suspendMinutes  < last) return false; last = s.suspendMinutes }
        return true
    }

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

            // ── Page header ──────────────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "bedtime"; iconSize: 20 }
                CustomText { content: "Sleep"; size: 20; customColor: Colors.primary }
            }

            CustomText {
                Layout.topMargin: 6
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                content: "What happens as the machine sits idle. Each stage counts from the last input, not from the previous stage."
                size: 12
                customColor: Colors.outline
            }

            // ── Conflict warning ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 14
                implicitHeight: 46
                radius: 16
                color: Qt.alpha(Colors.error, 0.13)
                visible: !root.orderOk

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    MaterialIconSymbol { content: "warning"; iconSize: 18; customColor: Colors.error }
                    CustomText {
                        Layout.fillWidth: true
                        content: "A later stage fires before an earlier one — it will never run."
                        size: 12
                        customColor: Colors.error
                    }
                }
            }

            // ── Stages ───────────────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Idle stages"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                Stage {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    title: "Dim the screen"
                    subtitle: "Drops the backlight; restores on any input"
                    enabledKey: "dimEnabled"
                    minutesKey: "dimMinutes"
                }

                Stage {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    title: "Lock"
                    subtitle: "Shows the lock screen"
                    enabledKey: "lockEnabled"
                    minutesKey: "lockMinutes"
                }

                Stage {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    title: "Screen off"
                    subtitle: "Powers the display down without suspending"
                    enabledKey: "screenOffEnabled"
                    minutesKey: "screenOffMinutes"
                }

                Stage {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    title: "Suspend"
                    subtitle: "Sleeps the machine; locks first"
                    enabledKey: "suspendEnabled"
                    minutesKey: "suspendMinutes"
                }
            }

            // ── Backlight level ──────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Dim level"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Dimmed brightness"; size: 14 }
                        CustomText {
                            content: "Backlight value while dimmed — avoid 0 on OLED"
                            size: 12; customColor: Colors.outline
                        }
                    }
                    Item { Layout.fillWidth: true }
                    CustomSpinBox {
                        color: Colors.surfaceContainerHighest
                        inc: 5
                        limit: 100
                        Component.onCompleted: val = SettingsConfig.sleep?.dimLevel ?? 10
                        onValChanged: if (val > 0) root.patch("dimLevel", val)
                    }
                }
            }

            // ── Apply ────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "hypridle"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Rewrite config now"; size: 14 }
                        CustomText {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            content: "Changes apply automatically. Use this to force a rewrite and restart."
                            size: 12; customColor: Colors.outline
                        }
                    }
                    Item { Layout.fillWidth: true }
                    M3IconButton {
                        implicitWidth: 42; implicitHeight: 34
                        icon: "restart_alt"
                        iconSize: 18
                        onClicked: ServiceIdle.apply()
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

    // ── One idle stage: toggle plus a minutes spinner ─────────────────────
    component Stage: CustomCard {
        id: stage
        property string title: ""
        property string subtitle: ""
        property string enabledKey: ""
        property string minutesKey: ""

        readonly property bool on: SettingsConfig.sleep?.[stage.enabledKey] ?? false

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ColumnLayout {
                spacing: 2
                CustomText {
                    content: stage.title
                    size: 14
                    customColor: stage.on ? Colors.surfaceText : Colors.outline
                }
                CustomText { content: stage.subtitle; size: 12; customColor: Colors.outline }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6
                opacity: stage.on ? 1 : 0.4

                CustomSpinBox {
                    color: Colors.surfaceContainerHighest
                    inc: 1
                    limit: 180
                    enabled: stage.on
                    Component.onCompleted: val = SettingsConfig.sleep?.[stage.minutesKey] ?? 10
                    onValChanged: if (val > 0) root.patch(stage.minutesKey, val)
                }

                CustomText { content: "min"; size: 12; customColor: Colors.outline }
            }

            CustomToogle {
                isToggleOn: stage.on
                onToggled: function(state) { root.patch(stage.enabledKey, state) }
            }
        }
    }
}
