import QtQuick
import qs.modules.utils

Item {
    id: root

    property var values: []         // array of numeric values (push new ones in)
    property int maxPoints: 30      // how many history points to keep
    property color lineColor: Colors.primary
    property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.15)
    property real lineWidth: 1.5
    property bool filled: true      // fill area under the line

    // Pins the Y scale instead of self-scaling to this series' own peak. Needed
    // when two sparklines are read against each other — an upload trace that
    // self-scales looks as tall as a download trace 20x its size.
    property real maxOverride: 0    // <= 0 keeps the self-scaling behaviour

    // AOSP UsageGraph spec (Settings/widget/UsageGraph.java + SettingsLib
    // dimens): CornerPathEffect 6dp on the trace, and a fill that fades from
    // accent@20% at the top to fully transparent at the baseline. This is what
    // Android uses for *running* usage, as opposed to the trapezoid segments of
    // the battery-history chart.
    property real cornerRadius: 6
    property bool gradientFill: true

    // Throughput is bursty: one 8 MB/s spike against a few-KB/s baseline flattens
    // every other sample onto the axis under linear scaling. log1p compression
    // keeps the quiet traffic readable without clipping the peak.
    property bool logScale: false

    // Call this to append a new data point
    function addValue(v) {
        const copy = values.slice()
        copy.push(v)
        if (copy.length > maxPoints) copy.shift()
        values = copy
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            const pts = root.values
            if (pts.length < 2) return

            const maxVal = root.maxOverride > 0 ? root.maxOverride : Math.max(...pts, 1)
            const stepX  = width / (root.maxPoints - 1)
            const offsetX = (root.maxPoints - pts.length) * stepX

            const xAt = i => offsetX + i * stepX
            const norm = root.logScale
                ? v => Math.log1p(Math.max(0, v)) / Math.log1p(maxVal)
                : v => v / maxVal
            const yAt = v => height - norm(v) * height * 0.9

            // arcTo at each interior vertex is the Canvas equivalent of
            // CornerPathEffect. AOSP skips it on segments shorter than the
            // radius; at widget widths the step is only a few px, and an
            // oversized radius bows the trace away from its own data points.
            const r = Math.min(root.cornerRadius, stepX / 2)

            // `move` must be false when continuing an open fill subpath — a
            // moveTo there starts a new one and the fill never closes
            function trace(move) {
                if (move) ctx.moveTo(xAt(0), yAt(pts[0]))
                else ctx.lineTo(xAt(0), yAt(pts[0]))
                if (r > 0.01) {
                    for (let i = 1; i < pts.length - 1; i++)
                        ctx.arcTo(xAt(i), yAt(pts[i]), xAt(i + 1), yAt(pts[i + 1]), r)
                } else {
                    for (let i = 1; i < pts.length - 1; i++)
                        ctx.lineTo(xAt(i), yAt(pts[i]))
                }
                const last = pts.length - 1
                ctx.lineTo(xAt(last), yAt(pts[last]))
            }

            // Fill under the line
            if (root.filled) {
                ctx.beginPath()
                ctx.moveTo(xAt(0), height)
                trace(false)
                ctx.lineTo(xAt(pts.length - 1), height)
                ctx.closePath()

                if (root.gradientFill) {
                    const g = ctx.createLinearGradient(0, 0, 0, height)
                    g.addColorStop(0, Qt.rgba(root.lineColor.r, root.lineColor.g,
                                              root.lineColor.b, 0.2))
                    g.addColorStop(1, Qt.rgba(root.lineColor.r, root.lineColor.g,
                                              root.lineColor.b, 0))
                    ctx.fillStyle = g
                } else {
                    ctx.fillStyle = root.fillColor
                }
                ctx.fill()
            }

            // Line
            ctx.beginPath()
            trace(true)
            ctx.strokeStyle = root.lineColor
            ctx.lineWidth = root.lineWidth
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.stroke()
        }

        Connections {
            target: root
            function onValuesChanged() { canvas.requestPaint() }
            function onMaxOverrideChanged() { canvas.requestPaint() }
            function onLineColorChanged() { canvas.requestPaint() }
            function onLogScaleChanged() { canvas.requestPaint() }
            function onCornerRadiusChanged() { canvas.requestPaint() }
            function onGradientFillChanged() { canvas.requestPaint() }
        }
    }
}
