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
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        spacing: -8

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            content: ServiceClock.time
            size: 100
            weight: 800
            color: Colors.surfaceText
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
            style: Text.Raised
            styleColor: Colors.outline
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            content: ServiceClock.day + ", " + ServiceClock.month + " " + ServiceClock.date
            size: 22
            weight: 700
            color: Colors.primary
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
        }
    }
}
