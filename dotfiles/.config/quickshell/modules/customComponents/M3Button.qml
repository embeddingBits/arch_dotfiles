import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Rectangle {
    id: root

    // "xsmall" | "small" | "medium" | "large" | "xlarge"
    property string size: "small"
    // "filled" | "tonal" | "outlined" | "text" | "elevated"
    property string variant: "filled"
    // false: pill (CornerFull).  true: square-ish (CornerMedium/Large).
    property bool square: false
    property bool toggled: false
    property bool enabledButton: true

    property string icon: ""
    property string label: ""
    property int iconFill: toggled ? 1 : 0

    signal clicked
    signal rightClicked

    readonly property var _spec: ({
        "xsmall": { h: 32,  pad: 12, gap: 8,  icon: 20, text: 12, sq: 12, press: 8  },
        "small":  { h: 40,  pad: 16, gap: 8,  icon: 20, text: 14, sq: 12, press: 8  },
        "medium": { h: 56,  pad: 24, gap: 8,  icon: 24, text: 16, sq: 16, press: 12 },
        "large":  { h: 96,  pad: 48, gap: 12, icon: 32, text: 24, sq: 28, press: 16 },
        "xlarge": { h: 136, pad: 64, gap: 16, icon: 40, text: 32, sq: 28, press: 20 }
    })
    readonly property var s: _spec[size] !== undefined ? _spec[size] : _spec["small"]

    readonly property bool _hasIcon:  icon !== ""
    readonly property bool _hasLabel: label !== ""

    implicitHeight: s.h
    implicitWidth: Math.max(s.h,
        s.pad * 2
        + (_hasIcon  ? _icon.implicitWidth  : 0)
        + (_hasIcon && _hasLabel ? s.gap : 0)
        + (_hasLabel ? _label.implicitWidth : 0))

    // Shape morph: round ⇄ square, and a tighter corner while pressed.
    radius: ripple.pressed ? s.press : (square ? s.sq : height / 2)
    Behavior on radius {
        NumberAnimation {
            duration: M3Motion.container.radiusDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3Motion.container.curve
        }
    }

    readonly property color _container: {
        if (!enabledButton) return Qt.alpha(Colors.surfaceText, 0.12)
        switch (variant) {
        case "tonal":    return toggled ? Colors.primary : Colors.surfaceContainerHighest
        case "outlined": return toggled ? Colors.primary : "transparent"
        case "text":     return toggled ? Colors.primary : "transparent"
        case "elevated": return Colors.surfaceContainerLow
        default:         return toggled ? Colors.primary : Colors.primary
        }
    }
    readonly property color _onContainer: {
        if (!enabledButton) return Qt.alpha(Colors.surfaceText, 0.38)
        switch (variant) {
        case "tonal":    return toggled ? Colors.primaryText : Colors.surfaceText
        case "outlined": return toggled ? Colors.primaryText : Colors.surfaceText
        case "text":     return toggled ? Colors.primaryText : Colors.primary
        case "elevated": return Colors.primary
        default:         return Colors.primaryText
        }
    }

    color: _container
    Behavior on color { ColorAnimation { duration: M3Motion.effects.fastDuration } }

    border.width: variant === "outlined" && !toggled ? 1 : 0
    border.color: enabledButton ? Colors.outline : Qt.alpha(Colors.outline, 0.4)

    opacity: enabledButton ? 1 : 0.6

    Row {
        id: _row
        anchors.centerIn: parent
        spacing: root._hasIcon && root._hasLabel ? root.s.gap : 0

        MaterialIconSymbol {
            id: _icon
            visible: root._hasIcon
            anchors.verticalCenter: parent.verticalCenter
            content: root.icon
            iconSize: root.s.icon
            fill: root.iconFill
            customColor: root._onContainer
            Behavior on fill { NumberAnimation { duration: M3Motion.effects.defaultDuration } }
        }

        CustomText {
            id: _label
            visible: root._hasLabel
            anchors.verticalCenter: parent.verticalCenter
            content: root.label
            size: root.s.text
            customColor: root._onContainer
        }
    }

    RippleEffect {
        id: ripple
        anchors.fill: parent
        radius: root.radius
        enabled: root.enabledButton
        hoverColor:  Qt.alpha(root._onContainer, 0.08)
        rippleColor: Qt.alpha(root._onContainer, 0.20)
        onClicked: if (root.enabledButton) root.clicked()
        onRightClicked: if (root.enabledButton) root.rightClicked()
    }
}
