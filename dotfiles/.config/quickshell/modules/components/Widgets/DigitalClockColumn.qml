import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Hours over minutes, read top to bottom. The accent rule down the left edge is
// the only structure — it marks where the column starts, which is the one thing
// a flush-left stack of numerals otherwise leaves ambiguous against wallpaper.
//
// Duotone rather than one colour: the hour carries the text colour, the minute
// the accent, so the two lines stay distinguishable at a glance despite being
// the same size and weight.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: outer.implicitWidth
    implicitHeight: outer.implicitHeight

    // "hh" / "mm" — zero-padded, which is what keeps the two lines the same
    // width and the column edge straight.
    readonly property string hourText: ServiceClock.hour
    readonly property string minuteText: ServiceClock.minute

    RowLayout {
        id: outer
        spacing: 18

        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 14
            Layout.bottomMargin: 14
            implicitWidth: 4
            radius: 2
            color: Colors.primary
        }

        ColumnLayout {
            id: body
            spacing: -34

            CustomText {
                content: root.hourText
                size: 112
                weight: 800
                color: Colors.surfaceText
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                content: root.minuteText
                size: 112
                weight: 800
                color: Colors.primary
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                Layout.topMargin: 22
                content: ServiceClock.day.slice(0, 3).toUpperCase() + "  "
                       + ServiceClock.date + "  "
                       + ServiceClock.month.slice(0, 3).toUpperCase()
                size: 13
                weight: 600
                customColor: Colors.outline
                font.letterSpacing: 3
            }
        }
    }
}
