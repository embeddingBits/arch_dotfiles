import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings
import qs.modules.services

PopupWindow {
    id: root
    implicitWidth: 300
    implicitHeight: col.implicitHeight + 32
    visible: true
    color: "transparent"
    signal close

    property real srcWidth: 90
    property real srcHeight: 30
    property real srcRadius: 15

    anchor {
        window: layout
        rect.x: utility.soundPanelCenterX - root.implicitWidth / 2
        rect.y: sectionsRow.y + utility.y + utility.height + (SettingsConfig.general.barMode === "pill" ? 8 : 4)
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: true
        windows: [QsWindow.window]
        onCleared: morph.close()
    }

    readonly property real micVolume: ServicePipewire.source?.audio?.volume ?? 0

    MorphCard {
        id: morph
        anchors.fill: parent

        srcWidth:  root.srcWidth
        srcHeight: root.srcHeight
        srcRadius: root.srcRadius

        contentHeight: col.implicitHeight + 32
        cardRadius: 24
        cardColor: Colors.surface

        onCloseFinished: root.close()
        Component.onCompleted: Qt.callLater(morph.open)

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors { margins: 16; topMargin: 16 }
            spacing: 0

            // ── Output ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                CustomText {
                    content: "OUTPUT"
                    size: 10; weight: 700
                    customColor: Colors.primary
                    font.letterSpacing: 2
                }

                Item { Layout.fillWidth: true }

                CustomText {
                    content: ServicePipewire.muted ? "Muted"
                           : Math.round(ServicePipewire.volume * 100) + "%"
                    size: 13; weight: 700
                    customColor: ServicePipewire.muted ? Colors.error : Colors.surfaceText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8

                LevelSlider {
                    Layout.fillWidth: true
                    value: ServicePipewire.volume
                    icon: ServicePipewire.muted ? "volume_off"
                        : ServicePipewire.volume > 0.5 ? "volume_up"
                        : ServicePipewire.volume > 0   ? "volume_down"
                                                       : "volume_mute"
                    dimmed: ServicePipewire.muted
                    onMoved: v => ServicePipewire.setVolume(v)
                }

                MuteButton {
                    active: ServicePipewire.muted
                    icon: ServicePipewire.muted ? "volume_off" : "volume_up"
                    onToggled: ServicePipewire.toggleMute()
                }
            }

            CustomList {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.preferredHeight: 34
                color: Colors.surfaceContainerHigh
                currentVal: ServicePipewire.sink?.description ?? ""
                list: ServicePipewire.sinks
                onIsListClickedChanged: focusGrab.active = !isListClicked
                onListChildClicked: child => ServicePipewire.setAudioSink(child)
            }

            // ── Input ──────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 18
                implicitHeight: 1
                color: Colors.outlineVariant
                opacity: 0.4
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                spacing: 6

                CustomText {
                    content: "INPUT"
                    size: 10; weight: 700
                    customColor: Colors.primary
                    font.letterSpacing: 2
                }

                Item { Layout.fillWidth: true }

                CustomText {
                    content: ServicePipewire.micMuted ? "Muted"
                           : Math.round(root.micVolume * 100) + "%"
                    size: 13; weight: 700
                    customColor: ServicePipewire.micMuted ? Colors.error : Colors.surfaceText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8

                LevelSlider {
                    Layout.fillWidth: true
                    value: root.micVolume
                    icon: ServicePipewire.micMuted ? "mic_off" : "mic"
                    dimmed: ServicePipewire.micMuted
                    onMoved: v => {
                        if (ServicePipewire.source?.audio) {
                            ServicePipewire.source.audio.muted  = false
                            ServicePipewire.source.audio.volume = v
                        }
                    }
                }

                MuteButton {
                    active: ServicePipewire.micMuted
                    icon: ServicePipewire.micMuted ? "mic_off" : "mic"
                    onToggled: ServicePipewire.toggleMicMute()
                }
            }

            CustomList {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.preferredHeight: 34
                color: Colors.surfaceContainerHigh
                currentVal: ServicePipewire.source?.description ?? ""
                list: ServicePipewire.sources
                onIsListClickedChanged: focusGrab.active = !isListClicked
                onListChildClicked: child => ServicePipewire.setAudioSource(child)
            }
        }
    }

    // ── Level slider ──────────────────────────────────────────────────────
    // A thick pill with the icon riding inside it, matching the vertical
    // sliders in the dashboard. The whole bar is the hit target, so there is no
    // thumb to aim at — the fill edge is the only thing that has to be read.
    component LevelSlider: Item {
        id: vs
        implicitHeight: 44

        property real value: 0
        property string icon: ""
        property bool dimmed: false
        signal moved(real val)

        // While dragging, show the dragged value rather than waiting for the
        // service to echo it back, or the fill lags behind the cursor.
        property bool _drag: false
        property real _dragVal: 0
        readonly property real _shown: _drag ? _dragVal : value

        scale: sliderArea.pressed ? 0.985 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: Colors.surfaceContainerHigh
            clip: true

            Rectangle {
                // Never retreats past the icon, so the icon always sits on the
                // fill and one colour works for it at any volume — including 0.
                width: Math.max(vs.height, track.width * vs._shown)
                height: parent.height
                radius: height / 2
                color: vs.dimmed ? Colors.outlineVariant : Colors.primary
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on width {
                    enabled: !vs._drag
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }
            }

            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 13
                content: vs.icon
                iconSize: 19
                customColor: vs.dimmed ? Colors.surfaceText : Colors.primaryText
            }
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function snap(mx) {
                var v = Math.max(0, Math.min(1, mx / vs.width))
                vs._dragVal = v
                vs.moved(v)
            }

            onPressed:         event => { vs._drag = true;  snap(event.x) }
            onPositionChanged: event => { if (pressed) snap(event.x) }
            onReleased:        vs._drag = false
        }
    }

    // ── Mute button ───────────────────────────────────────────────────────
    component MuteButton: Rectangle {
        id: mb
        implicitWidth: 44
        implicitHeight: 44
        radius: 22

        property bool active: false      // muted
        property string icon: ""
        signal toggled()

        color: mb.active ? Qt.alpha(Colors.error, 0.16)
             : hov.containsMouse ? Colors.primaryContainer
                                 : Colors.surfaceContainerHigh
        Behavior on color { ColorAnimation { duration: 130 } }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: mb.icon
            iconSize: 19
            customColor: mb.active ? Colors.error
                       : hov.containsMouse ? Colors.primaryContainerText
                                           : Colors.outline
            scale: hov.pressed ? 0.85 : 1
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 2 } }
        }

        MouseArea {
            id: hov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.toggled()
        }
    }
}
