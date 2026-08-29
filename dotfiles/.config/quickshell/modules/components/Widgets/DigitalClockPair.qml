import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Hour over minute with no colon, no labels, no rule. Negative leading locks
// the two rows together so they read as one shape instead of two numbers.
//
// The minute takes the accent — with the separator gone, colour is what tells
// you which half you are looking at.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: pair.implicitWidth
    implicitHeight: pair.implicitHeight

    // 12-hour, but zero-padded unlike the single-line styles: the two rows sit
    // directly on top of each other, so a bare "9" over "41" would leave the
    // block ragged down one edge.
    readonly property string hour12: {
        var h = parseInt(ServiceClock.hour, 10) % 12
        if (h === 0) h = 12
        return h < 10 ? "0" + h : String(h)
    }

    ColumnLayout {
        id: pair
        spacing: -40

        CustomText {
            content: root.hour12
            size: 130
            weight: 800
            color: Colors.surfaceText
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
        }

        CustomText {
            content: ServiceClock.minute
            size: 130
            weight: 800
            color: Colors.primary
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
        }
    }
}
