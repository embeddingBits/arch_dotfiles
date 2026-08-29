import QtQuick
import qs.modules.settings

NumberAnimation {
    property string speed: "default"

    duration: M3Motion.effectsDuration(speed)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: M3Motion.effects.curve
}
