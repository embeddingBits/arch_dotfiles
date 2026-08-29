import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.utils
import qs.modules.settings

// Lightweight click area with M3 press ripple clipped to the button's rounded shape.
// Pass radius: parent.radius (or per-corner radii) so the ripple clips correctly.
MouseArea {
    id: root
    anchors.fill: parent

    property real radius:            0
    property real topLeftRadius:     radius
    property real topRightRadius:    radius
    property real bottomLeftRadius:  radius
    property real bottomRightRadius: radius

    onPressed: event => {
        parent.scale = 1
        const d = (ox, oy) => ox*ox + oy*oy
        _anim.px = event.x; _anim.py = event.y
        _anim.r = Math.sqrt(Math.max(
            d(event.x, event.y), d(event.x, height - event.y),
            d(width - event.x, event.y), d(width - event.x, height - event.y)
        ))
        _anim.restart()
    }

    onReleased: parent.scale = 1

    // Ripple clipped to the rounded shape via OpacityMask
    Item {
        id: _rippleClip
        anchors.fill: parent

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width:             _rippleClip.width
                height:            _rippleClip.height
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
            color: Qt.alpha(Colors.primary, 0.25)
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
}
