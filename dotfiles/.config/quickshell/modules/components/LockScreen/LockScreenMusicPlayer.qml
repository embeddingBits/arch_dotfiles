import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import Quickshell.Widgets
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Item {
    id: root

    readonly property real _length: ServiceMusic.trackLength
    readonly property real _position: ServiceMusic.activePlayer?.position ?? 0

    // MPRIS position is only re-read when the property is re-notified, so nudge
    // it once a second while something is actually playing.
    Timer {
        interval: 1000
        repeat: true
        running: ServiceMusic.isPlaying && (ServiceMusic.activePlayer?.positionSupported ?? false)
        onTriggered: ServiceMusic.activePlayer.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Album art
        // ClippingWrapperRectangle wraps exactly one visual child; the
        // placeholder has to sit beside it, not inside it.
        Item {
            Layout.preferredWidth: height
            Layout.fillHeight: true

            ClippingWrapperRectangle {
                anchors.fill: parent
                radius: 12
                color: Colors.surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    sourceSize.width: 256
                    sourceSize.height: 256
                    source: ServiceMusic.activeTrack?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: (ServiceMusic.activeTrack?.artUrl?.length ?? 0) > 0
                }
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_note"; iconSize: 18; customColor: Colors.outline
                visible: (ServiceMusic.activeTrack?.artUrl?.length ?? 0) === 0
            }
        }

        // Track info + seek progress
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Item { Layout.fillHeight: true }

            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.title ?? "Nothing playing"
                size: 12; weight: 600; elide: Text.ElideRight
            }
            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.artist ?? ""
                size: 10; customColor: Colors.outline; elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 3
                spacing: 7
                visible: root._length > 0

                CustomText {
                    content: ServiceMusic.formatTime(root._position)
                    size: 9; weight: 500; customColor: Colors.outline
                }

                // Plain Item host so the bar's width comes from anchors, not from
                // its own implicitWidth feeding back into the layout.
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 3

                    CustomProgressBar {
                        anchors.fill: parent
                        valueBarWidth: parent.width
                        valueBarHeight: 3
                        // Canvas repaints on value change only; no 60fps timer here.
                        sperm: false
                        animateSperm: false
                        highlightColor: Colors.primary
                        trackColor: Colors.surfaceContainerHighest
                        value: root._length > 0 ? Math.min(1, root._position / root._length) : 0
                    }
                }

                CustomText {
                    content: ServiceMusic.formatTime(root._length)
                    size: 9; weight: 500; customColor: Colors.outline
                }
            }

            Item { Layout.fillHeight: true }
        }

        // Controls
        RowLayout {
            spacing: 4

            Rectangle {
                width: 30; height: 30; radius: 10
                color: Colors.surfaceContainerHighest
                opacity: ServiceMusic.canGoPrevious ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 150 } }
                MaterialIconSymbol { anchors.centerIn: parent; content: "skip_previous"; iconSize: 16 }
                CustomMouseArea {
                    anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceMusic.previous()
                }
            }

            Rectangle {
                width: 34; height: 34; radius: 11
                color: Colors.primary
                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                    iconSize: 18; customColor: Colors.primaryText
                }
                CustomMouseArea {
                    anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceMusic.togglePlaying()
                }
            }

            Rectangle {
                width: 30; height: 30; radius: 10
                color: Colors.surfaceContainerHighest
                opacity: ServiceMusic.canGoNext ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 150 } }
                MaterialIconSymbol { anchors.centerIn: parent; content: "skip_next"; iconSize: 16 }
                CustomMouseArea {
                    anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceMusic.next()
                }
            }
        }
    }
}
