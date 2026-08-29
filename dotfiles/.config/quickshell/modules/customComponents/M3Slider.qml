import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root

    property real from: 0.0
    property real to:   1.0
    property real progress: 0.0
    readonly property real value: from + progress * _span

    property real peakLevel: 0.0
    property bool showPeak: false
    property int  stepCount: 0
    property bool interactive: true
    property bool vertical: false
    property string icon: ""
    property bool iconAtEnd: false
    property bool showStopIndicator: true

    // Spec ratio is handle 44 : track 16 (2.75). Derive both from the space we
    // actually get so the proportion holds in a compact row instead of the
    // handle towering over a fixed 16px track.
    readonly property real _extent: vertical ? width : height
    property real trackHeight:        Math.min(12, _extent / 2.75)
    property real handleWidth:        4
    property real pressedHandleWidth: 2
    property real handleHeight:       Math.min(32, _extent)
    property real handleGap:          6
    property real stopSize:           4
    property real stopTrailingSpace:  6
    // M3: corners adjacent to the handle are small, outer corners full.
    property real trackInsideCorner:  2
    property real trackOuterCorner:   -1   // -1 = CornerFull (height/2)
    readonly property real _outer: trackOuterCorner >= 0
        ? Math.min(trackOuterCorner, trackHeight / 2) : trackHeight / 2
    // Ends are padded so stop dots don't touch the track edge.
    property real trackPadding: stepCount > 1 ? 6 : 0
    property bool showValueLabel: true
    property string valueText: stepped
        ? (stepLabels && stepLabels.length > currentStep && stepLabels[currentStep] !== undefined
            ? String(stepLabels[currentStep]) : String(currentStep))
        : Math.round(position * 100) + "%"

    property color activeColor:   Colors.primary
    property color inactiveColor: Colors.surfaceContainerHighest
    property color handleColor:   Colors.primary
    property color iconColor:     Colors.primaryText

    // Stepped facade (API-compatible with the former stepped M3Slider).
    // In stepped mode the component never writes `value`/`currentStep` itself —
    // it only emits stepChanged, so an external binding on currentStep can't fight it.
    property int currentStep: -1
    property var stepLabels: []
    signal stepChanged(int step)

    readonly property bool stepped: stepCount > 1 && currentStep >= 0

    signal moved(real value)
    signal committed(real value)

    readonly property real _span: Math.max(1e-6, to - from)
    readonly property real position: stepped
        ? Math.max(0, Math.min(1, currentStep / (stepCount - 1)))
        : Math.max(0, Math.min(1, progress))
    readonly property bool pressed: drag.pressed

    // Constants, not derived from trackHeight/handleHeight: those now depend on
    // height, so deriving the implicit size from them would be a binding loop.
    implicitWidth:  vertical ? 32 : 200
    implicitHeight: vertical ? 200 : 32

    readonly property real _len: vertical ? height : width
    property real _hw: pressed ? pressedHandleWidth : handleWidth
    Behavior on _hw { NumberAnimation { duration: M3Motion.effects.fastDuration } }

    // Handle centre travels inset by half its width so it never clips the ends.
    readonly property real _inset: Math.max(handleWidth, pressedHandleWidth) / 2
                                 + trackPadding
    readonly property real _travel: Math.max(0, _len - _inset * 2)
    readonly property real _pos: _inset + _travel * position

    function _quantise(p) {
        if (stepCount <= 1) return p
        return Math.round(p * (stepCount - 1)) / (stepCount - 1)
    }

    function _applyAt(coord) {
        let p = vertical ? 1 - (coord - _inset) / Math.max(1, _travel)
                         : (coord - _inset) / Math.max(1, _travel)
        p = Math.max(0, Math.min(1, _quantise(p)))
        if (stepped) {
            const step = Math.round(p * (stepCount - 1))
            if (step !== currentStep) stepChanged(step)
            return
        }
        if (p === progress) return
        progress = p
        moved(value)
    }

    // ── Horizontal ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: !root.vertical

        Rectangle {
            id: hActive
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: Math.max(0, root._pos - root._hw / 2 - root.handleGap)
            height: root.trackHeight
            topLeftRadius: root._outer
            bottomLeftRadius: root._outer
            topRightRadius: Math.min(root.trackInsideCorner, height / 2)
            bottomRightRadius: Math.min(root.trackInsideCorner, height / 2)
            color: root.activeColor
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: root._pos + root._hw / 2 + root.handleGap
            width: Math.max(0, parent.width - x)
            height: root.trackHeight
            topLeftRadius: Math.min(root.trackInsideCorner, height / 2)
            bottomLeftRadius: Math.min(root.trackInsideCorner, height / 2)
            topRightRadius: root._outer
            bottomRightRadius: root._outer
            color: root.inactiveColor
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: root._pos - root._hw / 2
            width: root._hw
            height: Math.min(root.handleHeight, parent.height)
            radius: width / 2
            color: root.handleColor
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showStopIndicator && root.stepCount <= 1
                  && root.position < 0.999
            x: parent.width - root.stopTrailingSpace - root.stopSize
            width: root.stopSize; height: root.stopSize
            radius: width / 2
            color: root.activeColor
        }

        Repeater {
            model: root.stepCount > 1 ? root.stepCount : 0
            delegate: Rectangle {
                readonly property real p: index / (root.stepCount - 1)
                anchors.verticalCenter: parent.verticalCenter
                x: root._inset + root._travel * p - root.stopSize / 2
                width: root.stopSize; height: root.stopSize
                radius: width / 2
                visible: Math.abs(x + root.stopSize / 2 - root._pos)
                         > root._hw / 2 + root.handleGap
                color: p <= root.position ? root.iconColor : root.activeColor
                opacity: 0.85
            }
        }

        Rectangle {
            visible: root.showPeak && root.peakLevel > 0.01
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: Math.max(0, Math.min(hActive.width,
                   root._travel * Math.min(1, root.peakLevel)))
            height: root.trackHeight
            radius: height / 2
            color: Qt.alpha(root.iconColor, 0.25)
        }

        MaterialIconSymbol {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            readonly property real _endX:
                hActive.width - iconSize - Math.round(root.trackHeight * 0.35)
            readonly property bool _insideFill: _endX >= 4
            // Once the fill is too short to hold it, the icon hops past the handle
            // onto the inactive track instead of vanishing into the fill.
            x: !root.iconAtEnd ? Math.max(8, hActive.width / 2 - width / 2)
               : _insideFill ? _endX
               : Math.min(parent.width - iconSize - 4,
                          root._pos + root._hw / 2 + root.handleGap
                          + Math.round(root.trackHeight * 0.35))
            content: root.icon
            iconSize: Math.round(root.trackHeight * 0.55)
            customColor: root.iconAtEnd && !_insideFill ? root.activeColor : root.iconColor
        }
    }

    // ── Vertical ──────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: root.vertical

        Rectangle {
            id: vActive
            anchors.horizontalCenter: parent.horizontalCenter
            y: root._pos + root._hw / 2 + root.handleGap
            height: Math.max(0, parent.height - y)
            width: root.trackHeight
            radius: width / 2
            color: root.activeColor
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            height: Math.max(0, root._pos - root._hw / 2 - root.handleGap)
            width: root.trackHeight
            radius: width / 2
            color: root.inactiveColor
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root._pos - root._hw / 2
            height: root._hw
            width: Math.min(root.handleHeight, parent.width)
            radius: height / 2
            color: root.handleColor
        }

        MaterialIconSymbol {
            visible: root.icon !== "" && vActive.height > iconSize + 16
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - root.trackHeight
            content: root.icon
            iconSize: Math.round(root.trackHeight * 0.55)
            customColor: root.iconColor
        }
    }

    property bool _recent: false
    Timer { id: labelTimer; interval: 900; onTriggered: root._recent = false }

    Rectangle {
        visible: root.showValueLabel && (root.pressed || root._recent) && !root.vertical
        z: 5
        x: Math.max(0, Math.min(parent.width - width, root._pos - width / 2))
        // Floats above the slider. Safe: the only clipping ancestor in the settings
        // panel is the outer Flickable, and this stays well inside its viewport.
        y: -height - 6
        implicitWidth: _lbl.implicitWidth + 16
        implicitHeight: _lbl.implicitHeight + 8
        radius: height / 2
        color: root.activeColor
        CustomText {
            id: _lbl
            anchors.centerIn: parent
            content: root.valueText
            size: 11
            customColor: root.iconColor
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: mouse => { root._recent = true; labelTimer.restart()
                              root._applyAt(root.vertical ? mouse.y : mouse.x) }
        onPositionChanged: mouse => {
            if (pressed) root._applyAt(root.vertical ? mouse.y : mouse.x)
        }
        onReleased: root.committed(root.value)

        onWheel: wheel => {
            root._recent = true; labelTimer.restart()
            const stepFrac = root.stepCount > 1 ? 1 / (root.stepCount - 1) : 0.05
            const dir = wheel.angleDelta.y > 0 ? 1 : -1
            const p = Math.max(0, Math.min(1, root.position + dir * stepFrac))
            if (root.stepped) {
                const step = Math.round(p * (root.stepCount - 1))
                if (step !== root.currentStep) root.stepChanged(step)
                return
            }
            root.progress = root._quantise(p)
            root.moved(root.value)
            root.committed(root.value)
        }
    }
}
