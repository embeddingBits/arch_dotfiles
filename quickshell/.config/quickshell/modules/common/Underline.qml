import QtQuick
import "../../config/Theme.qml" as Theme

Rectangle {
    property color underlineColor: Theme.underlineClock
    property bool highlighted: false

    height: highlighted ? 2.5 : 2
    radius: 1
    color: underlineColor
    opacity: highlighted ? 1.0 : 0.92

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
}
