pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.settings

Singleton {
    id: root

    // ── Derived gap values ──────────────────────────────────────────────
    // Top is now reserved via PanelWindow exclusiveZone (see Layout.qml) per
    // Quickshell docs: exclusiveZone requires 1 or 3 anchors. This is more
    // reliable than hyprctl gaps_out for layershell bars. ServiceGaps now
    // only manages side/bottom gaps via hyprctl.
    readonly property string barMode:    SettingsConfig.general.barMode ?? "flat"
    readonly property bool   isPill:     barMode === "pill"
    readonly property real   pillMargin: SettingsConfig.general.pillMargin ?? 6

    readonly property int rightGap:  SettingsConfig.general.gapRight  ?? 5
    readonly property int bottomGap: SettingsConfig.general.gapBottom ?? 5
    readonly property int leftGap:   SettingsConfig.general.gapLeft   ?? 5

    // ── Apply ───────────────────────────────────────────────────────────
    function exec() {
        // top is 0 here — bar strip is reserved by Layout's exclusiveZone
        Quickshell.execDetached(["hyprctl", "eval",
            "hl.config({ general = { gaps_out = { top = 0" +
            ", right = "  + root.rightGap  +
            ", bottom = " + root.bottomGap +
            ", left = "   + root.leftGap   + " } } })"])
    }

    // ── Debounce: merge rapid setting changes into one call ─────────────
    Timer {
        id: debounce
        interval: 150
        repeat: false
        onTriggered: root.exec()
    }

    // ── Startup retries: Hyprland may not be ready immediately ───────────
    // Fires at +500ms, +1000ms, +1500ms after launch
    Timer {
        id: startupRetry
        interval: 500
        repeat: true
        property int count: 0
        onTriggered: {
            root.exec()
            count++
            if (count >= 3) stop()
        }
    }

    Component.onCompleted: {
        root.exec()
        startupRetry.start()
    }

    // ── Reactive triggers ────────────────────────────────────────────────
    onRightGapChanged:  debounce.restart()
    onBottomGapChanged: debounce.restart()
    onLeftGapChanged:   debounce.restart()
}
