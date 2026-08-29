pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.settings

// Game mode — one runtime flag the rest of the shell reads to get out of the
// way while a game is running. Toggled from the Appearance settings page; the
// settings panel has its own `quickshell:settingOpen` shortcut, so it stays
// reachable once the bar is hidden.
//
// Deliberately NOT persisted: if the shell restarts mid-game you come back to
// a normal desktop rather than an invisible one with no obvious way out.
Singleton {
    id: root

    property bool active: false

    // Which sub-effects are enabled, from settings
    readonly property bool optHideBar:     SettingsConfig.gameMode?.hideBar     ?? true
    readonly property bool optHideWidgets: SettingsConfig.gameMode?.hideWidgets ?? true
    readonly property bool optDnd:         SettingsConfig.gameMode?.dnd         ?? true
    readonly property bool optHyprPerf:    SettingsConfig.gameMode?.hyprPerf    ?? true

    // What consumers actually bind to
    readonly property bool hideBar:     active && optHideBar
    readonly property bool hideWidgets: active && optHideWidgets
    readonly property bool dndActive:   active && optDnd

    // Toast text — flipped on every transition, consumed by GameModeToast
    property bool toastVisible: false
    property string toastText: ""

    function toggle() { root.active = !root.active }
    function enable()  { root.active = true }
    function disable() { root.active = false }

    // ── Hyprland perf tweaks ────────────────────────────────────────────
    // Applying is a one-liner. Reverting is the hard part: we never knew the
    // user's original blur/animation values, so instead of snapshotting them
    // we `hyprctl reload`, which re-reads hyprland.conf and restores exactly
    // what they configured. That also wipes the gaps ServiceGaps applied, so
    // gaps get re-pushed once the reload has settled.
    function _applyHyprPerf() {
        Quickshell.execDetached(["hyprctl", "eval",
            "hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }," +
            " animations = { enabled = false } })"])
    }

    function _revertHyprPerf() {
        Quickshell.execDetached(["hyprctl", "reload"])
        gapsRestore.restart()
    }

    Timer {
        id: gapsRestore
        interval: 200
        repeat: false
        onTriggered: ServiceGaps.exec()
    }

    onActiveChanged: {
        if (root.active) {
            if (root.optHyprPerf) root._applyHyprPerf()
        } else {
            if (root.optHyprPerf) root._revertHyprPerf()
        }

        root.toastText = root.active ? "Game Mode On" : "Game Mode Off"
        root.toastVisible = true
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1500
        repeat: false
        onTriggered: root.toastVisible = false
    }
}
