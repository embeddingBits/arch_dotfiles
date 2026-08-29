import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: text.implicitWidth
    implicitHeight: text.implicitHeight

    CustomText {
        id: text
        content: ServiceClock.time
        size: 140
        weight: 800
        color: Colors.surfaceText
        font.family: SettingsConfig.general.displayFont ?? "Titan One"
        style: Text.Raised
        styleColor: Colors.outline
    }
}
