import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// The opposite of Slab: light weight, wide tracking, air between the digits.
// Uses the body face rather than the display face — Titan One has one weight,
// and this style depends entirely on being thin.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: thin.implicitWidth
    implicitHeight: thin.implicitHeight

    // 12-hour without the meridiem — everything before the space in "h:mm a"
    readonly property string clockText: String(ServiceClock.time).split(" ")[0] ?? ""

    CustomText {
        id: thin
        content: root.clockText
        size: 120
        weight: 200
        customColor: Colors.surfaceText
        font.family: SettingsConfig.general.defaultFont ?? "Rubik"
        font.letterSpacing: 10
    }
}
