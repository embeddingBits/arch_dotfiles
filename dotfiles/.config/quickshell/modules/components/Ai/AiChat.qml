pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

FocusScope {
    id: root

    signal closed()

    property real maxHeight: 700

    property bool elevated: true

    implicitWidth: 760
    implicitHeight: Math.min(root.maxHeight, chrome.implicitHeight + 36)

    Behavior on implicitHeight {
        NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad }
    }

    function takeFocus() {
        if (ServiceAi.historyOpen) root.forceActiveFocus()
        else composer.focusField()
    }

    Keys.onEscapePressed: {

        if (ServiceAi.historyOpen) ServiceAi.historyBack()
        else root.closed()
    }

    AiLevels {
        id: levels
        active: ServiceAi.recording
        bars: 48
    }

    Repeater {
        model: root.elevated ? 4 : 0
        Rectangle {
            required property int index
            anchors.centerIn: card
            width: card.width + (index + 1) * 3
            height: card.height + (index + 1) * 3
            radius: card.radius + (index + 1) * 2
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colors.shadow, 0.10 - index * 0.022)
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 28
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.alpha(Colors.outlineVariant, 0.45)

        ColumnLayout {
            id: chrome
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                MaterialShapes.ShapeCanvas {
                    id: badge
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    roundedPolygon: MaterialShapeFn.getCookie6Sided()
                    color: root.statusColor

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "neurology"
                        iconSize: 18
                        customColor: Colors.primaryText
                    }

                    SequentialAnimation on opacity {
                        running: root.pulsing
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.45; duration: 620; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutSine }
                    }

                    Connections {
                        target: root
                        function onPulsingChanged() {
                            if (!root.pulsing) badge.opacity = 1
                        }
                    }
                }

                ColumnLayout {
                    spacing: 0

                    CustomText {
                        content: "Claude"
                        size: 15
                        weight: 700
                        customColor: Colors.surfaceText
                    }

                    CustomText {
                        content: root.statusLabel
                        size: 11
                        weight: 500
                        customColor: root.statusColor
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: !ServiceAi.historyOpen
                    implicitHeight: 22
                    implicitWidth: bridgeRow.implicitWidth + 16
                    radius: 11
                    color: ServiceAi.bridgeConnected
                        ? Qt.alpha(Colors.primary, 0.13)
                        : Qt.alpha(Colors.error, 0.13)

                    RowLayout {
                        id: bridgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIconSymbol {
                            content: ServiceAi.bridgeConnected ? "cloud_done" : "cloud_off"
                            iconSize: 12
                            customColor: ServiceAi.bridgeConnected ? Colors.primary : Colors.error
                        }

                        CustomText {
                            size: 10
                            weight: 600
                            customColor: ServiceAi.bridgeConnected ? Colors.primary : Colors.error
                            content: ServiceAi.bridgeConnected ? "claude.ai" : "Zen offline"
                        }
                    }
                }

                HeaderAction {
                    content: "add_comment"
                    tip: "New chat"
                    visible: !ServiceAi.historyOpen && ServiceAi.turns.length > 0
                    onTriggered: {
                        ServiceAi.newChat()
                        composer.focusField()
                    }
                }

                HeaderAction {
                    content: ServiceAi.historyOpen ? "arrow_back" : "history"
                    tip: ServiceAi.historyOpen ? "Back" : "Past chats"
                    visible: ServiceAi.historyOpen || ServiceAi.conversations.length > 0
                    onTriggered: {
                        if (ServiceAi.historyOpen) ServiceAi.historyBack()
                        else ServiceAi.openHistory()
                    }
                }

                HeaderAction {
                    content: "close"
                    tip: "Hide"
                    onTriggered: root.closed()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: ServiceAi.historyOpen
                    ? historyView.implicitHeight
                    : transcript.implicitHeight

                AiTranscript {
                    id: transcript
                    anchors.fill: parent
                    visible: !ServiceAi.historyOpen
                }

                AiHistory {
                    id: historyView
                    anchors.fill: parent
                    visible: ServiceAi.historyOpen
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: ServiceAi.notice !== "" && !ServiceAi.historyOpen
                implicitHeight: noticeRow.implicitHeight + 20
                radius: 12
                color: Qt.alpha(Colors.error, 0.12)

                RowLayout {
                    id: noticeRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    spacing: 8

                    MaterialIconSymbol {
                        Layout.alignment: Qt.AlignTop
                        content: "error_outline"
                        iconSize: 16
                        customColor: Colors.error
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: ServiceAi.notice
                        size: 11
                        weight: 500
                        customColor: Colors.error
                        wrapMode: Text.Wrap
                    }

                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 6
                        color: Qt.alpha(Colors.error, dismissArea.containsMouse ? 0.32 : 0.2)

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "close"
                            iconSize: 13
                            customColor: Colors.error
                        }

                        MouseArea {
                            id: dismissArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ServiceAi.notice = ""
                        }
                    }
                }
            }

            AiComposer {
                id: composer
                Layout.fillWidth: true

                visible: !ServiceAi.historyOpen
                levels: levels.levels

                onSubmitted: prompt => ServiceAi.send(prompt)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                CustomText {
                    size: 11
                    weight: 500
                    customColor: Qt.alpha(Colors.outline, 0.85)
                    content: {
                        if (ServiceAi.historyOpen)
                            return ServiceAi.historyIndex >= 0
                                ? "Read-only  ·  Esc to go back"
                                : "Pick a chat to read it  ·  Esc to go back"
                        switch (ServiceAi.state) {
                        case "recording":    return "Ctrl+Space to stop  ·  keep typing if you like"
                        case "transcribing": return "Transcribing the recording…"
                        case "sending":
                        case "streaming":    return "Super+D to hide  ·  the reply keeps going in Zen"

                        default:             return "Shift+Enter for a new line  ·  Ctrl+Space to dictate"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                CustomText {
                    id: copyChat
                    property bool copied: false
                    visible: !ServiceAi.historyOpen && ServiceAi.turns.length > 0
                    content: copied ? "copied" : "copy chat"
                    size: 11
                    weight: 600
                    customColor: copied ? Colors.primary : Colors.outline

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ServiceAi.copyConversation()
                            copyChat.copied = true
                            copyChatReset.restart()
                        }
                    }

                    Timer {
                        id: copyChatReset
                        interval: 1400
                        onTriggered: copyChat.copied = false
                    }
                }

                CustomText {
                    visible: ServiceAi.historyOpen
                        && ServiceAi.historyIndex < 0
                        && ServiceAi.conversations.length > 0
                    content: "clear all"
                    size: 11
                    weight: 600
                    customColor: clearArea.containsMouse ? Colors.error : Colors.outline

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ServiceAi.clearHistory()
                    }
                }
            }
        }
    }

    readonly property bool pulsing: ServiceAi.recording
        || ServiceAi.transcribing
        || ServiceAi.state === "sending"
        || ServiceAi.state === "streaming"

    readonly property string statusLabel: {
        if (ServiceAi.historyOpen)
            return ServiceAi.historyIndex >= 0 ? "Earlier chat" : "Past chats"
        switch (ServiceAi.state) {
        case "recording":    return "Listening"
        case "transcribing": return "Transcribing"
        case "sending":      return "Sending"
        case "streaming":    return "Replying…"
        case "answer":       return "Replying…"
        default:             return ServiceAi.bridgeConnected ? "Ready" : "Not connected"
        }
    }

    readonly property string statusColor: {
        if (ServiceAi.transcribing || ServiceAi.state === "sending" || ServiceAi.state === "streaming")
            return Colors.tertiary
        return Colors.primary
    }

    component HeaderAction: MaterialIconSymbol {
        id: action

        property string tip: ""
        signal triggered()

        iconSize: 17
        customColor: hit.containsMouse ? Colors.surfaceText : Colors.outline

        MouseArea {
            id: hit
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }

        CustomToolTip {
            content: action.tip
            visible: hit.containsMouse && action.tip !== ""
        }
    }
}
