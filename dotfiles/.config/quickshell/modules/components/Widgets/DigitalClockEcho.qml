import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// The time repeated behind itself on a diagonal, each copy further back and
// fainter — depth from repetition rather than from a shadow or a card.
//
// The trailing copies pick up the accent colour instead of dimming to grey, so
// the stack reads as one object lit from the front rather than three ghosts.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: stack.implicitWidth + 26
    implicitHeight: col.implicitHeight

    readonly property var _parts: String(ServiceClock.time).split(" ")
    readonly property string clockText: root._parts[0] ?? ""
    readonly property string meridiem: (root._parts[1] ?? "").toUpperCase()

    // Offset per echo step, in px
    readonly property int step: 13

    ColumnLayout {
        id: col
        spacing: 0

        Item {
            id: stack
            Layout.alignment: Qt.AlignLeft
            implicitWidth: front.implicitWidth
            implicitHeight: front.implicitHeight

            // Back to front, so the solid copy lands on top
            CustomText {
                x: root.step * 2; y: root.step * 2
                content: root.clockText
                size: 120
                weight: 800
                color: Qt.alpha(Colors.primary, 0.14)
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                x: root.step; y: root.step
                content: root.clockText
                size: 120
                weight: 800
                color: Qt.alpha(Colors.primary, 0.3)
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                id: front
                content: root.clockText
                size: 120
                weight: 800
                color: Colors.surfaceText
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }
        }

        RowLayout {
            // Clears the deepest echo copy, which hangs step*2 below the front
            Layout.topMargin: root.step * 2 + 6
            Layout.leftMargin: 4
            spacing: 8

            CustomText {
                content: root.meridiem
                size: 14
                weight: 700
                customColor: Colors.primary
                font.letterSpacing: 3
            }

            CustomText {
                content: ServiceClock.day + " " + ServiceClock.date
                size: 14
                weight: 500
                customColor: Colors.outline
                font.letterSpacing: 1
            }
        }
    }
}
