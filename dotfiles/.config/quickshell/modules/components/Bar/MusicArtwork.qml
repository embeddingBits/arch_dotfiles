import Quickshell.Widgets
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Album art with a placeholder for the (common) case of a player that publishes
// no artwork. `interactive` adds a scrim + play/pause overlay on hover, which is
// only worth it on the expanded panels — the collapsed bar item expands away
// under the cursor before a click could land.
Item {
    id: root

    property real cornerRadius: 20
    property real placeholderIconSize: 34
    // Off where the caller draws its own no-artwork treatment
    property bool showPlaceholder: true
    property bool interactive: false

    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool hovered: root.interactive && artArea.containsMouse

    ClippingWrapperRectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Colors.surfaceContainerHigh

        Image {
            source: root.artUrl
            sourceSize: Qt.size(Math.max(1, Math.round(root.width)),
                                Math.max(1, Math.round(root.height)))
            fillMode: Image.PreserveAspectCrop
            visible: root.artUrl !== ""
            asynchronous: true
        }
    }

    MaterialIconSymbol {
        anchors.centerIn: parent
        content: "album"
        iconSize: root.placeholderIconSize
        customColor: Colors.outline
        visible: root.showPlaceholder && root.artUrl === "" && !root.hovered
    }

    // ── Hover overlay ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.alpha(Colors.scrim, 0.45)
        opacity: root.hovered ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: ServiceMusic.isPlaying ? "pause" : "play_arrow"
            iconSize: Math.max(20, Math.round(root.width * 0.34))
            fill: 1
            customColor: "white"
        }
    }

    MouseArea {
        id: artArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive && ServiceMusic.canTogglePlaying
        cursorShape: Qt.PointingHandCursor
        onClicked: ServiceMusic.togglePlaying()
    }
}
