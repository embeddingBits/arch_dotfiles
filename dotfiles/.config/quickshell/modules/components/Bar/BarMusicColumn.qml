import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Tall now-playing column, used by the `barCenter: "both"` panel where the
// calendar has already claimed the width. Same content as BarMusicPanel stood on
// end: artwork on top so it can be big, then metadata, seek, transport.
//
// Owns its own padding so the caller can just anchors.fill it.
Item {
    id: root

    property real padding: 16

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null

    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength

    // Square, capped so a wide slot doesn't push the transport off the bottom
    readonly property real artSide: Math.max(0, Math.min(root.width - root.padding * 2, 170))

    readonly property string subtitle: {
        const a = ServiceMusic.activeTrack?.artist ?? ""
        const b = ServiceMusic.activeTrack?.album ?? ""
        if (a !== "" && b !== "" && a !== b) return a + "  ·  " + b
        return a !== "" ? a : b
    }

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasTrack
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 0
        visible: root.hasTrack

        MusicArtwork {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.artSide
            Layout.preferredHeight: root.artSide
            cornerRadius: 24
            placeholderIconSize: 44
            interactive: true
        }

        MusicSourceChip {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
        }

        CustomMarqueeText {
            Layout.fillWidth: true
            Layout.topMargin: 8
            content: ServiceMusic.activeTrack?.title ?? ""
            size: 16
            weight: 700
            customColor: Colors.surfaceText
            scrolling: ServiceMusic.isPlaying
        }

        CustomText {
            Layout.fillWidth: true
            Layout.topMargin: 1
            content: root.subtitle
            size: 12
            customColor: Colors.outline
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 10 }

        // ── Seek ──────────────────────────────────────────────────────
        // Times sit under the track rather than beside it: at this width,
        // flanking labels would leave the scrubber too short to aim with.
        MusicSeekBar { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: -2
            spacing: 0

            CustomText {
                content: ServiceMusic.formatTime(root.elapsed)
                size: 11
                customColor: Colors.outline
            }

            Item { Layout.fillWidth: true }

            CustomText {
                content: ServiceMusic.formatTime(root.total)
                size: 11
                customColor: Colors.outline
            }
        }

        MusicTransport {
            Layout.fillWidth: true
            Layout.topMargin: 6
            playSize: 44
            sideSize: 32
        }
    }
}
