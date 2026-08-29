pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.utils
import qs.modules.customComponents

// Sleep / restart / shutdown, bottom-right.
// Two-stage: the first click expands the button into a labelled confirm pill,
// a second click within 4s runs the command. Anything else collapses it.
Item {
    id: root

    property int confirmIndex: -1

    readonly property var actions: [
        { icon: "bedtime",             label: "Sleep",     cmd: ["systemctl", "suspend"]  },
        { icon: "restart_alt",         label: "Restart",   cmd: ["systemctl", "reboot"]   },
        { icon: "power_settings_new",  label: "Shut Down", cmd: ["systemctl", "poweroff"] }
    ]

    implicitWidth: row.implicitWidth
    implicitHeight: 44

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: root.confirmIndex = -1
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: root.actions

            delegate: Rectangle {
                id: btn
                required property int index
                required property var modelData

                readonly property bool confirming: root.confirmIndex === btn.index

                Layout.preferredWidth: btn.confirming ? 44 + label.implicitWidth + 10 : 44
                Layout.fillHeight: true
                radius: height / 2

                color: btn.confirming
                    ? Colors.error
                    : Qt.alpha(Colors.surfaceContainer, 0.55)
                border.width: 1
                border.color: btn.confirming
                    ? "transparent"
                    : Qt.alpha(Colors.outlineVariant, 0.35)

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 180 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 8

                    MaterialIconSymbol {
                        content: btn.modelData.icon
                        iconSize: 19
                        customColor: btn.confirming ? Colors.errorText : Colors.surfaceText
                    }

                    CustomText {
                        id: label
                        content: btn.modelData.label + "?"
                        size: 12
                        weight: 700
                        customColor: Colors.errorText
                        visible: btn.confirming
                    }
                }

                CustomMouseArea {
                    radius: btn.radius
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (btn.confirming) {
                            confirmTimer.stop()
                            root.confirmIndex = -1
                            Quickshell.execDetached(btn.modelData.cmd)
                        } else {
                            root.confirmIndex = btn.index
                            confirmTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
