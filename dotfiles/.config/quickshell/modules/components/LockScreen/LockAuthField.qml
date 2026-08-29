pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

// Centered password pill plus a reserved line beneath it for the failure
// message. The message lives outside the pill so it stays readable once the
// user has started typing and the placeholder is gone.
ColumnLayout {
    id: root

    required property LockContext context
    property alias input: passInput

    spacing: 8

    Rectangle {
        id: pill

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 460
        Layout.preferredHeight: 64
        radius: height / 2

        color: Qt.alpha(Colors.surfaceContainer, 0.72)
        border.width: 2
        border.color: root.context.showFailure
            ? Colors.error
            : passInput.activeFocus
                ? Colors.primary
                : Qt.alpha(Colors.outlineVariant, 0.45)

        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Shake on a rejected password. Translate rather than x so the layout
        // keeps ownership of the pill's real position.
        transform: Translate { id: shakeOffset }

        SequentialAnimation {
            id: shakeAnim
            loops: 2
            NumberAnimation { target: shakeOffset; property: "x"; to:  10; duration: 55; easing.type: Easing.OutSine }
            NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 55; easing.type: Easing.OutSine }
            NumberAnimation { target: shakeOffset; property: "x"; to:   0; duration: 55; easing.type: Easing.OutSine }
        }

        Connections {
            target: root.context
            function onFailed() { shakeAnim.restart() }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 8
            spacing: 12

            MaterialIconSymbol {
                content: root.context.unlockInProgress ? "lock_open" : "lock"
                iconSize: 22
                customColor: root.context.showFailure
                    ? Colors.error
                    : root.context.unlockInProgress ? Colors.primary : Colors.outline
            }

            CustomShapeInput {
                id: passInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "Enter password"
                placeholderColor: Colors.outline
                enabled: !root.context.unlockInProgress

                onTextChanged: root.context.currentText = text
                onAccepted:    root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        passInput.text = root.context.currentText
                    }
                }
            }

            // Caps lock warning — slides in from the trailing edge
            Rectangle {
                Layout.preferredWidth: root.context.capsLockOn ? capsRow.implicitWidth + 18 : 0
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                clip: true
                radius: 14
                color: Qt.alpha(Colors.tertiary, 0.2)
                opacity: root.context.capsLockOn ? 1 : 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                RowLayout {
                    id: capsRow
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialIconSymbol {
                        content: "keyboard_capslock"
                        iconSize: 15
                        customColor: Colors.tertiary
                    }
                    CustomText {
                        content: "Caps"
                        size: 11; weight: 700
                        customColor: Colors.tertiary
                    }
                }
            }

            // Submit — appears once there is something to submit, and turns
            // into a spinner while PAM is thinking.
            Rectangle {
                id: submit
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                radius: height / 2
                color: Colors.primary

                opacity: root.context.currentText.length > 0 ? 1 : 0
                scale: root.context.currentText.length > 0 ? 1 : 0.7
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "arrow_forward"
                    iconSize: 22
                    customColor: Colors.primaryText
                    visible: !root.context.unlockInProgress
                }

                CustomCircularLoader {
                    anchors.centerIn: parent
                    size: 28
                    trackWidth: 3
                    value: -1
                    highlightColor: Colors.primaryText
                    trackColor: Qt.alpha(Colors.primaryText, 0.25)
                    visible: root.context.unlockInProgress
                }

                CustomMouseArea {
                    radius: submit.radius
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.context.unlockInProgress
                    onClicked: root.context.tryUnlock()
                }
            }
        }
    }

    // Failure line. Height is reserved so the stack never jumps.
    CustomText {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 18
        content: root.context.failedAttempts > 1
            ? "Wrong password — attempt " + root.context.failedAttempts
            : "Wrong password — try again"
        size: 12
        weight: 600
        customColor: Colors.error
        opacity: root.context.showFailure ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
