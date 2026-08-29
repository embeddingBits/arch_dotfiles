import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Item {
    id: root
    property int value: 0
    property int val
    property int inc: 10
    property int limit: 100

    onValueChanged: { if (val !== value) val = value }
    property color color: Colors.surfaceContainerHigh

    implicitWidth: 140
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Minus ─────────────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 38
                Layout.fillHeight: true

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "remove"
                    iconSize: minusMouse.containsMouse && root.val > 0 ? 20 : 17
                    color: root.val <= 0 ? Colors.outline
                         : minusMouse.pressed ? Colors.primary
                         : minusMouse.containsMouse ? Colors.inverseSurface
                         : Colors.surfaceVariantText

                    Behavior on iconSize { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color    { ColorAnimation  { duration: 120 } }
                }

                MouseArea {
                    id: minusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.val > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.val = Math.max(0, root.val - root.inc)
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: Colors.outline
                opacity: 0.35
            }

            // ── Value ─────────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                CustomText {
                    anchors.centerIn: parent
                    content: root.val
                    size: 14
                    weight: 600
                    color: Colors.inverseSurface
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: Colors.outline
                opacity: 0.35
            }

            // ── Plus ──────────────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 38
                Layout.fillHeight: true

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "add"
                    iconSize: plusMouse.containsMouse && root.val < root.limit ? 20 : 17
                    color: root.val >= root.limit ? Colors.outline
                         : plusMouse.pressed ? Colors.primary
                         : plusMouse.containsMouse ? Colors.inverseSurface
                         : Colors.surfaceVariantText

                    Behavior on iconSize { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color    { ColorAnimation  { duration: 120 } }
                }

                MouseArea {
                    id: plusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.val < root.limit
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.val = Math.min(root.limit, root.val + root.inc)
                }
            }
        }
    }
}
