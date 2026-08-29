import QtQuick
import qs.modules.utils
import qs.modules.services

// Floating music card, bottom-left. Collapses away entirely when no MPRIS
// player is present so the corner is empty rather than showing a dead card.
Rectangle {
    id: root

    visible: ServiceMusic.activePlayer !== null

    implicitWidth: 400
    implicitHeight: 96
    radius: 28

    color: Qt.alpha(Colors.surfaceContainer, 0.62)
    border.width: 1
    border.color: Qt.alpha(Colors.outlineVariant, 0.35)

    LockScreenMusicPlayer {
        anchors.fill: parent
    }
}
