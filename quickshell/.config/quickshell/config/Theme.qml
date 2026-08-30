pragma Singleton

import QtQuick
import Quickshell

QtObject {
    // ── Core palette ──
    readonly property color bg: "#1d2021"
    readonly property color fg: "#ebdbb2"
    readonly property color accent: "#d79221"
    readonly property color border: "#d79221"
    readonly property color borderMuted: "#504945"
    readonly property color hover: "#3c3836"
    readonly property color muted: "#928374"

    // Aliases for backwards-compat / readability
    readonly property color colBg: bg
    readonly property color colFg: fg
    readonly property color colAccent: accent
    readonly property color colBorder: border
    readonly property color colBorderMuted: borderMuted
    readonly property color colHover: hover
    readonly property color colMuted: muted

    // ── Underline colors per bar element ──
    readonly property color underlineMenu: "#fabd2f"
    readonly property color underlineActiveWindow: "#d5c4a1"
    readonly property color underlineWorkspaces: "#fe8019"
    readonly property color underlineClock: "#83a598"
    readonly property color underlineTray: "#a89984"
    readonly property color underlineAudio: "#8ec07c"
    readonly property color underlineMemory: "#689d6a"
    readonly property color underlineNetwork: "#458588"
    readonly property color underlineBluetooth: "#d3869b"
    readonly property color underlineBattery: "#b8bb26"
    readonly property color underlinePower: "#fb4934"
    readonly property color underlineApps: "#b16286"

    // Compatibility aliases
    readonly property color colUnderlineMenu: underlineMenu
    readonly property color colUnderlineActiveWindow: underlineActiveWindow
    readonly property color colUnderlineWorkspaces: underlineWorkspaces
    readonly property color colUnderlineClock: underlineClock
    readonly property color colUnderlineTray: underlineTray
    readonly property color colUnderlineAudio: underlineAudio
    readonly property color colUnderlineMemory: underlineMemory
    readonly property color colUnderlineNetwork: underlineNetwork
    readonly property color colUnderlineBluetooth: underlineBluetooth
    readonly property color colUnderlineBattery: underlineBattery
    readonly property color colUnderlinePower: underlinePower
    readonly property color colUnderlineApps: underlineApps

    // ── Layout ──
    readonly property int barHeight: 38
    readonly property int radius: 0
    readonly property int radiusSmall: 0

    // ── Typography ──
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string fontFamilyFallback: "JetBrainsMono Nerd Font"
    readonly property int barFontSize: 14
    readonly property int clockFontSize: barFontSize
    readonly property int iconFontSize: barFontSize
    readonly property int smallFontSize: barFontSize

    // ── Spacing ──
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 12
    readonly property int barPadding: 8
}
