pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root

    property string role: "assistant"
    property string text: ""
    property var blocks: []
    property var offsets: []

    property int revealChars: -1

    property bool typing: false
    property bool loading: false
    property bool animateIn: true
    property string status: ""

    readonly property bool isUser: role === "user"
    readonly property bool isError: role === "error"

    readonly property real avatarLane: 32

    implicitHeight: (isUser ? userBubble.implicitHeight : botBubble.implicitHeight)
        + (isUser ? 0 : 4)

    Rectangle {
        visible: !root.isUser
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.top: parent.top
        anchors.topMargin: 2
        width: 24
        height: 24
        radius: 7
        color: root.isError ? Qt.alpha(Colors.error, 0.18) : Qt.alpha(Colors.primary, 0.18)

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: root.isError ? "error_outline" : "neurology"
            iconSize: 14
            customColor: root.isError ? Colors.error : Colors.primary
        }
    }

    Rectangle {
        id: userBubble
        visible: root.isUser
        anchors.right: parent.right
        anchors.top: parent.top

        width: Math.min(userText.implicitWidth + 28, root.width * 0.82)
        implicitHeight: userText.implicitHeight + 22
        height: implicitHeight
        topLeftRadius: 18
        topRightRadius: 4
        bottomLeftRadius: 18
        bottomRightRadius: 18
        color: Colors.primary

        opacity: 1
        Component.onCompleted: if (root.animateIn) {
            opacity = 0
            userFade.start()
        }
        NumberAnimation {
            id: userFade
            target: userBubble
            property: "opacity"
            from: 0; to: 1; duration: 250
            easing.type: Easing.OutQuad
        }

        CustomText {
            id: userText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            content: root.text
            size: 14
            weight: 400
            customColor: Colors.primaryText
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        id: botBubble
        visible: !root.isUser

        readonly property int pad: root.isError ? 12 : 0

        anchors.left: parent.left
        anchors.leftMargin: root.avatarLane
        anchors.top: parent.top
        anchors.topMargin: root.isError ? 2 : 0
        width: Math.max(60, root.width - root.avatarLane - 4)
        implicitHeight: botContent.implicitHeight + pad * 2
        height: implicitHeight
        topLeftRadius: 4
        topRightRadius: 18
        bottomLeftRadius: 18
        bottomRightRadius: 18
        color: root.isError ? Qt.alpha(Colors.error, 0.12) : "transparent"

        opacity: 1
        Component.onCompleted: if (root.animateIn) {
            opacity = 0
            botFade.start()
        }
        NumberAnimation {
            id: botFade
            target: botBubble
            property: "opacity"
            from: 0; to: 1; duration: 250
            easing.type: Easing.OutQuad
        }

        Column {
            id: botContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: botBubble.pad
            spacing: 8

            CustomText {
                width: botContent.width
                visible: root.isError
                content: root.text
                size: 13
                weight: 500
                customColor: Colors.error
                wrapMode: Text.Wrap
            }

            Rectangle {
                visible: root.loading
                width: 58
                height: 30
                radius: 15
                color: Colors.surfaceContainerHigh

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: 3

                        Rectangle {
                            required property int index
                            width: 7
                            height: 7
                            radius: 3.5
                            color: Colors.primary

                            SequentialAnimation on opacity {
                                running: root.loading
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 180 }
                                NumberAnimation { to: 0.15; duration: 500; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }

            CustomText {
                visible: root.loading && root.status !== ""
                width: botContent.width
                content: root.status
                size: 11
                weight: 400
                customColor: Colors.outline
                wrapMode: Text.Wrap
            }

            AiBlocks {
                id: blockView
                width: botContent.width
                visible: !root.isError && !root.loading
                blocks: root.blocks
                offsets: root.offsets
                revealChars: root.revealChars
                animateBlocks: root.animateIn
            }

            Rectangle {
                visible: root.typing
                width: 2
                height: 15
                radius: 1
                color: Colors.primary

                SequentialAnimation on opacity {
                    running: root.typing
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 420; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutSine }
                }
            }

            Item {
                width: botContent.width
                height: copyLabel.implicitHeight
                visible: !root.isError && !root.loading && root.revealChars < 0 && root.text !== ""

                CustomText {
                    id: copyLabel
                    property bool copied: false
                    anchors.right: parent.right
                    opacity: botHover.containsMouse || copied ? 1 : 0
                    content: copied ? "copied" : "copy"
                    size: 10
                    weight: 600
                    customColor: copied ? Colors.primary : Colors.outline

                    Behavior on opacity { NumberAnimation { duration: Appearance.duration.small } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.clipboardText = root.text
                            copyLabel.copied = true
                            copyReset.restart()
                        }
                    }

                    Timer {
                        id: copyReset
                        interval: 1400
                        onTriggered: copyLabel.copied = false
                    }
                }
            }
        }

        MouseArea {
            id: botHover
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }
}
