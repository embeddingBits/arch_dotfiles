import QtQuick
import Quickshell

PanelWindow {
    id: root

    required property bool anyPopupOpen
    signal dismiss

    visible: root.anyPopupOpen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
    }
}
