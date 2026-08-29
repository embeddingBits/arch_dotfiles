import QtQuick
import QtQuick.Controls
import qs.modules.utils

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    topPadding: 10
    bottomPadding: 10
    leftPadding: 10

    contentItem: Rectangle {
        implicitWidth: 8
        implicitHeight: root.visualSize + 50
        radius: width / 2
        color: Colors.tertiary
        
        opacity: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1.0) ? 0.5 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuad
            }
        }
    }
}
