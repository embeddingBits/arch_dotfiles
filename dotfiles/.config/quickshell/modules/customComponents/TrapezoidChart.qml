import QtQuick
import qs.modules.utils

// Port of AOSP's BatteryChartView.drawTrapezoids() — the Android battery-usage
// plot. N levels produce N-1 *trapezoids*: each slot's top edge runs from
// level[i] on the left to level[i+1] on the right and fills to the baseline, so
// the series reads as one sloping area cut into separate segments.
//
// Geometry from Settings/res/values/dimens.xml:
//   chartview_trapezoid_radius       5dp   (CornerPathEffect, rounds ALL corners)
//   chartview_trapezoid_margin_start 1dp   (inset each side => the gap)
//   chartview_trapezoid_margin_bottom 2dp
//   chartview_divider_width 1dp, chartview_divider_height 4dp (axis ticks)
Item {
    id: root

    property var values: []
    property var labels: []

    // Optional translucent series over the main one, on its own 0..backMax scale
    property var backValues: []
    property real backMax: 100

    property real lo: 0
    property real hi: 100
    property bool autoRange: false

    property color barColor: Colors.primary
    property color backColor: Qt.alpha(Colors.primary, 0.28)
    property color gridColor: Qt.alpha(Colors.outline, 0.35)
    property color labelColor: Colors.outline

    property var gridValues: []
    property string suffix: ""
    property int gridLabelWidth: 34
    property int labelHeight: 16

    property bool showAxis: true
    // Live histories carry far more samples than a widget has pixels; past this
    // many slots the 1px insets eat the shape, so bucket-average down to it
    property int maxSlots: 0

    property real cornerRadius: 5
    property real slotInset: 1
    property real bottomOffset: 2
    property real tickHeight: 4
    property real barAlpha: 1.0

    function bucket(arr, slots) {
        if (!arr || slots <= 0 || arr.length <= slots + 1) return arr ?? []
        const n = slots + 1
        const out = []
        const size = arr.length / n
        for (var i = 0; i < n; i++) {
            const s = Math.floor(i * size)
            const e = Math.max(s + 1, Math.floor((i + 1) * size))
            var sum = 0, c = 0
            for (var j = s; j < e && j < arr.length; j++) { sum += arr[j]; c++ }
            out.push(c > 0 ? sum / c : 0)
        }
        return out
    }

    readonly property var _values: root.bucket(root.values, root.maxSlots)
    readonly property var _back: root.bucket(root.backValues, root.maxSlots)

    readonly property real _lo: {
        if (!root.autoRange) return root.lo
        const v = root._values ?? []
        return v.length === 0 ? 0 : Math.min.apply(null, v)
    }
    readonly property real _hi: {
        if (!root.autoRange) return root.hi
        const v = root._values ?? []
        if (v.length === 0) return 1
        const m = Math.max.apply(null, v)
        return m > root._lo ? m : root._lo + 1
    }

    onValuesChanged: canvas.requestPaint()
    onBackValuesChanged: canvas.requestPaint()
    onLabelsChanged: canvas.requestPaint()
    onGridValuesChanged: canvas.requestPaint()
    onBarColorChanged: canvas.requestPaint()
    onBackColorChanged: canvas.requestPaint()
    onGridColorChanged: canvas.requestPaint()
    onLabelColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        // AOSP gets this from CornerPathEffect, which rounds every vertex of the
        // path. arcTo does the same thing one corner at a time.
        function trapezoid(ctx, l, r, topL, topR, bottom, radius) {
            const w = r - l
            const h = bottom - Math.min(topL, topR)
            if (w <= 0 || h <= 0) return
            const rr = Math.max(0, Math.min(radius, w / 2, h / 2))
            const midX = (l + r) / 2

            ctx.beginPath()
            if (rr <= 0.01) {
                ctx.moveTo(l, bottom)
                ctx.lineTo(l, topL)
                ctx.lineTo(r, topR)
                ctx.lineTo(r, bottom)
            } else {
                ctx.moveTo(midX, bottom)
                ctx.arcTo(l, bottom, l, topL, rr)
                ctx.arcTo(l, topL, r, topR, rr)
                ctx.arcTo(r, topR, r, bottom, rr)
                ctx.arcTo(r, bottom, midX, bottom, rr)
            }
            ctx.closePath()
            ctx.fill()
        }

        function drawSeries(ctx, series, lo, hi, plotW, bottom, top, color) {
            const n = series.length
            if (n < 2) return
            const span = Math.max(1e-6, hi - lo)
            const usable = bottom - top
            const slots = n - 1
            const unit = plotW / slots
            const yAt = v => bottom - ((Math.max(lo, Math.min(hi, v)) - lo) / span) * usable

            ctx.fillStyle = color
            for (var i = 0; i < slots; i++) {
                const l = i * unit + root.slotInset
                const r = (i + 1) * unit - root.slotInset
                canvas.trapezoid(ctx, l, r, yAt(series[i]), yAt(series[i + 1]),
                                 bottom, root.cornerRadius)
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const v = root._values ?? []
            if (v.length < 2 || width <= 0 || height <= 0) return

            const plotW = Math.max(1, width - root.gridLabelWidth)
            const axisY = root.showAxis
                ? Math.max(1, height - root.labelHeight - root.tickHeight)
                : height
            const bottom = axisY - root.bottomOffset
            const top = 4
            const lo = root._lo
            const hi = root._hi
            const span = Math.max(1e-6, hi - lo)

            ctx.font = "600 10px sans-serif"
            ctx.textBaseline = "middle"

            const grid = root.gridValues ?? []
            for (var g = 0; g < grid.length; g++) {
                const gy = bottom - ((grid[g] - lo) / span) * (bottom - top)
                if (gy < 0 || gy > bottom) continue

                ctx.strokeStyle = root.gridColor
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(0, Math.round(gy) + 0.5)
                ctx.lineTo(plotW, Math.round(gy) + 0.5)
                ctx.stroke()

                ctx.fillStyle = root.labelColor
                ctx.textAlign = "right"
                ctx.fillText(grid[g] + root.suffix, width,
                             Math.min(bottom - 5, Math.max(5, gy)))
            }

            ctx.globalAlpha = root.barAlpha
            canvas.drawSeries(ctx, v, lo, hi, plotW, bottom, top, root.barColor)
            ctx.globalAlpha = 1

            // Drawn last: the main series fills most of the plot, so a second
            // series behind it is simply invisible
            const back = root._back ?? []
            if (back.length >= 2)
                canvas.drawSeries(ctx, back, 0, root.backMax, plotW, bottom, top, root.backColor)

            // Axis with a tick between each pair of segments
            const slots = v.length - 1
            const unit = plotW / slots
            if (root.showAxis) {
                ctx.strokeStyle = root.gridColor
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(0, Math.round(axisY) + 0.5)
                ctx.lineTo(plotW, Math.round(axisY) + 0.5)
                ctx.stroke()

                for (var t = 0; t <= slots; t++) {
                    const tx = Math.round(t * unit) + 0.5
                    ctx.beginPath()
                    ctx.moveTo(tx, axisY)
                    ctx.lineTo(tx, axisY + root.tickHeight)
                    ctx.stroke()
                }
            }

            const labels = root.labels ?? []
            if (labels.length > 0 && root.labelHeight > 0) {
                ctx.fillStyle = root.labelColor
                ctx.textAlign = "center"
                for (var m = 0; m < labels.length && m < slots; m++) {
                    if (!labels[m]) continue
                    ctx.fillText(labels[m], m * unit + unit / 2,
                                 axisY + root.tickHeight + root.labelHeight / 2)
                }
            }
        }
    }
}
