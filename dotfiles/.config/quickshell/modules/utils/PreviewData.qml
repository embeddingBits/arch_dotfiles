pragma Singleton

import Quickshell
import QtQuick

// Canned readings for widgets rendered in the settings gallery.
//
// Deliberately API-compatible with ServiceSystemInfo, so a widget can swap the
// whole source with one alias:
//
//     readonly property var si: preview ? PreviewData : ServiceSystemInfo
//
// retain()/release() are no-ops here, which is the point: a preview must never
// start the polling processes that back the real service. Values are plausible
// rather than zero so the cards still look like what they represent.
Singleton {
    id: root

    readonly property real cpuUsage: 0.42
    readonly property real memUsage: 0.61
    readonly property real memUsedGb: 9.7
    readonly property real memTotalGb: 16.0
    readonly property real cpuTemp: 52
    readonly property string cpuName: "CPU"

    readonly property real diskUsage: 0.73
    readonly property real diskUsedGb: 214
    readonly property real diskTotalGb: 293

    readonly property real gpuUsage: 0.28
    readonly property real gpuTemp: 47
    readonly property real gpuVramUsage: 0.35
    readonly property real gpuVramUsedGb: 2.8
    readonly property real gpuVramTotalGb: 8.0
    readonly property real gpuClockMhz: 1850
    readonly property string gpuName: "GPU"

    readonly property real netDownloadBps: 1.4 * 1024 * 1024
    readonly property real netUploadBps: 320 * 1024
    readonly property real netTotalRxBytes: 4.2 * 1024 * 1024 * 1024
    readonly property real netTotalTxBytes: 0.9 * 1024 * 1024 * 1024

    readonly property string uptime: "3h 12m"

    function retain() {}
    function release() {}
    function getUptime() {}

    function formatNetSpeed(bps) {
        if (bps >= 1024 * 1024) return (bps / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bps >= 1024)        return (bps / 1024).toFixed(1) + " KB/s"
        return Math.round(bps) + " B/s"
    }

    function formatBytes(bytes) {
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
        if (bytes >= 1024 * 1024)        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        if (bytes >= 1024)               return (bytes / 1024).toFixed(1) + " KB"
        return Math.round(bytes) + " B"
    }
}
