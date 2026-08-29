import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

// Scratchpad you can type straight onto the wallpaper. Text lives in
// SettingsConfig.widgets.stickyNoteText rather than a new service — it's a
// single string and that store is already debounced to disk.
WidgetHost {
    id: root
    configKey: "stickyNote"
    tile: WidgetSizes.small
    defaultPos: Qt.point(620, 660)

    readonly property string savedText: SettingsConfig.widgets.stickyNoteText ?? ""

    // Only push external changes in when the user isn't mid-edit, otherwise the
    // save round-trip would fight the cursor.
    onSavedTextChanged: if (!area.activeFocus && area.text !== savedText) area.text = savedText

    Component.onCompleted: {
        area.text = root.preview
            ? "Pick up keys\nCall the landlord\nrent — friday"
            : root.savedText
    }

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: {
            if (root.preview) return
            if (area.text === root.savedText) return
            SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, {
                stickyNoteText: area.text
            })
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 6

            MaterialIconSymbol { content: "sticky_note_2"; iconSize: 15; customColor: Colors.primary }
            CustomText { content: "Note"; size: 13; customColor: Colors.primary }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol {
                content: "close"
                iconSize: 14
                customColor: Colors.outline
                visible: area.text.length > 0 && !root.preview
                opacity: clearArea.containsMouse ? 1 : 0.6

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { area.text = ""; saveTimer.restart() }
                }
            }
        }

        ScrollView {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            anchors.bottomMargin: 12
            clip: true

            TextArea {
                id: area
                readOnly: root.preview
                background: null
                wrapMode: TextArea.Wrap
                font.pixelSize: 13
                font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                color: Colors.surfaceText
                selectionColor: Qt.alpha(Colors.primary, 0.35)
                selectedTextColor: Colors.surfaceText
                placeholderText: "Jot something down…"
                placeholderTextColor: Colors.outline

                onTextChanged: if (!root.preview) saveTimer.restart()

                // Tells the layer surface to hold the keyboard only while this
                // field is being edited; also commits without waiting out the timer.
                onActiveFocusChanged: {
                    if (!root.preview) GlobalStates.widgetTextFocus = activeFocus
                    if (!activeFocus) saveTimer.restart()
                }

                Keys.onEscapePressed: focus = false
            }
        }
    }
}
