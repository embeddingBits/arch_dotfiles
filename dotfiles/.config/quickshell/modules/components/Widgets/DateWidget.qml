import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "dateWidget"
    defaultPos: Qt.point(300, 300)
    implicitWidth: 210
    implicitHeight: 215

    readonly property int dayOfWeek: ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"].indexOf(ServiceClock.day)

    // Edit mode outline
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.surface

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            // ── Week row ────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]

                    delegate: Item {
                        required property int index
                        required property string modelData
                        readonly property bool isToday: index === root.dayOfWeek

                        implicitWidth: 26
                        implicitHeight: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            color: parent.isToday ? Colors.primary : "transparent"
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }

                        CustomText {
                            anchors.centerIn: parent
                            content: modelData
                            size: 11
                            weight: parent.isToday ? 700 : 400
                            color: parent.isToday ? Colors.primaryText : Colors.outline
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }
            }

            // ── Separator ────────────────────────────────────────────
            Rectangle {
                Layout.topMargin: 8
                Layout.bottomMargin: 0
                implicitWidth: 168
                implicitHeight: 1
                color: Qt.alpha(Colors.outline, 0.2)
            }

            // ── Large date number ─────────────────────────────────────
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.date
                size: 90
                weight: 600
                color: Colors.surfaceText
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
            }

            // ── Month · Year ──────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -8
                spacing: 6

                CustomText {
                    content: ServiceClock.month
                    size: 15
                    weight: 600
                    color: Colors.primary
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    style: Text.Raised
                    styleColor: Colors.outline
                }

                CustomText {
                    content: "·"
                    size: 15
                    color: Colors.outline
                }

                CustomText {
                    content: ServiceClock.year
                    size: 15
                    weight: 600
                    color: Colors.surfaceText
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    style: Text.Raised
                    styleColor: Colors.outline
                }
            }
        }
    }
}
