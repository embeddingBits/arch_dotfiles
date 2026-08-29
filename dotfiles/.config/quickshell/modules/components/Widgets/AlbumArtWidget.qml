import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Full-bleed album art with a blurred oversized copy bleeding out behind it, a
// scrim so the text stays legible over any cover, and a progress line along the
// bottom edge.
//
// Square art rarely fills a square tile (covers are cropped, and some players
// report portrait art), so the blur underneath fills whatever the cover leaves
// rather than letting the surface colour show through as a hard band.
WidgetHost {
    id: root
    configKey: "albumArt"
    tile: WidgetSizes.large
    defaultPos: Qt.point(760, 620)

    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool hasArt: root.artUrl !== ""
    readonly property bool hasTrack: ServiceMusic.activePlayer !== null

    readonly property real progress: {
        const len = ServiceMusic.trackLength
        if (len <= 0) return 0
        return Math.max(0, Math.min(1, (ServiceMusic.activePlayer?.position ?? 0) / len))
    }

    // ── Card ──────────────────────────────────────────────────────────
    Item {
        id: card
        anchors.fill: parent

        // Everything that needs rounding is drawn into this, then masked once
        Item {
            id: cardContent
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: Colors.surface
            }

            // Blurred bleed
            Image {
                id: bleed
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(160, 160)   // downscaled — it gets blurred anyway
                visible: false
                asynchronous: true
            }

            MultiEffect {
                anchors.fill: parent
                source: bleed
                visible: root.hasArt
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                brightness: -0.25
                saturation: 0.35
            }

            // The cover itself
            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 320
                sourceSize.height: 320
                visible: root.hasArt
                asynchronous: true
            }

            // Scrim — without it, light covers make the title unreadable
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.5
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.alpha(Colors.surface, 0.92) }
                }
            }
        }

        Rectangle {
            id: cardMask
            anchors.fill: parent
            radius: WidgetSizes.radius
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: cardContent
            maskEnabled: true
            maskSource: cardMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // ── Empty state ───────────────────────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            visible: !root.hasTrack

            MaterialIconSymbol {
                Layout.alignment: Qt.AlignHCenter
                content: "album"
                iconSize: 40
                customColor: Colors.outline
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: "Nothing playing"
                size: 13
                customColor: Colors.outline
            }
        }

        // Placeholder when a player is up but reports no artwork
        MaterialIconSymbol {
            anchors.centerIn: parent
            content: "music_note"
            iconSize: 48
            customColor: Colors.outline
            visible: root.hasTrack && !root.hasArt
        }

        // ── Track text ────────────────────────────────────────────────
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.bottomMargin: 26
            spacing: 2
            visible: root.hasTrack

            RowLayout {
                spacing: 6

                MaterialIconSymbol {
                    content: ServiceMusic.isPlaying ? "equalizer" : "pause"
                    iconSize: 13
                    customColor: Colors.primary
                }
                CustomText {
                    Layout.fillWidth: true
                    content: ServiceMusic.activeTrack?.album ?? ""
                    size: 11
                    customColor: Colors.primary
                }
            }

            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.title ?? ""
                size: 17
                weight: 700
            }

            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.artist ?? ""
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Progress ──────────────────────────────────────────────────
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.bottomMargin: 14
            height: 3
            visible: root.hasTrack

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Colors.outlineVariant
                opacity: 0.6
            }

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: height / 2
                color: Colors.primary

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
            }
        }
    }
}
