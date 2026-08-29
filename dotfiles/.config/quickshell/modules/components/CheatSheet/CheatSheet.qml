import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

// Full-screen keybinding cheat sheet.
//
//     hl.bind(mainMod .. " + slash", hl.dsp.global("quickshell:cheatsheet"))
//
// Typing filters immediately — there is no text field, because the overlay
// holds the keyboard and the whole window is the input.
Scope {
    id: scope

    GlobalShortcut {
        name: "cheatsheet"
        description: "Toggle the keybinding cheat sheet"
        onPressed: GlobalStates.cheatSheetOpen = !GlobalStates.cheatSheetOpen
    }

    Loader {
        active: GlobalStates.cheatSheetOpen
        visible: active

        sourceComponent: PanelWindow {
            id: win
            visible: true
            color: "transparent"
            anchors { top: true; left: true; right: true; bottom: true }

            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property var visibleGroups: ServiceKeybinds.groups

            // Distributes groups across columns by filling whichever column is
            // currently shortest. A plain Flow sizes each row to its tallest
            // item, so a 24-row group beside a 4-row group leaves a hole the
            // height of the difference.
            function columnise(groups, n) {
                var cols = [], heights = []
                for (var i = 0; i < n; i++) { cols.push([]); heights.push(0) }
                for (var g = 0; g < groups.length; g++) {
                    var min = 0
                    for (var c = 1; c < n; c++)
                        if (heights[c] < heights[min]) min = c
                    cols[min].push(groups[g])
                    // Header plus rows plus the gap after the group
                    heights[min] += groups[g].binds.length + 3
                }
                return cols
            }

            // Scrim — click anywhere outside the card to dismiss
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.surface, 0.78)
                opacity: 0
                NumberAnimation on opacity { from: 0; to: 1; duration: 160; running: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.cheatSheetOpen = false
                }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(parent.width - 100, 1240)
                height: Math.min(parent.height - 100, 860)
                radius: 28
                color: Colors.surface

                opacity: 0
                scale: 0.97
                NumberAnimation on opacity { from: 0; to: 1; duration: 200; easing.type: Easing.OutQuad; running: true }
                NumberAnimation on scale   { from: 0.97; to: 1; duration: 220; easing.type: Easing.OutCubic; running: true }

                // Swallow clicks so they don't reach the dismiss scrim
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 0

                    // ── Header ────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            implicitWidth: 40; implicitHeight: 40
                            radius: 13
                            color: Colors.primaryContainer

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "keyboard"
                                iconSize: 21
                                customColor: Colors.primaryContainerText
                            }
                        }

                        ColumnLayout {
                            spacing: -2
                            CustomText { content: "Keybindings"; size: 19; weight: 700 }
                            CustomText {
                                content: ServiceKeybinds.bindCount + " shortcuts"
                                size: 12
                                customColor: Colors.outline
                            }
                        }

                        Item { Layout.fillWidth: true }

                        KeyCap { text: "ESC" }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        implicitHeight: 1
                        color: Colors.outlineVariant
                        opacity: 0.35
                    }

                    // ── Columns ───────────────────────────────────────────
                    Flickable {
                        id: flick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 18
                        contentWidth: width
                        contentHeight: colRow.implicitHeight
                        clip: true
                        visible: win.visibleGroups.length > 0

                        RowLayout {
                            id: colRow
                            width: flick.width
                            spacing: 30

                            readonly property int columns:
                                Math.max(1, Math.min(4, Math.floor(flick.width / 300)))

                            Repeater {
                                model: win.columnise(win.visibleGroups, colRow.columns)

                                delegate: ColumnLayout {
                                    id: colDelegate
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 0

                                    Repeater {
                                        model: colDelegate.modelData

                                        delegate: ColumnLayout {
                                            id: groupDelegate
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.bottomMargin: 22
                                            spacing: 7

                                            // Group heading
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                CustomText {
                                                    content: groupDelegate.modelData.name.toUpperCase()
                                                    size: 10
                                                    weight: 700
                                                    customColor: Colors.primary
                                                    font.letterSpacing: 1.5
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    implicitHeight: 1
                                                    color: Colors.primary
                                                    opacity: 0.18
                                                }
                                            }

                                            Repeater {
                                                model: groupDelegate.modelData.binds

                                                delegate: RowLayout {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    spacing: 10

                                                    // Each modifier gets its own cap — one
                                                    // long "SUPER + SHIFT + Q" pill is a
                                                    // sentence; three caps are a picture.
                                                    Row {
                                                        Layout.alignment: Qt.AlignTop
                                                        spacing: 3

                                                        Repeater {
                                                            model: String(modelData.shortcut).split(" + ")

                                                            delegate: KeyCap {
                                                                required property string modelData
                                                                text: modelData
                                                            }
                                                        }
                                                    }

                                                    CustomText {
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        content: modelData.description
                                                        size: 12
                                                        customColor: Colors.outline
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Empty state ───────────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: win.visibleGroups.length === 0
                        spacing: 10

                        Item { Layout.fillHeight: true }

                        MaterialIconSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            content: "keyboard_off"
                            iconSize: 40
                            customColor: Colors.outlineVariant
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            content: "No keybindings found"
                            size: 14
                            customColor: Colors.outline
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            content: ServiceKeybinds.path
                            size: 11
                            customColor: Colors.outlineVariant
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // The overlay holds the keyboard, so typing filters and there is no
            // field to click into first.
            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.cheatSheetOpen = false
                        event.accepted = true
                    }
                }
            }
        }
    }

    // ── Key cap ───────────────────────────────────────────────────────────
    component KeyCap: Rectangle {
        id: cap
        property string text: ""

        // XF86 prefixes eat half a column and say nothing — every reader knows
        // an "AudioRaiseVolume" key is the media key.
        readonly property string label: cap.text.replace(/^XF86/, "")

        implicitWidth: Math.max(26, capText.implicitWidth + 14)
        implicitHeight: 24
        radius: 7
        color: Colors.surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colors.outlineVariant, 0.55)

        CustomText {
            id: capText
            anchors.centerIn: parent
            content: cap.label
            size: 11
            weight: 600
            customColor: Colors.surfaceText
        }
    }
}
