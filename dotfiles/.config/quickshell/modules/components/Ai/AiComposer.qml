pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

ColumnLayout {
    id: root

    property var levels: []

    readonly property bool recording: ServiceAi.recording
    readonly property bool transcribing: ServiceAi.transcribing
    readonly property bool empty: field.text.trim() === ""

    readonly property bool canSend: !empty && !ServiceAi.awaitingReply

    signal submitted(string body)

    spacing: 9

    Connections {
        target: ServiceAi

        function onDictationSeqChanged() {
            root.insertDictation(ServiceAi.dictated)

            if ((SettingsConfig.ai?.autoSend ?? false) && !root.empty)
                root.submit()
        }

        function onDraftSeqChanged() {
            root.clear()
            root.focusField()
        }

        function onStateChanged() {
            if (ServiceAi.state === "sending") root.clear()
        }
    }

    function focusField() {
        field.forceActiveFocus()
    }

    function clear() {
        field.text = ""
    }

    function insertDictation(chunk) {
        const body = String(chunk).trim()
        if (body === "")
            return

        const at = field.cursorPosition
        const before = field.text.slice(0, at)
        const after = field.text.slice(at)

        const lead = (before !== "" && !/\s$/.test(before)) ? " " : ""
        const tail = (after !== "" && !/^\s/.test(after)) ? " " : ""

        field.insert(at, lead + body + tail)
        field.cursorPosition = at + lead.length + body.length
        field.forceActiveFocus()
    }

    function submit() {
        root.submitted(field.text)
    }

    component FieldAction: Rectangle {
        id: act

        property string icon: ""
        property bool active: false
        property color accent: Colors.primary

        signal triggered()

        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 9
        color: act.active ? act.accent : Qt.alpha(Colors.outline, 0.22)

        Behavior on color { ColorAnimation { duration: 150 } }

        scale: area.pressed ? 0.85 : area.containsMouse ? 1.1 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: act.icon
            iconSize: 15
            customColor: act.active ? Colors.primaryText : Qt.alpha(Colors.outline, 0.75)
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: act.triggered()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 32
        radius: 22
        color: Colors.surfaceContainerHigh
        border.width: 1
        border.color: field.activeFocus
            ? Qt.alpha(Colors.primary, 0.5)
            : Qt.alpha(Colors.outlineVariant, 0.45)

        Behavior on border.color { ColorAnimation { duration: 150 } }

        CustomText {
            id: fontRef
            visible: false
            size: SettingsConfig.ai?.composerFontSize ?? 15
            weight: 400
            family: SettingsConfig.ai?.composerFont ?? "Adwaita Mono"
        }

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 10

            Flickable {
                id: scroll
                Layout.fillWidth: true

                implicitHeight: Math.min(170, Math.max(fontRef.font.pixelSize + 6, field.implicitHeight))
                contentHeight: field.implicitHeight
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: field
                    width: scroll.width
                    font: fontRef.font
                    color: Colors.surfaceText
                    selectionColor: Qt.alpha(Colors.primary, 0.35)
                    selectedTextColor: Colors.surfaceText
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    persistentSelection: true
                    renderType: Text.NativeRendering

                    onCursorRectangleChanged: {
                        if (cursorRectangle.y < scroll.contentY)
                            scroll.contentY = cursorRectangle.y
                        else if (cursorRectangle.y + cursorRectangle.height > scroll.contentY + scroll.height)
                            scroll.contentY = cursorRectangle.y + cursorRectangle.height - scroll.height
                    }

                    onTextChanged: if (ServiceAi.notice !== "") ServiceAi.notice = ""

                    Keys.onPressed: event => {

                        if (event.key === Qt.Key_Space && (event.modifiers & Qt.ControlModifier)) {
                            event.accepted = true
                            ServiceAi.toggleMic()
                        }
                    }

                    Keys.onReturnPressed: event => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            event.accepted = false
                            return
                        }
                        event.accepted = true
                        root.submit()
                    }

                    Keys.onEnterPressed: event => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            event.accepted = false
                            return
                        }
                        event.accepted = true
                        root.submit()
                    }

                    CustomText {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        visible: field.text === ""

                        content: root.recording ? "Listening — speak, or keep typing" : "Write a message…"
                        size: 16
                        weight: 400
                        customColor: Colors.outline
                    }
                }
            }

            AiMeter {
                Layout.fillWidth: true
                visible: root.recording
                levels: root.levels
                barColor: Colors.primary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: chipRow.implicitWidth + 14
                    radius: 11
                    color: root.recording
                        ? Qt.alpha(Colors.error, 0.13)
                        : Qt.alpha(Colors.primary, 0.13)

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIconSymbol {
                            content: root.recording ? "graphic_eq" : root.transcribing ? "hourglass_top" : "bolt"
                            iconSize: 11
                            customColor: root.recording ? Colors.error : Colors.primary
                        }

                        CustomText {
                            size: 10
                            weight: 600
                            customColor: root.recording ? Colors.error : Colors.primary
                            content: {
                                if (root.transcribing)
                                    return "Transcribing"
                                if (root.recording) {
                                    const t = Math.floor(ServiceAi.recordingMs / 1000)
                                    return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0")
                                }
                                return "Enter to send"
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                FieldAction {
                    icon: root.recording ? "stop" : "mic"
                    active: root.recording
                    accent: Colors.error
                    enabled: !root.transcribing
                    opacity: root.transcribing ? 0.45 : 1
                    onTriggered: ServiceAi.toggleMic()
                }

                FieldAction {
                    icon: "send"

                    active: root.canSend
                    enabled: root.canSend
                    onTriggered: root.submit()
                }
            }
        }
    }
}
