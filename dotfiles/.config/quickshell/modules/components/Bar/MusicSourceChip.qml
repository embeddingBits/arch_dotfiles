import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Which player the panel is actually controlling. Worth the 20px: with several
// MPRIS clients alive at once, the transport buttons are otherwise acting on an
// invisible choice.
Rectangle {
    id: root

    readonly property string identity: ServiceMusic.activeTrack?.identity ?? ""

    implicitWidth: chip.implicitWidth + 16
    implicitHeight: 20
    radius: 10
    color: Colors.surfaceContainerHigh
    visible: root.identity !== ""

    RowLayout {
        id: chip
        anchors.centerIn: parent
        spacing: 5

        Rectangle {
            Layout.preferredWidth: 5
            Layout.preferredHeight: 5
            radius: 2.5
            color: ServiceMusic.isPlaying ? Colors.primary : Colors.outline
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        CustomText {
            content: root.identity
            size: 10
            weight: 600
            customColor: Colors.outline
        }
    }
}
