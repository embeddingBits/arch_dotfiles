import QtQuick
import qs.modules.utils
import qs.modules.settings

Item {
    id: morph

    default property alias content: contentHolder.data

    property real srcWidth: 80
    property real srcHeight: 30
    property real srcRadius: 15
    property real srcX: (morph.width - morph.srcWidth) / 2
    property real srcY: 0

    property real contentHeight: 0
    property real cardRadius: 24
    property color cardColor: Colors.surface
    property real cardBorderWidth: 0
    property color cardBorderColor: "transparent"

    property bool opened: false
    property bool contentVisible: false
    property bool fadeCard: false

    readonly property int morphDuration: M3Motion.spatialDuration("default")
    property var morphCurve: [0.2, 0.0, 0.0, 1.0, 1, 1]

    signal closeFinished

    implicitHeight: morph.contentHeight

    function open() {
        closeTimer.stop()
        morph.opened = true
    }

    function close() {
        if (!morph.opened) return
        morph.opened = false
        closeTimer.restart()
    }

    onOpenedChanged: {
        if (morph.opened) {
            contentTimer.restart()
        } else {
            contentTimer.stop()
            morph.contentVisible = false
        }
    }

    Timer {
        id: contentTimer
        interval: morph.morphDuration * 0.3
        onTriggered: if (morph.opened) morph.contentVisible = true
    }

    Timer {
        id: closeTimer
        interval: morph.morphDuration
        onTriggered: morph.closeFinished()
    }

    Rectangle {
        id: card

        width: morph.opened ? morph.width : morph.srcWidth
        height: morph.opened ? morph.contentHeight : morph.srcHeight
        x: morph.opened ? 0 : morph.srcX
        y: morph.opened ? 0 : morph.srcY
        radius: morph.opened ? morph.cardRadius : morph.srcRadius
        color: morph.cardColor
        clip: true

        border.width: morph.cardBorderWidth
        border.color: morph.cardBorderColor

        opacity: (!morph.fadeCard || morph.opened) ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: morph.morphDuration * 0.366
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0, 0, 0.6, 1, 1, 1]
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: morph.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: morph.morphCurve
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: morph.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: morph.morphCurve
            }
        }
        Behavior on x {
            NumberAnimation {
                duration: morph.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: morph.morphCurve
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: morph.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: morph.morphCurve
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: morph.morphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: morph.morphCurve
            }
        }

        Item {
            id: contentHolder
            width: morph.width
            height: morph.contentHeight
            x: (card.width - contentHolder.width) / 2
            y: 0

            opacity: morph.contentVisible ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: morph.contentVisible ? morph.morphDuration * 0.366
                                                   : morph.morphDuration * 0.3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: morph.contentVisible ? [0, 0, 0.6, 1, 1, 1]
                                                             : [0.4, 0, 1, 1, 1, 1]
                }
            }
        }
    }
}
