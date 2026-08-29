import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// An instrument readout rather than a display clock: small, wide, monospaced,
// with live seconds. Sized to sit in a corner next to something else instead of
// dominating the wallpaper the way the other digital styles do.
//
// Monospace matters here — this is the only clock showing seconds, and a
// proportional face makes the whole row twitch every time a digit changes width.
WidgetHost {
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    // Generic family name — fontconfig resolves it to whatever mono face is
    // installed, so this doesn't depend on a specific font being present.
    readonly property string mono: "monospace"

    ColumnLayout {
        id: col
        spacing: 4

        // Eyebrow: the date, since the numerals below only carry time
        CustomText {
            Layout.leftMargin: 3
            content: ServiceClock.day.toUpperCase() + " · "
                   + ServiceClock.date + " " + ServiceClock.month.toUpperCase()
            size: 11
            weight: 600
            customColor: Colors.outline
            font.letterSpacing: 4
        }

        RowLayout {
            spacing: 2

            CustomText {
                content: ServiceClock.hour
                size: 46
                weight: 700
                color: Colors.surfaceText
                font.family: root.mono
                font.letterSpacing: 2
            }

            CustomText {
                id: colonA
                content: ":"
                size: 46
                weight: 700
                color: Colors.primary

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { from: 1;   to: 0.2; duration: 500; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.2; to: 1;   duration: 500; easing.type: Easing.InOutQuad }
                }
            }

            CustomText {
                content: ServiceClock.minute
                size: 46
                weight: 700
                color: Colors.surfaceText
                font.family: root.mono
                font.letterSpacing: 2
            }

            CustomText {
                content: ":"
                size: 46
                weight: 700
                color: Colors.primary
                opacity: colonA.opacity
            }

            // Seconds sit back a step — present for the tick, not for reading
            CustomText {
                content: ServiceClock.seconds
                size: 46
                weight: 700
                customColor: Colors.outline
                font.family: root.mono
                font.letterSpacing: 2
            }
        }
    }
}
