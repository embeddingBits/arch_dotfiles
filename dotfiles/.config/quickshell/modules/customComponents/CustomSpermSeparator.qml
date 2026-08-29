import QtQuick
import Quickshell
import qs.modules.utils

Canvas {
    id: root

    property color color: Colors.primary
    property real amplitude: height * 0.4
    property real frequency: 8
    property real lineWidth: 2


    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var centerY = height / 2;

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();

        for (var x = 0; x <= width; x += 1) {
            var waveY = centerY + root.amplitude * Math.sin(root.frequency * 2 * Math.PI * x / width);
            if (x === 0)
                ctx.moveTo(x, waveY);
            else
                ctx.lineTo(x, waveY);
        }

        ctx.stroke();
    }

    Connections {
        target: root
        function onColorChanged() { root.requestPaint(); }
        function onAmplitudeChanged() { root.requestPaint(); }
        function onFrequencyChanged() { root.requestPaint(); }
        function onWidthChanged() { root.requestPaint(); }
        function onHeightChanged() { root.requestPaint(); }
    }
}
