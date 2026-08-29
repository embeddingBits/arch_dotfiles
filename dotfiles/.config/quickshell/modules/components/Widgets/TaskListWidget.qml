import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Desktop face for ServiceTodo, which until now had no UI anywhere.
//
// Ordering is derived locally rather than through ServiceTodo.filteredTodos —
// that property reads the singleton's shared filter/sort state, and a desktop
// widget shouldn't be mutating global state that other consumers may rely on.
WidgetHost {
    id: root
    configKey: "taskList"
    tile: WidgetSizes.large
    defaultPos: Qt.point(960, 200)

    // Collapsed by default: two tasks and a progress bar is enough at a glance.
    // Tapping the header opens the full list plus the quick-add field.
    property bool expanded: false
    readonly property int collapsedRows: 2

    implicitHeight: expanded ? WidgetSizes.large.height : WidgetSizes.strip.height
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // Collapsing while typing would strand the keyboard grab
    onExpandedChanged: if (!expanded && !preview) {
        addField.focus = false
        GlobalStates.widgetTextFocus = false
    }

    readonly property var sampleTodos: [
        { id: "s1", title: "Reply to the landlord",  completed: false, priority: 3, dueDate: "" },
        { id: "s2", title: "Book train tickets",     completed: false, priority: 2, dueDate: "" },
        { id: "s3", title: "Refill the water filter", completed: false, priority: 0, dueDate: "" },
        { id: "s4", title: "Send the invoice",       completed: true,  priority: 1, dueDate: "" }
    ]

    readonly property var source: root.preview ? root.sampleTodos : ServiceTodo.todos

    // Open first, overdue at the top, then soonest due, then priority.
    // Completed sink to the bottom.
    readonly property var rows: {
        const list = [...(root.source ?? [])]
        list.sort(function (a, b) {
            if (a.completed !== b.completed) return a.completed ? 1 : -1
            if (!root.preview) {
                const ao = ServiceTodo.isOverdue(a), bo = ServiceTodo.isOverdue(b)
                if (ao !== bo) return ao ? -1 : 1
            }
            const ad = a.dueDate || "9999-12-31", bd = b.dueDate || "9999-12-31"
            if (ad !== bd) return ad < bd ? -1 : 1
            if (a.priority !== b.priority) return b.priority - a.priority
            return 0
        })
        return list
    }

    readonly property var visibleRows: root.expanded ? root.rows
                                                     : root.rows.slice(0, root.collapsedRows)
    readonly property int hiddenCount: Math.max(0, root.rows.length - root.collapsedRows)

    readonly property int doneCount: root.rows.filter(function (t) { return t.completed }).length
    readonly property int overdueCount: root.preview ? 0 : (ServiceTodo.stats.overdue ?? 0)

    function priorityColor(p) {
        if (p >= 3) return Colors.error
        if (p === 2) return Colors.tertiary
        if (p === 1) return Colors.primary
        return Colors.outlineVariant
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // ── Header ────────────────────────────────────────────────────
        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            implicitHeight: headerRow.implicitHeight

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 7

                MaterialIconSymbol { content: "checklist"; iconSize: 16; customColor: Colors.primary }
                CustomText { content: "Tasks"; size: 13; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                CustomText {
                    content: root.doneCount + " / " + root.rows.length
                    size: 12
                    customColor: Colors.outline
                }

                MaterialIconSymbol {
                    content: "keyboard_arrow_down"
                    iconSize: 16
                    customColor: Colors.outline
                    rotation: root.expanded ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }

            // Header is the toggle — keeps row checkboxes from fighting it
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: !root.preview
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        // ── Progress ──────────────────────────────────────────────────
        Rectangle {
            id: bar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 10
            height: 4
            radius: 2
            color: Colors.surfaceContainerHighest

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (root.rows.length > 0 ? root.doneCount / root.rows.length : 0)
                radius: 2
                color: Colors.primary
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }
        }

        CustomText {
            id: overdueLine
            anchors.left: parent.left
            anchors.top: bar.bottom
            anchors.leftMargin: 16
            anchors.topMargin: 6
            visible: root.overdueCount > 0
            height: visible ? implicitHeight : 0
            content: root.overdueCount + " overdue"
            size: 11
            customColor: Colors.error
        }

        // ── List ──────────────────────────────────────────────────────
        ListView {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: overdueLine.bottom
            anchors.bottom: root.expanded ? addRow.top : moreLine.top
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 8
            anchors.bottomMargin: 6
            clip: true
            spacing: 1
            interactive: root.expanded
            boundsBehavior: Flickable.StopAtBounds
            model: root.visibleRows

            delegate: Item {
                id: row
                required property var modelData
                width: ListView.view.width
                height: 34

                readonly property bool overdue: !root.preview
                                             && !modelData.completed
                                             && ServiceTodo.isOverdue(modelData)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 9
                    color: rowHover.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: !root.preview
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 6
                    spacing: 9

                    // Tick — the whole circle is the hit target
                    Item {
                        implicitWidth: 20; implicitHeight: 20
                        Layout.alignment: Qt.AlignVCenter

                        CustomCheckbox {
                            anchors.centerIn: parent
                            checkState: row.modelData.completed
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: !root.preview
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ServiceTodo.toggleComplete(row.modelData.id)
                        }
                    }

                    // Priority stripe
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 3
                        implicitHeight: 15
                        radius: 1.5
                        visible: (row.modelData.priority ?? 0) > 0 && !row.modelData.completed
                        color: root.priorityColor(row.modelData.priority ?? 0)
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: row.modelData.title
                        size: 12
                        customColor: row.modelData.completed ? Colors.outline
                                   : row.overdue             ? Colors.error
                                                             : Colors.surfaceText
                        font.strikeout: row.modelData.completed
                        elide: Text.ElideRight
                    }

                    CustomText {
                        visible: (row.modelData.dueDate ?? "") !== "" && !row.modelData.completed
                        content: root.preview ? "" : ServiceTodo.dueDateLabel(row.modelData.dueDate ?? "")
                        size: 10
                        customColor: row.overdue ? Colors.error : Colors.outline
                    }

                    // Delete — only on hover, so the row stays quiet at rest
                    MaterialIconSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        content: "close"
                        iconSize: 14
                        customColor: Colors.outline
                        visible: rowHover.containsMouse && !root.preview

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ServiceTodo.removeTodo(row.modelData.id)
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.rows.length === 0

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: "task_alt"
                    iconSize: 26
                    customColor: Colors.outline
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: "Nothing to do"
                    size: 12
                    customColor: Colors.outline
                }
            }
        }

        // ── Collapsed footer ──────────────────────────────────────────
        CustomText {
            id: moreLine
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.bottomMargin: 12
            visible: !root.expanded
            height: visible ? implicitHeight : 0
            content: root.hiddenCount > 0 ? "+" + root.hiddenCount + " more"
                                          : (root.rows.length > 0 ? "" : "")
            size: 11
            customColor: Colors.outline
        }

        // ── Quick add ─────────────────────────────────────────────────
        Rectangle {
            id: addRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 12
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            height: 36
            radius: 12
            color: addField.activeFocus ? Colors.surfaceContainerHigh
                                        : Colors.surfaceContainerHighest
            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 11
                anchors.rightMargin: 9
                spacing: 7

                MaterialIconSymbol {
                    content: "add"
                    iconSize: 16
                    customColor: addField.text.length > 0 ? Colors.primary : Colors.outline
                }

                TextField {
                    id: addField
                    Layout.fillWidth: true
                    readOnly: root.preview
                    background: null
                    placeholderText: "Add a task…"
                    placeholderTextColor: Colors.outline
                    font.pixelSize: 12
                    font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                    color: Colors.surfaceText
                    verticalAlignment: TextInput.AlignVCenter

                    function submit() {
                        const t = text.trim()
                        if (t.length === 0 || root.preview) return
                        ServiceTodo.addTodo(t, "", 0, [], "")
                        text = ""
                    }

                    onAccepted: submit()
                    Keys.onEscapePressed: { text = ""; focus = false }

                    // Layer surface only holds the keyboard while this is focused
                    onActiveFocusChanged: if (!root.preview) GlobalStates.widgetTextFocus = activeFocus
                }
            }
        }
    }
}
