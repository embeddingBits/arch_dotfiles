import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Time and nothing else, as one solid mass. Negative tracking pulls the digits
// until they almost touch, so the whole readout reads as a single object rather
// than four characters and a colon.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: slab.implicitWidth
    implicitHeight: slab.implicitHeight

    // ServiceClock.time is "h:mm a" — take everything before the space, which
    // is the 12-hour clock without the meridiem.
    readonly property string clockText: String(ServiceClock.time).split(" ")[0] ?? ""

    CustomText {
        id: slab
        content: root.clockText
        size: 165
        weight: 800
        color: Colors.surfaceText
        font.family: SettingsConfig.general.displayFont ?? "Titan One"
        font.letterSpacing: -8
        style: Text.Raised
        styleColor: Colors.outline
    }
}
