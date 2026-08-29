import QtQuick
import qs.modules.utils

// Single-line text that scrolls itself when it doesn't fit, instead of eliding.
//
// Track titles are the motivating case: the width available in the bar is set by
// the bar's layout, not by the content, so eliding hides exactly the part that
// distinguishes one track from another. Scrolling is opt-in per surface via
// `scrolling` — a paused player animating in the corner of the screen is noise.
Item {
    id: root

    property string content: ""
    property int size: 12
    property int weight: 500
    property string customColor: Colors.surfaceText

    property bool scrolling: true
    property real gap: 44           // blank run between the text and its repeat
    property real speed: 26         // px per second
    property int startDelay: 1600   // hold at the start so it's readable first

    implicitWidth: primary.implicitWidth
    implicitHeight: primary.implicitHeight
    clip: true

    readonly property bool overflowing:
        root.width > 0 && primary.implicitWidth > root.width + 0.5
    readonly property bool animating: root.scrolling && root.overflowing

    Row {
        id: track
        spacing: root.gap

        CustomText {
            id: primary
            content: root.content
            size: root.size
            weight: root.weight
            customColor: root.customColor
            // Constrained only when parked, so the idle state elides rather than
            // ending on a hard clip mid-glyph.
            width: root.animating || root.width <= 0
                   ? implicitWidth
                   : Math.min(implicitWidth, root.width)
        }

        CustomText {
            content: root.content
            size: root.size
            weight: root.weight
            customColor: root.customColor
            width: implicitWidth
            visible: root.animating
        }
    }

    SequentialAnimation {
        running: root.animating
        loops: Animation.Infinite

        PauseAnimation { duration: root.startDelay }

        NumberAnimation {
            target: track
            property: "x"
            from: 0
            to: -(primary.implicitWidth + root.gap)
            duration: Math.max(1, (primary.implicitWidth + root.gap) / root.speed * 1000)
            easing.type: Easing.Linear
        }
    }

    onAnimatingChanged: if (!root.animating) track.x = 0
    onContentChanged: track.x = 0
}
