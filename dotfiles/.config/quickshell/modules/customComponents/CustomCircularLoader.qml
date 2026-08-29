import QtQuick
import Quickshell
import qs.modules.utils

Item {
    id: root

    property real size: 48
    property real trackWidth: 4
    property color highlightColor: Colors.primary
    property color trackColor: Colors.secondaryContainer

    property real value: -1

    property real waveAmplitude: 0
    property real wavelength: 15
    property real trackGap: 4

    readonly property bool indeterminate: root.value < 0
    readonly property bool spinning: root.indeterminate && root.visible

    readonly property var _standard:  [0.2, 0.0, 0.0, 1.0, 1, 1]
    readonly property var _emphDecel: [0.05, 0.7, 0.1, 1.0, 1, 1]

    property real phase: 0.0
    property real globalRotation: 0.0
    property real additionalRotation: 0.0
    property real arcProgress: 0.1

    property real currentAmplitude: 0.0
    readonly property real _targetAmplitude: {
        if (root.indeterminate) return 1.0
        const p = Math.max(0, Math.min(1, root.value))
        return (p > 0.1 && p < 0.95) ? 1.0 : 0.0
    }

    on_TargetAmplitudeChanged: root.currentAmplitude = root._targetAmplitude
    Component.onCompleted: root.currentAmplitude = root._targetAmplitude

    Behavior on currentAmplitude {
        NumberAnimation { duration: 700; easing.type: Easing.InOutCubic }
    }

    NumberAnimation on globalRotation {
        from: 0; to: 1080
        duration: 6000
        loops: Animation.Infinite
        running: root.spinning
    }

    SequentialAnimation on additionalRotation {
        running: root.spinning
        loops: Animation.Infinite
        NumberAnimation {
            from: 0; to: 90; duration: 300
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._emphDecel
        }
        PauseAnimation { duration: 1200 }
        NumberAnimation {
            from: 90; to: 180; duration: 300
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._emphDecel
        }
        PauseAnimation { duration: 1200 }
        NumberAnimation {
            from: 180; to: 270; duration: 300
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._emphDecel
        }
        PauseAnimation { duration: 1200 }
        NumberAnimation {
            from: 270; to: 360; duration: 300
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._emphDecel
        }
        PauseAnimation { duration: 1200 }
    }

    SequentialAnimation on arcProgress {
        running: root.spinning
        loops: Animation.Infinite
        NumberAnimation {
            from: 0.1; to: 0.87; duration: 3000
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._standard
        }
        NumberAnimation {
            from: 0.87; to: 0.1; duration: 3000
            easing.type: Easing.BezierSpline; easing.bezierCurve: root._standard
        }
    }

    NumberAnimation on phase {
        from: 0; to: Math.PI * 2
        duration: 1000
        loops: Animation.Infinite
        running: root.visible && (root.indeterminate || root.currentAmplitude > 0.01)
    }

    Behavior on value {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    width: size
    height: size

    Canvas {
        id: canvas
        anchors.fill: parent

        rotation: root.indeterminate
            ? (root.globalRotation + root.additionalRotation)
            : -90

        Connections {
            target: root
            function onPhaseChanged()              { canvas.requestPaint() }
            function onValueChanged()              { canvas.requestPaint() }
            function onArcProgressChanged()        { canvas.requestPaint() }
            function onGlobalRotationChanged()     { canvas.requestPaint() }
            function onAdditionalRotationChanged() { canvas.requestPaint() }
            function onCurrentAmplitudeChanged()   { canvas.requestPaint() }
            function onHighlightColorChanged()     { canvas.requestPaint() }
            function onTrackColorChanged()         { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            const cx = width / 2
            const cy = height / 2
            const r  = cx - root.trackWidth / 2 - root.waveAmplitude - 1

            const TWO_PI = 2 * Math.PI
            const numWaves = Math.max(3, Math.round(TWO_PI * r / root.wavelength))

            const arcSweep = root.indeterminate
                ? root.arcProgress * TWO_PI
                : Math.max(0.01, Math.min(1, root.value)) * TWO_PI

            const gapRad = root.trackGap / r

            ctx.lineWidth = root.trackWidth
            ctx.lineCap   = "round"

            ctx.strokeStyle = root.trackColor
            if (arcSweep < TWO_PI - gapRad * 2) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, arcSweep + gapRad, TWO_PI - gapRad)
                ctx.stroke()
            } else if (root.value <= 0.01 && root.value >= 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, TWO_PI)
                ctx.stroke()
            }

            if (arcSweep < 0.01) return

            const amp = root.waveAmplitude * root.currentAmplitude

            ctx.beginPath()
            ctx.strokeStyle = root.highlightColor

            if (amp < 0.01) {
                ctx.arc(cx, cy, r, 0, arcSweep)
            } else {
                const taper = Math.min(TWO_PI / numWaves, arcSweep / 2)
                const steps = Math.max(100, numWaves * 24)
                for (let i = 0; i <= steps; i++) {
                    const angle = (i / steps) * arcSweep
                    const edge = Math.min(angle, arcSweep - angle)
                    let k = taper > 0 ? Math.min(1, edge / taper) : 1
                    k = k * k * (3 - 2 * k)
                    const wave = amp * k * Math.sin(numWaves * angle - root.phase)
                    const px = cx + (r + wave) * Math.cos(angle)
                    const py = cy + (r + wave) * Math.sin(angle)
                    if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                }
            }
            ctx.stroke()
        }
    }
}
