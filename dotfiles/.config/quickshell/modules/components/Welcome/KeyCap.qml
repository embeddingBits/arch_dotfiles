import QtQuick
import qs.modules.utils
import qs.modules.customComponents

Rectangle {
    id: root

    property string key: ""

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24
    radius: 7
    color: Colors.surfaceContainerHighest
    border.width: 1
    border.color: Qt.alpha(Colors.outlineVariant, 0.8)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        height: 2
        radius: 1
        color: Qt.alpha(Colors.outlineVariant, 0.7)
    }

    CustomText {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        content: root.key
        size: 11
        weight: 600
        customColor: Colors.surfaceText
    }
}
