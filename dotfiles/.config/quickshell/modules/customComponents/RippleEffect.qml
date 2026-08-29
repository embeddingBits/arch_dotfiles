import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.utils
import qs.modules.settings

// Drop-in interactive overlay: hover tint + M3-style press ripple.
//
//   Rectangle {
//       radius: 12
//       RippleEffect {
//           anchors.fill: parent
//           radius: parent.radius
//           onClicked: doSomething()
//       }
//   }
Item {
    id: root

    property real radius:            0
    property real topLeftRadius:     radius
    property real topRightRadius:    radius
    property real bottomLeftRadius:  radius
    property real bottomRightRadius: radius

    property color hoverColor:  Qt.alpha(Colors.primary, 0.08)
    property color pressColor:  Qt.alpha(Colors.primary, 0.14)  // kept for API compat
    property color rippleColor: Qt.alpha(Colors.primary, 0.25)
    property bool  hoverEnabled: true

    readonly property alias containsMouse: _mouse.containsMouse
    readonly property alias pressed:       _mouse.pressed

    signal clicked
    signal rightClicked

    // Hover tint — uses corner radii for visual shape
    Rectangle {
        anchors.fill: parent
        topLeftRadius:     root.topLeftRadius
        topRightRadius:    root.topRightRadius
        bottomLeftRadius:  root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: _mouse.containsMouse ? root.hoverColor : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Ripple container — OpacityMask clips circle to the rounded shape
    Item {
        id: _rippleClip
        anchors.fill: parent

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width:              _rippleClip.width
                height:             _rippleClip.height
                topLeftRadius:     root.topLeftRadius
                topRightRadius:    root.topRightRadius
                bottomLeftRadius:  root.bottomLeftRadius
                bottomRightRadius: root.bottomRightRadius
            }
        }

        Rectangle {
            id: _ripple
            width: 0; height: 0
            radius: width / 2
            opacity: 0
            color: root.rippleColor
            transform: Translate { x: -_ripple.width / 2; y: -_ripple.height / 2 }
        }
    }

    SequentialAnimation {
        id: _anim
        property real px: 0; property real py: 0; property real r: 0

        PropertyAction { target: _ripple; property: "x";       value: _anim.px }
        PropertyAction { target: _ripple; property: "y";       value: _anim.py }
        PropertyAction { target: _ripple; property: "width";   value: 0 }
        PropertyAction { target: _ripple; property: "height";  value: 0 }
        PropertyAction { target: _ripple; property: "opacity"; value: 1 }
        NumberAnimation {
            target: _ripple; properties: "width,height"
            to: _anim.r * 2
            duration: Appearance.duration.normal
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: _ripple; property: "opacity"; to: 0
            duration: Appearance.duration.small
            easing.type: Easing.InOutCubic
        }
    }

    MouseArea {
        id: _mouse
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: event => {
            const d = (ox, oy) => ox*ox + oy*oy
            _anim.px = event.x; _anim.py = event.y
            _anim.r = Math.sqrt(Math.max(
                d(event.x, event.y), d(event.x, height - event.y),
                d(width - event.x, event.y), d(width - event.x, height - event.y)
            ))
            _anim.restart()
        }

        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
