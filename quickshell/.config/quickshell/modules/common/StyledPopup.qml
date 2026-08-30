import QtQuick
import Quickshell
import "../../config/Theme.qml" as Theme

PopupWindow {
    id: root

    // Expose content container so callers can anchor inside
    default property alias content: container.data

    property int popupPadding: 14

    color: "transparent"

    Rectangle {
        id: container
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
    }
}
