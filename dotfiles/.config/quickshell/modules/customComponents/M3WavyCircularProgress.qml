import Quickshell
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Item {
    id: root
    property real progress: 0.6
    property real thickness: 4
    property real radius: Math.min(width, height) / 2 - thickness
    property string baseColor: Colors.primaryText
    property string lineColor: Colors.primary
    property real gap: 0

    property bool sperm: true
    property bool animateSperm: true
    property real spermAmplitudeMultiplier: sperm ? 0.5 : 0
    property real spermFrequency: 20
    property real spermFps: 60

    // Dedicated phase tracker to maintain visual position when animation is paused
    property real wavePhase: 0

    Behavior on spermAmplitudeMultiplier {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real startAngle: (-Math.PI / 2 ) - 0.1
        readonly property real endAngle: startAngle + (2 * Math.PI * root.progress)
        readonly property real baseEndAngle: (2 * Math.PI)

        onEndAngleChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset();

            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round"

            const r = root.radius
            const cx = centerX;
            const cy = centerY;

            const amplitude = root.thickness * root.spermAmplitudeMultiplier;
            const phase = root.wavePhase;

            // --- 1. DRAW BASE LINE (Background Track) ---
            const baseStart = endAngle;
            const baseEnd = (Math.PI / 2 + Math.PI) - root.gap;

            if (amplitude > 0 && baseEnd > baseStart) {
                const baseSteps = Math.max(1, Math.round(Math.abs(baseEnd - baseStart) / 0.02));
                ctx.beginPath();

                for (let i = 0; i <= baseSteps; i++) {
                    const angle = baseStart + (baseEnd - baseStart) * i / baseSteps;
                    // Continuous tracking matching absolute angle positions
                    const waveR = r + amplitude * Math.sin(root.spermFrequency * (angle - startAngle) + phase);
                    const x = cx + waveR * Math.cos(angle);
                    const y = cy + waveR * Math.sin(angle);

                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.strokeStyle = root.baseColor;
                ctx.stroke();
            } else {
                ctx.beginPath();
                ctx.arc(cx, cy, r, baseStart, baseEnd, false);
                ctx.strokeStyle = root.baseColor;
                ctx.stroke();
            }

            // --- 2. DRAW PROGRESS LINE ---
            if (root.progress > 0) {
                const start = startAngle;
                const arcSpan = endAngle - startAngle;
                const effectiveGap = Math.min(root.gap, arcSpan * 0.5);
                const end = endAngle - effectiveGap;

                if (amplitude > 0 && end > start) {
                    const steps = Math.max(1, Math.round(Math.abs(end - start) / 0.02));
                    ctx.beginPath();

                    for (let i = 0; i <= steps; i++) {
                        const angle = start + (end - start) * i / steps;
                        const waveR = r + amplitude * Math.sin(root.spermFrequency * (angle - startAngle) + phase);
                        const x = cx + waveR * Math.cos(angle);
                        const y = cy + waveR * Math.sin(angle);

                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                    ctx.strokeStyle = root.lineColor;
                    ctx.stroke();
                } else {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, start, end, false);
                    ctx.strokeStyle = root.lineColor;
                    ctx.stroke();
                }
            }
        }

        Timer {
            interval: 1000 / root.spermFps
            running: root.animateSperm
            repeat: root.sperm
            onTriggered: {
                // Manually progress the wave phase relative to frame rate
                root.wavePhase += (1000 / root.spermFps) / 400.0;
                canvas.requestPaint();
            }
        }
    }

    // MaterialIconSymbol {
    //     anchors.centerIn: parent
    //     content: root.icon
    //     iconSize: root.iconSize
    //     color: root.iconColor
    // }
}
