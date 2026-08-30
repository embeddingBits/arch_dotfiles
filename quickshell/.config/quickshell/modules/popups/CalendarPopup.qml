import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config/Theme.qml" as Theme

PopupWindow {
    id: root

    required property var bar
    required property var calendarService
    required property bool calendarOpen

    visible: root.calendarOpen
    color: "transparent"

    anchor.window: root.bar
    anchor.rect.x: Math.round(bar.width / 2 - implicitWidth / 2)
    anchor.rect.y: bar.height + 6
    anchor.rect.width: 1
    anchor.rect.height: 1

    implicitWidth: 380
    implicitHeight: calColumn.implicitHeight + 28

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        Column {
            id: calColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            // ── Hero date ──
            Item {
                width: parent.width
                height: 42

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "󰃭"
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        color: Theme.fg
                        anchors.baseline: heroDate.baseline
                    }

                    Text {
                        id: heroDate
                        text: Qt.formatDate(root.calendarService.today, "MMMM d")
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                        font.weight: 700
                        color: Theme.fg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.calendarService.refreshCalendar()
                }
            }

            // ── Year progress ──
            Column {
                width: parent.width
                spacing: 4

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: String(root.calendarService.today.getFullYear())
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Qt.darker(Theme.fg, 1.4)
                        font.letterSpacing: 1
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                    }

                    Text {
                        text: root.calendarService.yearDonePercent + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: Theme.radius
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

                    Rectangle {
                        width: parent.width * root.calendarService.yearDone
                        height: parent.height
                        radius: Theme.radius
                        color: Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            // ── Month navigation ──
            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.centerIn: parent
                    width: 140
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(root.calendarService.calViewDate, "MMMM yyyy").toUpperCase()
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    color: Qt.darker(Theme.fg, 1.2)
                }

                Rectangle {
                    anchors.left: parent.left
                    width: 28
                    height: 28
                    radius: Theme.radius
                    color: prevMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                    border.color: prevMouse.containsMouse ? Theme.border : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.fg
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.calendarService.stepCalMonth(-1)
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 28
                    height: 28
                    radius: Theme.radius
                    color: nextMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                    border.color: nextMouse.containsMouse ? Theme.border : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.fg
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.calendarService.stepCalMonth(1)
                    }
                }
            }

            // ── Weekday headers ──
            Row {
                width: parent.width
                spacing: 2

                Item {
                    width: 28
                    height: 16
                }

                Repeater {
                    model: root.calendarService.weekdayOrder(root.calendarService.weekStart)

                    delegate: Text {
                        required property int modelData
                        width: (parent.width - 28 - 6 * 2) / 7
                        height: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][modelData].substring(0, 2)
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        font.bold: true
                        color: Qt.darker(Theme.fg, 1.5)
                    }
                }
            }

            // ── Calendar grid ──
            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.calendarService.calWeeks

                    delegate: Row {
                        required property var modelData
                        width: parent.width
                        spacing: 2

                        Text {
                            width: 28
                            height: 30
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: String(modelData.week)
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            color: Qt.darker(Theme.fg, 1.8)
                        }

                        Repeater {
                            model: modelData.days

                            delegate: Item {
                                required property var modelData
                                width: (parent.parent.width - 28 - 6 * 2) / 7
                                height: 34

                                property var dayEvents: root.calendarService.festivalsForDate(modelData.year, modelData.month, modelData.day)
                                property bool hasEvents: dayEvents.length > 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radius
                                    color: dayMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : modelData.today ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : "transparent"
                                    border.width: modelData.today ? 1 : 0
                                    border.color: Theme.border
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(modelData.day)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: modelData.today ? 700 : 400
                                        color: modelData.inMonth ? (modelData.weekend ? Qt.darker(Theme.fg, 1.3) : Theme.fg) : Qt.darker(Theme.fg, 2.0)
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        visible: hasEvents

                                        Repeater {
                                            model: dayEvents.slice(0, 3)

                                            delegate: Rectangle {
                                                required property var modelData
                                                required property int index
                                                width: 5
                                                height: 5
                                                radius: 2.5
                                                color: root.calendarService.eventDotColor(index)
                                            }
                                        }

                                        Text {
                                            visible: dayEvents.length > 3
                                            text: "+" + (dayEvents.length - 3)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 6
                                            color: Theme.muted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: hasEvents ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }

                                ToolTip {
                                    visible: dayMouse.containsMouse && hasEvents
                                    delay: 300
                                    timeout: 3000
                                    text: dayEvents.join("\n")
                                    contentItem: Text {
                                        text: dayMouse.containsMouse && hasEvents ? dayEvents.join("\n") : ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.fg
                                        wrapMode: Text.Wrap
                                    }
                                    background: Rectangle {
                                        color: Theme.bg
                                        border.color: Theme.border
                                        border.width: 1
                                        radius: 4
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        WheelHandler {
            onWheel: function (e) {
                if (e.angleDelta.y !== 0)
                    root.calendarService.stepCalMonth(e.angleDelta.y > 0 ? -1 : 1);
            }
        }
    }
}
