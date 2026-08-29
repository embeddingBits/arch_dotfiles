import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialSHapeFn

ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 10
    spacing: 8

    property int currentYear:  new Date().getFullYear()
    property int currentMonth: new Date().getMonth()

    onCurrentYearChanged:  ServiceClock.ensureHolidaysForYear(currentYear)
    Component.onCompleted: ServiceClock.ensureHolidaysForYear(currentYear)

    // ── Header ───────────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 50
        radius: 16
        color: Colors.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 0

            Rectangle {
                width: 36; height: 36; radius: 18
                color: prevHov.containsMouse ? Colors.surfaceContainerHighest : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "chevron_left"
                    iconSize: 20
                    customColor: Colors.surfaceText
                }
                MouseArea {
                    id: prevHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (--root.currentMonth < 0) { root.currentMonth = 11; root.currentYear-- }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1

                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: ServiceClock.getMonthName(root.currentMonth)
                        size: 16; weight: 700
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: root.currentYear.toString()
                        size: 12
                        customColor: Colors.outline
                    }
                }
            }

            Rectangle {
                width: 36; height: 36; radius: 18
                color: nextHov.containsMouse ? Colors.surfaceContainerHighest : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "chevron_right"
                    iconSize: 20
                    customColor: Colors.surfaceText
                }
                MouseArea {
                    id: nextHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (++root.currentMonth > 11) { root.currentMonth = 0; root.currentYear++ }
                    }
                }
            }
        }
    }

    // ── Calendar grid card ───────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16
        color: Colors.surfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 0

            // Weekday headers — S M T W T F S, weekends in primary
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 32

                        CustomText {
                            anchors.centerIn: parent
                            content: modelData
                            size: 13; weight: 700
                            customColor: (index === 0 || index === 6) ? Colors.primary : Colors.outline
                        }
                    }
                }
            }

            // Day grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: ServiceClock.generateCalendarGrid(root.currentYear, root.currentMonth)

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isWeekend: (index % 7 === 0) || (index % 7 === 6)

                        // Gem shape for today and hover
                        MaterialShapes.ShapeCanvas {
                            anchors.centerIn: parent
                            width: 38; height: 38
                            roundedPolygon: MatrialSHapeFn.getGem()
                            color: modelData.isToday     ? Colors.primary
                                 : dateHov.containsMouse ? Colors.surfaceContainerHighest
                                 : "transparent"
                        }

                        // Date number
                        CustomText {
                            anchors.centerIn: parent
                            content: modelData.day ? modelData.day.toString() : ""
                            size: 14
                            weight: modelData.isToday ? 800 : 500
                            customColor: modelData.isToday         ? Colors.primaryText
                                       : !modelData.isCurrentMonth ? Qt.alpha(Colors.surfaceText, 0.22)
                                       : isWeekend                 ? Colors.primary
                                       : Colors.surfaceText
                            Behavior on customColor { ColorAnimation { duration: 150 } }
                        }

                        // Holiday dot below the number
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: modelData.isHoliday && modelData.isCurrentMonth && !!modelData.day
                            width: 4; height: 4; radius: 2
                            color: modelData.isToday ? Colors.primaryText : Colors.primary
                        }

                        MouseArea {
                            id: dateHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.day ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }

                        CustomToolTip {
                            content: (modelData.isHoliday && modelData.info?.length > 0)
                                   ? modelData.info.map(h => h.name).join("\n") : ""
                            visible: modelData.isHoliday && dateHov.containsMouse
                        }
                    }
                }
            }
        }
    }
}
