import QtQuick
import "../../config/Theme.qml" as Theme

Rectangle {
    property int sepHeight: 18

    width: 1
    height: sepHeight
    color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
    opacity: 0.6
}
