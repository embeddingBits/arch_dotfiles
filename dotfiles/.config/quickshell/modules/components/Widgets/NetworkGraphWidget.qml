import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Live network throughput, download above the centerline and upload below.
//
// Both traces share one Y scale (see `peak`) rather than each self-scaling —
// otherwise a 300 KB/s upload draws as tall as a 5 MB/s download and the shape
// of the graph lies about the ratio between them.
WidgetHost {
    id: root
    configKey: "networkGraph"
    tile: WidgetSizes.strip
    defaultPos: Qt.point(100, 780)

    // Previews read canned values and never start the pollers
    readonly property var si: root.preview ? PreviewData : ServiceSystemInfo

    readonly property int historyLength: root.preview ? 22 : ServiceSystemInfo.netHistoryPoints

    // Kept here rather than inside the sparklines so both can be scaled together
    property var downHist: []
    property var upHist: []

    // KB/s throughout; the sparklines only care about relative magnitude
    readonly property real peak: Math.max(1, ...root.downHist, ...root.upHist)

    function _push(arr, v) {
        const copy = arr.slice()
        copy.push(v)
        if (copy.length > root.historyLength) copy.shift()
        return copy
    }

    function sample(downKb, upKb) {
        root.downHist = _push(root.downHist, downKb)
        root.upHist   = _push(root.upHist,   upKb)
    }

    Component.onCompleted: {
        root.si.retain()   // no-op on PreviewData
        if (root.preview) {
            // A plausible burst so the gallery tile isn't a flat line
            const d = [40, 90, 220, 480, 900, 1400, 1100, 700, 420, 260, 180,
                       120, 300, 640, 1250, 1600, 1350, 800, 480, 300, 200, 140]
            const u = [10, 20, 45, 80, 140, 190, 160, 110, 70, 45, 30,
                       25, 50, 95, 170, 210, 180, 120, 80, 50, 35, 25]
            for (let i = 0; i < d.length; i++) root.sample(d[i], u[i])
        }
    }
    Component.onDestruction: root.si.release()

    property real _accDown: 0
    property real _accUp: 0
    property int  _accCount: 0

    function _resetHistory() {
        root.downHist = []
        root.upHist = []
        root._accDown = 0
        root._accUp = 0
        root._accCount = 0
    }

    Connections {
        target: ServiceSystemInfo
        enabled: !root.preview
        function onNetSampled() {
            root._accDown += ServiceSystemInfo.netDownloadBps / 1024
            root._accUp   += ServiceSystemInfo.netUploadBps / 1024
            root._accCount++

            if (root._accCount < ServiceSystemInfo.netSamplesPerPoint) return

            root.sample(root._accDown / root._accCount, root._accUp / root._accCount)
            root._accDown = 0
            root._accUp = 0
            root._accCount = 0
        }

        function onNetSampleIntervalMsChanged() { root._resetHistory() }
        function onNetHistoryPointsChanged()    { root._resetHistory() }
    }

    // ── Card ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            y: 14
            spacing: 6

            CustomText { content: "Network"; size: 13; customColor: Colors.primary }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol { content: "swap_vert"; iconSize: 13; customColor: Colors.outline }
            CustomText {
                content: root.si.formatBytes(root.si.netTotalRxBytes + root.si.netTotalTxBytes)
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Mirrored graph ────────────────────────────────────────────
        Item {
            id: graph
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            y: 38
            height: 60

            CustomSparkline {
                id: downTrace
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height / 2
                values: root.downHist
                maxPoints: root.historyLength
                maxOverride: root.peak
                lineColor: Colors.primary
                lineWidth: 2
                logScale: true
            }

            // Same component, flipped about its own centre so the trace grows
            // downward from the axis. Scale rather than rotation: a 180° turn
            // would also reverse the time axis.
            CustomSparkline {
                id: upTrace
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height / 2
                values: root.upHist
                maxPoints: root.historyLength
                maxOverride: root.peak
                lineColor: Colors.tertiary
                lineWidth: 2
                logScale: true

                transform: Scale {
                    origin.x: upTrace.width / 2
                    origin.y: upTrace.height / 2
                    yScale: -1
                }
            }

            // Axis
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: Colors.outlineVariant
                opacity: 0.5
            }
        }

        // ── Rates ─────────────────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            y: 106
            spacing: 0

            RowLayout {
                spacing: 5
                MaterialIconSymbol { content: "arrow_downward"; iconSize: 14; customColor: Colors.primary }
                CustomText {
                    content: root.si.formatNetSpeed(root.si.netDownloadBps)
                    size: 14
                    weight: 600
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 5
                MaterialIconSymbol { content: "arrow_upward"; iconSize: 14; customColor: Colors.tertiary }
                CustomText {
                    content: root.si.formatNetSpeed(root.si.netUploadBps)
                    size: 14
                    weight: 600
                }
            }
        }
    }
}
