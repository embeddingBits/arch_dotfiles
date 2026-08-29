import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// The scrub track, shared by every music surface in the bar.
//
// Driven directly rather than through M3Slider: a two-way binding fights
// the once-a-second position tick, so the handle jumps back under the cursor
// mid-drag. Here the drag owns the displayed value until release.
Item {
    id: root

    property real barHeight: 4
    property real hoverHeight: 6
    property real handleSize: 12

    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength
    readonly property real progress: root.total > 0
        ? Math.max(0, Math.min(1, root.elapsed / root.total)) : 0
    readonly property bool canSeek: ServiceMusic.activePlayer?.canSeek ?? false

    property bool dragging: false
    property real dragVal: 0
    readonly property real shown: root.dragging ? root.dragVal : root.progress
    readonly property bool active: seekArea.containsMouse || root.dragging

    implicitHeight: Math.max(root.handleSize, 16)

    M3WavyProgressBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 10
        progress: root.shown
        activeThickness: root.active ? root.hoverHeight : root.barHeight
        trackThickness: root.active ? root.hoverHeight : root.barHeight
        trackColor: Colors.surfaceContainerHigh
        showStopIndicator: false
        waveAmplitude: ServiceMusic.isPlaying && !root.dragging ? 3 : 0
    }

    Rectangle {
        id: seekTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.active ? root.hoverHeight : root.barHeight
        radius: height / 2
        color: "transparent"
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    }

    // Only appears once the bar is live, so a non-seekable stream doesn't
    // advertise a control it hasn't got
    Rectangle {
        width: root.handleSize
        height: root.handleSize
        radius: width / 2
        color: Colors.primary
        anchors.verticalCenter: parent.verticalCenter
        x: seekTrack.width * root.shown - width / 2
        visible: root.canSeek && root.active
    }

    MouseArea {
        id: seekArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        enabled: root.canSeek
        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
        preventStealing: true

        function frac(mx) {
            return Math.max(0, Math.min(1, mx / seekTrack.width))
        }

        onPressed: e => { root.dragging = true; root.dragVal = frac(e.x) }
        onPositionChanged: e => { if (pressed) root.dragVal = frac(e.x) }
        onReleased: e => {
            root.dragging = false
            if (root.total > 0)
                ServiceMusic.activePlayer.position = frac(e.x) * root.total
        }
    }
}
