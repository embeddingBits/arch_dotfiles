pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root

    readonly property var viewed: ServiceAi.viewedConversation

    implicitHeight: viewed ? detailCol.implicitHeight : Math.max(80, listCol.implicitHeight)

    Flickable {
        id: listFlick
        anchors.fill: parent
        visible: !root.viewed
        contentHeight: listCol.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: CustomScrollBar {}

        Column {
            id: listCol
            width: listFlick.width
            spacing: 2

            CustomText {
                width: listCol.width
                visible: ServiceAi.conversations.length === 0
                content: "No past chats yet. Starting a new chat files the current one here."
                size: 14
                customColor: Colors.outline
                wrapMode: Text.Wrap
            }

            Repeater {
                model: ServiceAi.conversations

                delegate: Rectangle {
                    id: chatRow
                    required property var modelData
                    required property int index

                    width: listCol.width
                    height: rowCol.implicitHeight + 18
                    radius: 12
                    color: rowArea.containsMouse ? Qt.alpha(Colors.primary, 0.10) : "transparent"

                    Column {
                        id: rowCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 3

                        CustomText {
                            width: rowCol.width
                            content: ServiceAi.conversationTitle(chatRow.modelData)
                            size: 14
                            weight: 500
                            customColor: Colors.surfaceText
                            elide: Text.ElideRight
                        }

                        CustomText {
                            readonly property int turnCount: (chatRow.modelData?.turns ?? []).length
                            content: {
                                const d = new Date(chatRow.modelData?.at ?? 0)
                                const today = new Date()
                                const time = String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0")
                                const when = d.toDateString() === today.toDateString()
                                    ? time
                                    : d.toLocaleDateString(Qt.locale(), "d MMM") + "  " + time

                                return when + "  ·  " + turnCount + (turnCount === 1 ? " message" : " messages")
                            }
                            size: 10
                            weight: 500
                            customColor: Colors.outline
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ServiceAi.viewConversation(chatRow.index)
                    }
                }
            }
        }
    }

    Flickable {
        id: detailFlick
        anchors.fill: parent
        visible: !!root.viewed
        contentHeight: detailCol.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: CustomScrollBar {}

        Connections {
            target: ServiceAi
            function onHistoryIndexChanged() { detailFlick.contentY = 0 }
        }

        Column {
            id: detailCol
            width: detailFlick.width
            spacing: 18

            Repeater {
                model: root.viewed ? (root.viewed.turns ?? []) : []

                delegate: AiTurn {
                    required property var modelData

                    width: detailCol.width
                    role: modelData?.role ?? "assistant"
                    text: modelData?.text ?? ""
                    blocks: modelData?.blocks ?? []
                    revealChars: -1
                }
            }
        }
    }
}
