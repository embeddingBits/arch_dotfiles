import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

// Collapsed now-playing for the bar's centre slot — the music counterpart to
// CustomClock. Sized to the 40px bar, so everything here is tuned tight: the
// progress reads as a ring around the artwork rather than a bar, because at this
// height a bar would either be invisible or crowd the text.
//
// Nothing here is clickable. Hovering the centre slot expands it into the full
// panel almost immediately, so a click target on this item would never be hit —
// the interactive controls all live on the expanded surfaces.
Item {
    id: root
    anchors.centerIn: parent
    implicitWidth:  root.hasTrack ? content.implicitWidth  : empty.implicitWidth
    implicitHeight: root.hasTrack ? content.implicitHeight : empty.implicitHeight

    // Shrunk by the caller in "both" mode, where the clock takes half the slot.
    property real maxTextWidth: 160

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool playing: ServiceMusic.isPlaying

    readonly property real progress: {
        const len = ServiceMusic.trackLength
        if (len <= 0) return 0
        return Math.max(0, Math.min(1, (ServiceMusic.activePlayer?.position ?? 0) / len))
    }

    // ── Nothing playing ───────────────────────────────────────────────
    RowLayout {
        id: empty
        anchors.centerIn: parent
        spacing: 8
        visible: !root.hasTrack

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 12
            color: Colors.surfaceContainerHigh

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_off"
                iconSize: 14
                customColor: Colors.outline
            }
        }

        CustomText {
            content: "Nothing playing"
            size: 12
            weight: 500
            customColor: Colors.outline
        }
    }

    // ── Now playing ───────────────────────────────────────────────────
    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 9
        visible: root.hasTrack

        // Artwork + progress ring
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            CustomCircularProgressBar {
                anchors.fill: parent
                progress: root.progress
                thickness: 2
                showText: false
                baseColor: Colors.surfaceContainerHighest
                lineColor: Colors.primary
            }

            MusicArtwork {
                anchors.centerIn: parent
                width: 22
                height: 22
                cornerRadius: 7
                showPlaceholder: false   // handled below, where paused/playing differ
            }

            // With no artwork the ring's centre is dead space; fill it with the
            // playing state instead of a generic note glyph.
            MusicEqualizer {
                anchors.centerIn: parent
                implicitHeight: 12
                barColor: Colors.primary
                active: root.playing
                visible: root.artUrl === "" && root.playing
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_note"
                iconSize: 13
                customColor: Colors.outline
                visible: root.artUrl === "" && !root.playing
            }
        }

        // Title / artist
        ColumnLayout {
            spacing: -1

            CustomMarqueeText {
                Layout.maximumWidth: root.maxTextWidth
                content: ServiceMusic.activeTrack?.title ?? ""
                size: 12
                weight: 600
                customColor: Colors.surfaceText
                scrolling: root.playing
            }

            CustomText {
                Layout.maximumWidth: root.maxTextWidth
                content: ServiceMusic.activeTrack?.artist ?? ""
                size: 10
                weight: 500
                customColor: Colors.outline
            }
        }
    }
}
