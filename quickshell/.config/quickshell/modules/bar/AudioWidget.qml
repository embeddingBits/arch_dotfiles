import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property bool volumePopupOpen
    signal toggleVolume

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Layout.preferredWidth: 64
    Layout.preferredHeight: 26

    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: audioMouse.containsMouse || root.volumePopupOpen ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: 4

        Text {
            text: {
                if (!Pipewire.defaultAudioSink?.audio)
                    return "󰖁";
                if (root.muted || root.vol === 0)
                    return "󰝟";
                if (root.vol < 0.33)
                    return "󰕿";
                if (root.vol < 0.66)
                    return "󰖀";
                return "󰕾";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: Theme.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Math.round(root.vol * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            font.weight: 600
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.90)
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlineAudio
        opacity: audioMouse.containsMouse || root.volumePopupOpen ? 1 : 0.92
    }

    MouseArea {
        id: audioMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleVolume()
        onWheel: function (wheel) {
            if (!Pipewire.defaultAudioSink?.audio)
                return;
            let s = 0.05;
            let v = Pipewire.defaultAudioSink.audio.volume + (wheel.angleDelta.y > 0 ? s : -s);
            Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, v));
            if (Pipewire.defaultAudioSink.audio.muted && v > 0)
                Pipewire.defaultAudioSink.audio.muted = false;
        }
    }
}
