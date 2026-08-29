import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

// Translucent pill used for the lock screen's corner status readouts.
// Sits directly on the blurred wallpaper, so it carries its own scrim
// and hairline border rather than relying on a card behind it.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string iconColor: Colors.surfaceText
    property string labelColor: Colors.surfaceText
    property real iconSize: 16

    implicitWidth: chipRow.implicitWidth + 26
    implicitHeight: 34
    radius: height / 2

    color: Qt.alpha(Colors.surfaceContainer, 0.55)
    border.width: 1
    border.color: Qt.alpha(Colors.outlineVariant, 0.35)

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: 7

        MaterialIconSymbol {
            content: root.icon
            iconSize: root.iconSize
            customColor: root.iconColor
            visible: root.icon !== ""
        }

        CustomText {
            content: root.label
            size: 12
            weight: 600
            customColor: root.labelColor
            visible: root.label !== ""
        }
    }
}
