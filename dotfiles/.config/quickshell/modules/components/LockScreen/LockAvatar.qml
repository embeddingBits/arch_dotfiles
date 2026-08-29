import QtQuick
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

// Profile picture with a state ring. The ring becomes an indeterminate
// spinner while PAM is checking, and flashes error on rejection.
Item {
    id: root

    required property LockContext context

    readonly property real avatarSize: 96
    readonly property real ringInset: 7

    implicitWidth: avatarSize + ringInset * 2
    implicitHeight: avatarSize + ringInset * 2

    // Idle / failure ring
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.context.showFailure
            ? Colors.error
            : Qt.alpha(Colors.outlineVariant, 0.5)
        visible: !root.context.unlockInProgress
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    // Working ring
    CustomCircularLoader {
        anchors.centerIn: parent
        size: root.implicitWidth
        trackWidth: 3
        value: -1
        highlightColor: Colors.primary
        trackColor: Qt.alpha(Colors.outlineVariant, 0.4)
        visible: root.context.unlockInProgress
    }

    ClippingWrapperRectangle {
        anchors.centerIn: parent
        width: root.avatarSize
        height: root.avatarSize
        radius: width / 2
        color: Colors.primaryContainer

        Image {
            anchors.fill: parent
            source: SettingsConfig.general.profile
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.avatarSize, root.avatarSize)
        }
    }
}
