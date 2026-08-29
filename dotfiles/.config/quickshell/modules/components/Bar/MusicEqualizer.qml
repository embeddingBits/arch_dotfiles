import QtQuick
import qs.modules.utils

// Four bouncing bars — the "this is playing" cue for surfaces too small for a
// real visualiser. Deliberately not driven by audio: the collapsed bar item has
// no room to show anything meaningful about the spectrum, and a fake-but-steady
// motion reads as a status light rather than a broken meter.
//
// Bars are positioned by hand (x/y) instead of a Row because a positioner would
// fight the per-bar height animation.
Item {
    id: root

    property color barColor: Colors.primary
    property bool active: true
    property real barWidth: 2.5
    property real barSpacing: 2.5
    property int bars: 4

    implicitWidth: root.bars * root.barWidth + (root.bars - 1) * root.barSpacing
    implicitHeight: 14

    Repeater {
        model: root.bars

        Rectangle {
            id: bar
            required property int index

            width: root.barWidth
            radius: root.barWidth / 2
            color: root.barColor
            x: bar.index * (root.barWidth + root.barSpacing)
            height: root.height * 0.3
            y: root.height - height

            // Staggered periods so the four never land in sync
            SequentialAnimation on height {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation {
                    to: root.height
                    duration: 320 + bar.index * 90
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: root.height * 0.25
                    duration: 380 + bar.index * 70
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
