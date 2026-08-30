import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "../../config/Theme.qml" as Theme

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio
        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0
            implicitWidth: 400
            implicitHeight: 50
            color: Theme.bg
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                border.color: Theme.border
                border.width: 1
                radius: Theme.radius
                color: Theme.bg

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }

                    Text {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: Theme.fg
                        text: {
                            const s = Pipewire.defaultAudioSink;
                            if (!s?.audio)
                                return "\uf026";
                            if (s.audio.muted || s.audio.volume === 0)
                                return "\uf026";
                            if (s.audio.volume < 0.5)
                                return "\uf027";
                            return "\uf028";
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: Theme.radius
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18)

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            radius: Theme.radius
                            implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                            color: Theme.accent

                            Behavior on implicitWidth {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: 600
                        color: Theme.fg
                    }
                }
            }
        }
    }
}
