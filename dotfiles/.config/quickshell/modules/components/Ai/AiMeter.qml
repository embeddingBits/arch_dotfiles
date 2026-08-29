pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.utils

Item {
    id: root

    property var levels: []
    property color barColor: Colors.primary

    readonly property real gap: 3
    readonly property int count: levels.length

    implicitHeight: 16

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.count

            delegate: Rectangle {
                required property int index

                readonly property real level: Math.max(0, Math.min(1, root.levels[index] ?? 0))

                width: Math.max(2, (root.width - (root.count - 1) * root.gap) / root.count)
                height: Math.max(2, level * root.height)
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: root.barColor
                opacity: 0.45 + level * 0.55

                Behavior on height {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
