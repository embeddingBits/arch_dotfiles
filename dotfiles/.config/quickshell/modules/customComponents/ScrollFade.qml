import QtQuick
import qs.modules.utils

Item {
    id: root

    property Flickable flickable: null
    property color color: Colors.surfaceContainer
    property real size: 22

    readonly property bool scrollable:
        !!flickable && flickable.contentHeight > flickable.height + 1
    readonly property bool showTop:    scrollable && !flickable.atYBeginning
    readonly property bool showBottom: scrollable && !flickable.atYEnd

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.size
        opacity: root.showTop ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.color }
            GradientStop { position: 1.0; color: Qt.alpha(root.color, 0) }
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.size
        opacity: root.showBottom ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(root.color, 0) }
            GradientStop { position: 1.0; color: root.color }
        }
    }
}
