import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

// Month calendar built for the dashboard's narrow column, rather than the
// 400x400 popup the bar's centre slot uses. Cells are sized off the available
// width so the grid stays square at any dashboard width, and holidays are a dot
// under the number instead of a colour change — at this size a recoloured digit
// reads as "selected", which is what today already means.
Rectangle{
    id: root
    property bool compact: false

    implicitHeight: content.implicitHeight + (root.compact ? 18 : 26)
    radius: 20
    color: Colors.surfaceContainer

    property int viewYear:  new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property var grid: {
        ServiceClock.holidaysLoaded          // repaint once holidays arrive
        return ServiceClock.generateCalendarGrid(root.viewYear, root.viewMonth)
    }

    onViewYearChanged: ServiceClock.ensureHolidaysForYear(root.viewYear)
    Component.onCompleted: ServiceClock.ensureHolidaysForYear(root.viewYear)

    function step(delta) {
        var m = root.viewMonth + delta
        var y = root.viewYear
        if (m < 0)       { m = 11; y-- }
        else if (m > 11) { m = 0;  y++ }
        root.viewMonth = m
        root.viewYear = y
    }

    function isThisMonth() {
        const now = new Date()
        return root.viewYear === now.getFullYear() && root.viewMonth === now.getMonth()
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.compact ? 9 : 13
        spacing: root.compact ? 6 : 9

        // ── Month header ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            ColumnLayout {
                spacing: -2

                CustomText {
                    content: ServiceClock.getMonthName(root.viewMonth)
                    size: root.compact ? 14 : 16
                    weight: 700
                }

                CustomText {
                    content: root.viewYear
                    size: 11
                    customColor: Colors.outline
                }
            }

            Item { Layout.fillWidth: true }

            // Only offers a way back when you have actually navigated away
            Rectangle {
                implicitWidth: 26; implicitHeight: 26
                radius: 13
                color: "transparent"
                visible: !root.isThisMonth()

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "today"
                    iconSize: 15
                    customColor: Colors.primary
                }

                RippleEffect {
                    anchors.fill: parent
                    radius: 13
                    onClicked: {
                        const now = new Date()
                        root.viewYear = now.getFullYear()
                        root.viewMonth = now.getMonth()
                    }
                }
            }

            Rectangle {
                implicitWidth: 26; implicitHeight: 26
                radius: 13
                color: "transparent"

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "chevron_left"
                    iconSize: 17
                    customColor: Colors.outline
                }

                RippleEffect { anchors.fill: parent; radius: 13; onClicked: root.step(-1) }
            }

            Rectangle {
                implicitWidth: 26; implicitHeight: 26
                radius: 13
                color: "transparent"

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "chevron_right"
                    iconSize: 17
                    customColor: Colors.outline
                }

                RippleEffect { anchors.fill: parent; radius: 13; onClicked: root.step(1) }
            }
        }

        // ── Weekday initials ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                delegate: CustomText {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    content: modelData
                    size: 10
                    weight: 600
                    // Weekend initials sit back so the working week reads first
                    customColor: (index === 0 || index === 6) ? Colors.primary : Colors.outline
                }
            }
        }

        // ── Day grid ──────────────────────────────────────────────────
        GridLayout {
            id: dayGrid
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 1
            columnSpacing: 0

            readonly property real cell: width / 7

            Repeater {
                model: root.grid

                delegate: Item {
                    id: dayCell
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: dayGrid.cell

                    readonly property bool today: modelData.isToday && modelData.isCurrentMonth
                    readonly property bool outside: !modelData.isCurrentMonth

                    // Today's marker — the only filled shape in the grid
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(dayGrid.cell - 4, 28)
                        height: width
                        radius: width / 2
                        color: Colors.primary
                        visible: dayCell.today
                    }

                    CustomText {
                        anchors.centerIn: parent
                        content: dayCell.modelData.day
                        size: root.compact ? 11 : 12
                        weight: dayCell.today ? 700 : 500
                        customColor: dayCell.today   ? Colors.primaryText
                                   : dayCell.outside ? Colors.outlineVariant
                                                     : Colors.surfaceText
                    }

                    // Holiday dot, tucked under the number
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: 3; height: 3; radius: 2
                        color: dayCell.today ? Colors.primaryText : Colors.tertiary
                        visible: dayCell.modelData.isHoliday && !dayCell.outside
                    }

                    CustomToolTip {
                        visible: hover.hovered && dayCell.modelData.isHoliday
                        content: (dayCell.modelData.info?.[0]?.name) ?? ""
                    }

                    HoverHandler { id: hover }
                }
            }
        }
    }
}
