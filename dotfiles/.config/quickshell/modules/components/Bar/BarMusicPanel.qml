import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Expanded player for `barCenter: "music"`, revealed on hover the same way the
// calendar is. Transparent like Calander — the bar's pill shape draws the
// surface underneath, so a background here would double it up.
//
// Artwork and transport sit side by side rather than stacked, which buys the
// seek bar the full panel width along the bottom: scrubbing accuracy is a
// function of how many pixels a second is worth.
Item {
    id: root
    anchors.fill: parent

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null

    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength

    // Artist and album on one line — three stacked secondary lines made the
    // title compete with its own metadata.
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
        anchors.margins: 18
        spacing: 0
        visible: root.hasTrack

        // ── Artwork + metadata + transport ────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            MusicArtwork {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 100
                Layout.alignment: Qt.AlignVCenter
                cornerRadius: 20
                interactive: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item { Layout.fillHeight: true }

                MusicSourceChip { Layout.bottomMargin: 5 }

                CustomMarqueeText {
                    Layout.fillWidth: true
                    content: ServiceMusic.activeTrack?.title ?? ""
                    size: 17
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

                Item { Layout.fillHeight: true }

                MusicTransport {
                    Layout.fillWidth: true
                    playSize: 42
                    sideSize: 34
                }
            }
        }

        // ── Seek ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            spacing: 10

            CustomText {
                Layout.preferredWidth: 38
                content: ServiceMusic.formatTime(root.elapsed)
                size: 11
                customColor: Colors.outline
            }

            MusicSeekBar { Layout.fillWidth: true }

            CustomText {
                Layout.preferredWidth: 38
                content: ServiceMusic.formatTime(root.total)
                size: 11
                customColor: Colors.outline
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
