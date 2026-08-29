import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Hollow numerals — the wallpaper reads through the time instead of behind it.
// This style only works without a card: put a surface behind it and the effect
// collapses into ordinary outlined text.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    // ServiceClock.time is "h:mm a"; the meridiem is set separately below so it
    // doesn't inherit the 150px display size.
    readonly property var _parts: String(ServiceClock.time).split(" ")
    readonly property string clockText: root._parts[0] ?? ""
    readonly property string meridiem: (root._parts[1] ?? "").toUpperCase()

    ColumnLayout {
        id: col
        spacing: 0

        Item {
            Layout.alignment: Qt.AlignLeft
            implicitWidth: outline.implicitWidth
            implicitHeight: outline.implicitHeight

            // A whisper of fill under the ring. Pure outline disappears against
            // a busy wallpaper — this is the minimum that keeps it readable
            // without turning the numerals solid.
            CustomText {
                anchors.fill: parent
                content: root.clockText
                size: 150
                weight: 800
                color: Qt.alpha(Colors.surfaceText, 0.12)
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }

            CustomText {
                id: outline
                content: root.clockText
                size: 150
                weight: 800
                color: "transparent"
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Outline
                styleColor: Colors.surfaceText
            }
        }

        // Meridiem and day, solid, riding the baseline of the numerals
        RowLayout {
            Layout.topMargin: -14
            Layout.leftMargin: 6
            spacing: 10

            CustomText {
                content: root.meridiem
                size: 15
                weight: 700
                customColor: Colors.primary
                font.letterSpacing: 4
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 4; implicitHeight: 4; radius: 2
                color: Colors.primary
                opacity: 0.7
            }

            CustomText {
                content: ServiceClock.day.toUpperCase()
                size: 15
                weight: 500
                customColor: Colors.outline
                font.letterSpacing: 4
            }
        }
    }
}
