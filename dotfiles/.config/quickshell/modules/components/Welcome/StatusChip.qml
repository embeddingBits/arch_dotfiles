import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Rectangle {
    id: root

    property string label: ""
    property int status: 0

    readonly property color tone: root.status === 1 ? Colors.primary
                                : root.status === 2 ? Colors.error
                                                   : Colors.outline

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 30
    radius: 15
    color: root.status === 2 ? Qt.alpha(Colors.error, 0.12) : Colors.surfaceContainerHigh

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MaterialIconSymbol {
            content: root.status === 1 ? "check" : root.status === 2 ? "close" : "pending"
            iconSize: 15
            customColor: root.tone
        }

        CustomText {
            content: root.label
            size: 12
            customColor: root.status === 2 ? Colors.error : Colors.surfaceText
        }
    }
}
