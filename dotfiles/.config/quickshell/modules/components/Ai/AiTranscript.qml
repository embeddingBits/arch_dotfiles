pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item {
    id: root

    implicitHeight: col.implicitHeight

    property real livePeak: 0

    Connections {
        target: ServiceAi

        function onStateChanged() {
            if (ServiceAi.state === "sending") root.livePeak = 0

            if (ServiceAi.state === "sending" || ServiceAi.state === "streaming") {
                flick.pinned = true
                Qt.callLater(flick.toEnd)
            }
        }

        function onScrollToBottom() {
            flick.pinned = true
            Qt.callLater(flick.toEnd)
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, col.y + col.implicitHeight)
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: CustomScrollBar {}

        property bool pinned: true

        function atEnd() {
            return contentY >= contentHeight - height - 12
        }

        function toEnd() {
            contentY = Math.max(0, contentHeight - height)
        }

        function pin() {
            if (pinned) Qt.callLater(toEnd)
        }

        onContentHeightChanged: pin()
        onHeightChanged: pin()
        onMovementEnded: pinned = atEnd()
        onFlickEnded: pinned = atEnd()

        Column {
            id: col
            width: flick.width
            spacing: 10
            bottomPadding: 14

            y: Math.max(0, flick.height - implicitHeight)

            Item {
                width: col.width
                height: visible ? 190 : 0
                visible: ServiceAi.turns.length === 0 && !ServiceAi.replying

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    MaterialShapes.ShapeCanvas {
                        anchors.horizontalCenter: parent.horizontalCenter

                        width: 70
                        height: 70
                        roundedPolygon: MaterialShapeFn.getCookie6Sided()
                        color: Qt.alpha(Colors.primary, 0.14)

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "neurology"
                            iconSize: 42
                            customColor: Colors.primary
                        }
                    }

                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        content: "How can I help you?"
                        size: 16
                        weight: 700
                        customColor: Colors.surfaceText
                    }

                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        content: ServiceAi.bridgeConnected
                            ? "Continues whatever chat is open in Zen"
                            : "Open claude.ai in Zen to get started"
                        size: 11
                        customColor: Colors.outline
                    }
                }
            }

            ScriptModel {
                id: turnModel
                values: ServiceAi.turns
                objectProp: "seq"
            }

            Repeater {
                model: turnModel

                delegate: AiTurn {
                    required property var modelData

                    width: col.width
                    role: modelData?.role ?? "assistant"
                    text: modelData?.text ?? ""
                    blocks: modelData?.blocks ?? []
                    revealChars: -1
                    animateIn: (modelData?.seq ?? -1) !== ServiceAi.lastCommittedSeq
                }
            }

            AiTurn {
                width: col.width
                visible: ServiceAi.state === "sending"
                    || (ServiceAi.state === "streaming" && ServiceAi.responseBlocks.length === 0)
                role: "assistant"
                loading: true
                status: ServiceAi.thinkingStatus

                onVisibleChanged: if (visible) {
                    flick.pinned = true
                    Qt.callLater(flick.toEnd)
                }
            }

            AiTurn {
                id: live
                width: col.width
                visible: (ServiceAi.state === "streaming" || ServiceAi.state === "answer")
                         && ServiceAi.responseBlocks.length > 0

                role: "assistant"
                text: ServiceAi.response
                blocks: ServiceAi.responseBlocks
                offsets: ServiceAi.blockOffsets
                revealChars: ServiceAi.revealChars
                typing: visible

            }
        }
    }
}
