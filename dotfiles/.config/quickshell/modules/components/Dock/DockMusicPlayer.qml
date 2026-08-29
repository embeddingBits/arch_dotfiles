import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import Quickshell.Widgets
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Rectangle {
    id: player
    radius: 14
    color: Colors.surfaceContainerHigh

    readonly property bool hasTrack: ServiceMusic.activeTrack !== null

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 6

        // ── Album art ─────────────────────────────────────────────────────
        ClippingWrapperRectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 8
            color: Colors.surfaceContainerHighest

            Item {
                anchors.fill: parent

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "music_note"
                    iconSize: 18
                    customColor: Colors.outline
                    visible: !player.hasTrack || (ServiceMusic.activeTrack?.artUrl ?? "") === ""
                }

                Image {
                    anchors.fill: parent
                    sourceSize.width: 128
                    sourceSize.height: 128
                    source: ServiceMusic.activeTrack?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: player.hasTrack && source !== ""
                }
            }
        }

        // ── Track info ────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.title ?? "Nothing playing"
                size: 12
                weight: 600
                elide: Text.ElideRight
                customColor: player.hasTrack ? Colors.surfaceText : Colors.outline
            }

            CustomText {
                Layout.fillWidth: true
                content: ServiceMusic.activeTrack?.artist ?? ""
                size: 10
                customColor: Colors.outline
                elide: Text.ElideRight
                visible: (ServiceMusic.activeTrack?.artist ?? "").length > 0
            }
        }

        // ── Controls ──────────────────────────────────────────────────────

        // Previous
        Rectangle {
            implicitWidth: 24; implicitHeight: 24; radius: 7
            color: prevArea.containsMouse ? Qt.alpha(Colors.primary, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "skip_previous"; iconSize: 16
                customColor: prevArea.containsMouse ? Colors.primary : Colors.outline
                Behavior on customColor { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: ServiceMusic.previous()
            }
        }

        // Play / Pause
        Rectangle {
            implicitWidth: 28; implicitHeight: 28; radius: 9
            color: playArea.containsMouse ? Colors.primary : Colors.primaryContainer
            Behavior on color { ColorAnimation { duration: 120 } }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                iconSize: 17
                customColor: playArea.containsMouse ? Colors.primaryText : Colors.primaryContainerText
                Behavior on customColor { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: ServiceMusic.togglePlaying()
            }
        }

        // Next
        Rectangle {
            implicitWidth: 24; implicitHeight: 24; radius: 7
            color: nextArea.containsMouse ? Qt.alpha(Colors.primary, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "skip_next"; iconSize: 16
                customColor: nextArea.containsMouse ? Colors.primary : Colors.outline
                Behavior on customColor { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: ServiceMusic.next()
            }
        }
    }
}
