pragma Singleton

import Quickshell
import QtQuick

// Standard desktop-widget footprints.
//
// Widths and heights both come off a single 60px ladder, so every tile lines
// up on a shared grid instead of each widget inventing its own size. Pick the
// nearest named tile rather than a one-off number — mismatched sizes are what
// made the desktop look ragged (a 200x200 battery beside a 195x185 date card
// reads as a mistake even though the difference is only a few pixels).
Singleton {
    id: root

    // Ladder steps
    readonly property int xs: 80
    readonly property int sm: 140
    readonly property int md: 200
    readonly property int lg: 260
    readonly property int xl: 320

    // Gap to leave between neighbouring tiles when placing them
    readonly property int gutter: 20

    // Shared corner radius, so tiles read as one family
    readonly property int radius: 24

    // ── Named tiles ───────────────────────────────────────────────────
    readonly property size small: Qt.size(md, md)   // 200 x 200 — square
    readonly property size wide:  Qt.size(xl, md)   // 320 x 200 — landscape
    readonly property size strip: Qt.size(xl, sm)   // 320 x 140 — short banner
    readonly property size tall:  Qt.size(md, xl)   // 200 x 320 — portrait
    readonly property size large: Qt.size(xl, xl)   // 320 x 320 — big
}
