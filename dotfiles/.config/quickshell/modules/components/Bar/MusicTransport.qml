import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Shuffle / prev / play / next / repeat, shared by every music surface in the
// bar. Sizes are parameterised because the wide panel and the column panel have
// very different budgets for the same five controls.
RowLayout {
    id: root

    property real playSize: 42
    property real sideSize: 34
    property bool showToggles: true

    spacing: 6

    ToggleIcon {
        icon: "shuffle"
        on: ServiceMusic.hasShuffle
        enabled_: ServiceMusic.shuffleSupported
        visible: root.showToggles
        onTapped: ServiceMusic.setShuffle(!ServiceMusic.hasShuffle)
    }

    Item { Layout.fillWidth: true }

    M3IconButton {
        implicitWidth: root.sideSize
        implicitHeight: root.sideSize
        icon: "skip_previous"
        iconSize: Math.round(root.sideSize * 0.56)
        opacity: ServiceMusic.canGoPrevious ? 1 : 0.35
        onClicked: if (ServiceMusic.canGoPrevious) ServiceMusic.previous()
    }

    M3IconButton {
        implicitWidth: root.playSize
        implicitHeight: root.playSize
        icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
        iconSize: Math.round(root.playSize * 0.55)
        color: Colors.primary
        iconColor: Colors.primaryText
        iconHoverColor: Colors.primaryText
        onClicked: if (ServiceMusic.canTogglePlaying) ServiceMusic.togglePlaying()
    }

    M3IconButton {
        implicitWidth: root.sideSize
        implicitHeight: root.sideSize
        icon: "skip_next"
        iconSize: Math.round(root.sideSize * 0.56)
        opacity: ServiceMusic.canGoNext ? 1 : 0.35
        onClicked: if (ServiceMusic.canGoNext) ServiceMusic.next()
    }

    Item { Layout.fillWidth: true }

    // Cycles none → playlist → track, mirroring how players present it
    ToggleIcon {
        icon: ServiceMusic.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
        on: ServiceMusic.loopState !== MprisLoopState.None
        enabled_: ServiceMusic.loopSupported
        visible: root.showToggles
        onTapped: {
            const s = ServiceMusic.loopState
            ServiceMusic.setLoopState(
                s === MprisLoopState.None     ? MprisLoopState.Playlist
              : s === MprisLoopState.Playlist ? MprisLoopState.Track
                                              : MprisLoopState.None)
        }
    }

    // ── Small stateful icon button (shuffle / repeat) ──────────────────
    component ToggleIcon: Rectangle {
        id: ti
        property string icon: ""
        property bool on: false
        property bool enabled_: true
        signal tapped()

        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        color: ti.on ? Qt.alpha(Colors.primary, 0.16) : "transparent"
        opacity: ti.enabled_ ? 1 : 0.3
        Behavior on color { ColorAnimation { duration: 130 } }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: ti.icon
            iconSize: 17
            customColor: ti.on ? Colors.primary
                       : tiArea.containsMouse ? Colors.surfaceText
                                              : Colors.outline
        }

        MouseArea {
            id: tiArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: ti.enabled_
            cursorShape: Qt.PointingHandCursor
            onClicked: ti.tapped()
        }
    }
}
