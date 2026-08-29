import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root

    property var model: []
    property var iconFor: function(modelData, active) { return modelData.icon ?? "" }
    property var activeCheck: function(index) { return false }
    signal triggered(int index)

    property int pressedIndex: -1
    readonly property int count: root.model.length
    readonly property real gap: 7
    readonly property real growth: 0.28

    implicitHeight: 40

    readonly property real baseW:
        root.count > 0 ? (root.width - (root.count - 1) * root.gap) / root.count : 0

    RowLayout {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: btn
                required property var modelData
                required property int index

                readonly property bool active: root.activeCheck(btn.index)
                readonly property bool isPressed: root.pressedIndex === btn.index

                Layout.fillHeight: true
                Layout.preferredWidth: {
                    if (root.pressedIndex < 0 || root.count < 2) return root.baseW
                    if (btn.isPressed) return root.baseW * (1 + root.growth)
                    return root.baseW * (1 - root.growth / (root.count - 1))
                }
                Behavior on Layout.preferredWidth { SpatialAnim { speed: "fast" } }

                radius: btn.isPressed ? btn.height * 0.22
                      : btn.active ? btn.height * 0.32
                      : btn.height / 2
                Behavior on radius { SpatialAnim { speed: "fast" } }

                color: btn.active ? Colors.primary
                     : btnArea.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh
                Behavior on color { EffectsColorAnim { speed: "fast" } }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: root.iconFor(btn.modelData, btn.active)
                    iconSize: 19
                    customColor: btn.active ? Colors.primaryText : Colors.surfaceText
                    fill: btn.active ? 1 : 0
                    Behavior on fill { EffectsAnim { speed: "fast" } }
                    scale: btn.isPressed ? 0.86 : 1
                    Behavior on scale { SpatialAnim { speed: "fast" } }
                }

                MouseArea {
                    id: btnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: root.pressedIndex = btn.index
                    onReleased: root.pressedIndex = -1
                    onCanceled: root.pressedIndex = -1
                    onClicked: root.triggered(btn.index)
                }
            }
        }
    }
}
