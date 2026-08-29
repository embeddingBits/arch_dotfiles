import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.utils
import qs.modules.components.Bar
import qs.modules.settings
import qs.modules.components.AppLauncher
import qs.modules.components.ToolsWidget
import qs.modules.components.Setting
import qs.modules.components.Notification
import qs.modules.components.Dock
import qs.modules.components.Osd
import qs.modules.components.Widgets
import qs.modules.services
import qs.modules.customComponents

PanelWindow{
    id: layout
    color: "transparent"
    // Per Quickshell PanelWindow docs (https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/):
    // exclusiveZone only takes effect with 1 or 3 anchors. Using top+left+right (3 anchors)
    // with exclusiveZone reserves the bar strip so tiled windows don't render underneath.
    // Previous config used 4 anchors (full-screen) which disabled the exclusive zone — causing overlap.
    // implicitHeight is set to screen height so expanded panels (dashboard/weather/AI) can draw
    // as overlay without being clipped, while exclusiveZone stays at barHeight so only the bar pushes windows.
    anchors{
        top: true
        left: true
        right: true
    }
    implicitHeight: layout.screen ? layout.screen.height : Appearance.size.barHeight

    // Reserve barHeight (+ pill floating margin + user gapTop) at the top edge
    exclusiveZone: {
        let zone = Appearance.size.barHeight
        // pill mode floats with a margin + 10px breathing room (mirrors ServiceGaps.topAuto)
        const m = SettingsConfig.general.pillMargin ?? 6
        const isPill = (SettingsConfig.general.barMode ?? "flat") === "pill"
        if (isPill) zone += Math.round(m) + 10
        zone += SettingsConfig.general.gapTop ?? 0
        return zone
    }

    // true = full bar; false = secondary monitor minimal bar
    property bool isPrimary: true

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.keyboardFocus: isPrimary && workspaces.active
                                 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region{
        item: maskRect;
        intersection: Intersection.Xor;

        // Primary bar clickable regions (zeroed out on secondary monitors)
        Region{
            x: sectionsRow.x + workspaces.x;
            y: sectionsRow.y + workspaces.y;
            width:  isPrimary ? workspaces.width  : 0
            height: isPrimary ? workspaces.height : 0
            intersection: Intersection.Subtract
        }
        Region{
            x: sectionsRow.x + utility.x
            y: sectionsRow.y + utility.y
            width:  isPrimary ? utility.container.width  : 0
            height: isPrimary ? utility.container.height : 0
            intersection: Intersection.Subtract
        }
        Region{
            x: sectionsRow.x + clock.x
            y: sectionsRow.y + clock.y
            width:  isPrimary ? clock.width  : 0
            height: isPrimary ? clock.height : 0
            intersection: Intersection.Subtract
        }

        // Secondary bar strip (full-width top strip on secondary monitors)
        Region{
            x: 0; y: 0
            width:  isPrimary ? 0 : layout.width
            height: isPrimary ? 0 : Appearance.size.barHeight
            intersection: Intersection.Subtract
        }

        // Pill floating panels (dashboard / weather)
        Region {
            x:      pillDashPanel.x
            y:      pillDashPanel.y
            width:  pillDashPanel.visible ? pillDashPanel.width  : 0
            height: pillDashPanel.visible ? pillDashPanel.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x:      pillWeatherPanel.x
            y:      pillWeatherPanel.y
            width:  pillWeatherPanel.visible ? pillWeatherPanel.width  : 0
            height: pillWeatherPanel.visible ? pillWeatherPanel.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x:      pillVpnPanel.x
            y:      pillVpnPanel.y
            width:  pillVpnPanel.visible ? pillVpnPanel.width  : 0
            height: pillVpnPanel.visible ? pillVpnPanel.height : 0
            intersection: Intersection.Subtract
        }

        Region {
            x:      notifPopups.x
            y:      notifPopups.y
            width:  (isPrimary && notifPopups.height > 0) ? notifPopups.width : 0
            height: isPrimary ? notifPopups.height : 0
            intersection: Intersection.Subtract
        }
    }
    Rectangle{
        id: maskRect
        implicitHeight: parent.height
        implicitWidth: parent.width
        anchors.bottom: parent.bottom
        color: "transparent"
    }

    // ── Secondary bar (shown on non-primary monitors) ──────────────────────
    SecondaryBar {
        visible: !isPrimary
    }

    Item{
        id: root
        anchors.fill: parent
        visible: isPrimary
        property real disX: 18
        property real disY: 18
        property real radX: 18
        property real radY: 18
        property real lineDis: 4
        property real clockHeight: 0
        property real clockWidth: clock.width
        property real workspaceWidth: 100
        property real utilityWidth: 100
        property string barMode: SettingsConfig.general.barMode
                                  ?? (SettingsConfig.general.flatBarMode === false ? "stepped" : "flat")
        property real pillMargin:      SettingsConfig.general.pillMargin      ?? 6
        property real pillLeftMargin:  SettingsConfig.general.pillLeftMargin  ?? 6
        property real pillRightMargin: SettingsConfig.general.pillRightMargin ?? 6

        // ── Flat bar path ───────────────────────────────────────────────────────
        // Truly flat bar (no stepped bridges). Sections expand downward when open:
        //   • clock expands when calendar is open (cH > wH)
        //   • utility expands when dashboard/panel is open (uH > wH)
        function buildFlatBarPath(dX, dY, rX, rY,
                                  wH, wW, showArc, wpH, atBottom,
                                  cX, cW, cH,
                                  uX, uW, uH, uAtBottom) {
            function A(sw, ex, ey) { return `A ${rX} ${rY} 0 0 ${sw} ${ex} ${ey} ` }
            function L(x,  y)      { return `L ${x} ${y} ` }
            const CW = 1, CCW = 0

            const wBlockH = showArc ? wpH : wH

            let p  = `M 0 ${wBlockH + dY} `
            p += A(CW, dX, wBlockH)   // screen-edge flare, same at every height
            if (showArc) {
                // Landed on the screen bottom: the edge overshoots and flares back
                // up so the block merges into it, mirroring the dashboard's
                // corner on the utility side. Still growing: a plain rounded corner.
                p += atBottom ? L(wW + dX, wpH) : L(wW - dX, wpH)
                p += atBottom ? A(CW,  wW, wpH - dY)
                              : A(CCW, wW, wpH - dY)
                p += L(wW,           wH + dY)
                p += A(CW,  wW + dX, wH)
            }

            // Clock section — expand downward if calendar is open, else flat
            if (cH > wH + 2 * dY) {
                p += L(cX - dX, wH)
                p += A(CW,  cX,            wH + dY)   // outer corner going down
                p += L(cX,                 cH - dY)   // clock left wall
                p += A(CCW, cX + dX,       cH)        // clock BL corner
                p += L(cX + cW - dX,       cH)        // clock bottom
                p += A(CCW, cX + cW,       cH - dY)   // clock BR corner
                p += L(cX + cW,            wH + dY)   // clock right wall (up)
                p += A(CW,  cX + cW + dX,  wH)        // outer corner back to flat
            }
            // else: bar is flat through the clock area — no scallop

            // Utility section — expand downward if dashboard/panel is open
            if (uH > wH + 2 * dY) {
                p += L(uX - dX, wH)
                p += A(CW,  uX,      wH + dY)   // outer corner going down
                p += L(uX,           uH - dY)   // utility left wall
                p += uAtBottom ? A(CW,  uX - dX, uH)   // merges into the screen bottom
                               : A(CCW, uX + dX, uH)   // still growing
                p += L(uX + uW - dX, uH)
                p += A(CW,  uX + uW, uH + dY)
            } else {
                p += L(uX + uW - dX, wH)
                p += A(CW,  uX + uW, wH + dY)
            }

            p += L(uX + uW, 0)
            p += L(0, 0)
            p += L(0, wBlockH + dY)
            return p
        }

        // ── Stepped bar path ────────────────────────────────────────────────────
        // Builds the bar SVG path. Transition arcs between sections use (disY - lineDis)
        // as their vertical offset. When lineDis == disY the offset is 0 and those arcs
        // would bulge as semicircles; this function emits a straight L segment instead.
        function buildBarPath(dX, dY, rX, rY, lD,
                              wH, wW, showArc, wpH, atBottom,
                              cX, cW, cH,
                              uX, uW, uH, uAtBottom) {
            const eD = dY - lD  // effectiveDis: 0 = flat bar, dY = maximum step

            function A(sw, ex, ey) { return `A ${rX} ${rY} 0 0 ${sw} ${ex} ${ey} ` }
            function L(x,  y)      { return `L ${x} ${y} ` }
            // Transition: flat line when eD ≈ 0, proper arc otherwise
            function T(sw, ex, ey) { return eD < 0.1 ? L(ex, ey) : A(sw, ex, ey) }
            const CW = 1, CCW = 0

            const wBlockH = showArc ? wpH : wH

            let p = `M 0 ${wBlockH + dY} `
            // bottom-left corner — screen-edge flare, same at every height
            p += A(CW, dX, wBlockH)
            // workspaces bottom edge + right-bottom corner. Only flares once the
            // block has landed on the screen bottom, so the curve opens into the
            // edge instead of hanging in mid-air while it grows.
            p += atBottom ? L(wW + dX, wBlockH) : L(wW - dX, wBlockH)
            p += atBottom ? A(CW,  wW, wBlockH - dY)
                          : A(CCW, wW, wBlockH - dY)
            // workspaces right wall up to transition point
            p += L(wW, dY)
            // ── TRANSITION: workspace → bridge
            p += T(CW, wW + dX, lD)
            // bridge across to clock
            p += L(cX - dX, lD)
            // ── TRANSITION: bridge → clock left
            p += T(CW, cX, dY)
            // clock left wall + bottom corners + bottom edge + right wall
            p += L(cX, cH - dY)
            p += A(CCW, cX + dX, cH)
            p += L(cX + cW - dX, cH)
            p += A(CCW, cX + cW, cH - dY)
            p += L(cX + cW, dY)
            // ── TRANSITION: clock → bridge
            p += T(CW, cX + cW + dX, lD)
            // bridge across to utility
            p += L(uX - dX, lD)
            // ── TRANSITION: bridge → utility left
            p += T(CW, uX, dY)
            // utility left wall + bottom corners + bottom edge + right-bottom corner
            p += L(uX, uH - dY)
            p += uAtBottom ? A(CW,  uX - dX, uH)   // merges into the screen bottom
                           : A(CCW, uX + dX, uH)   // still growing
            p += L(uX + uW - dX, uH)
            p += A(CW, uX + uW, uH + dY)
            // utility right wall up, top edge, left wall back to start
            p += L(uX + uW, 0)
            p += L(0, 0)
            p += L(0, wBlockH + dY)
            return p
        }

        // ── Pill bar path ────────────────────────────────────────────────────
        // Single floating pill — same structure as buildFlatBarPath but:
        //   • all y coords offset by margin (so the bar floats)
        //   • left/right ends use full pill caps (capR = wH/2) instead of rX corners
        // Clock/utility expansion works identically to flat mode.
        // xOff = sectionsRow.x — all section x coords are relative to sectionsRow,
        // but the Shape is drawn in root space, so every x needs this offset.
        function buildPillBarPath(dX, dY, rX, rY, margin, xOff,
                                  wH, wW, showArc, wpH,
                                  cX, cW, cH,
                                  uX, uW, uH, uAtBottom) {
            function A(sw, ex, ey) { return `A ${rX} ${rY} 0 0 ${sw} ${ex} ${ey} ` }
            function L(x,  y)      { return `L ${x} ${y} ` }
            const CW = 1, CCW = 0
            const capR = wH / 2
            // All section x values are in sectionsRow-space; shift to root space
            cX += xOff;  uX += xOff
            const right = uX + uW

            let p = `M ${xOff + capR} ${margin + (showArc ? wpH : wH)} `

            if (showArc) {
                p += L(xOff + wW - dX,      margin + wpH)
                p += A(CCW, xOff + wW,      margin + wpH - dY)
                p += L(xOff + wW,           margin + wH + dY)
                p += A(CW,  xOff + wW + dX, margin + wH)
            }

            if (cH > wH + 2 * dY) {
                p += L(cX - dX,            margin + wH)
                p += A(CW,  cX,            margin + wH + dY)
                p += L(cX,                 margin + cH - dY)
                p += A(CCW, cX + dX,       margin + cH)
                p += L(cX + cW - dX,       margin + cH)
                p += A(CCW, cX + cW,       margin + cH - dY)
                p += L(cX + cW,            margin + wH + dY)
                p += A(CW,  cX + cW + dX,  margin + wH)
            }

            if (uH > wH + 2 * dY) {
                p += L(uX - dX, margin + wH)
                p += A(CW,  uX, margin + wH + dY)
                p += L(uX,  margin + uH - dY)
                p += uAtBottom ? A(CW,  uX - dX, margin + uH)
                               : A(CCW, uX + dX, margin + uH)
                p += L(right - dX, margin + uH)
                p += A(CW, right, margin + uH + dY)
                p += L(right, margin + capR)
            } else {
                p += L(right - capR, margin + wH)
            }

            // Right pill cap — CCW sweep (bottom→rightmost→top, bulges outward)
            p += `A ${capR} ${capR} 0 0 0 ${right - capR} ${margin} `

            if (showArc) {
                p += L(xOff + dX, margin)
                p += A(CCW, xOff,      margin + dY)
                p += L(xOff,           margin + wpH - dY)
                p += A(CCW, xOff + dX, margin + wpH)
                p += L(xOff + capR,    margin + wpH)
            } else {
                // Top edge right-to-left
                p += L(xOff + capR, margin)
                // Left pill cap — CCW sweep (top→leftmost→bottom, bulges outward)
                p += `A ${capR} ${capR} 0 0 0 ${xOff + capR} ${margin + wH} `
            }
            p += `Z `
            return p
        }

        Shape{
            preferredRendererType: Shape.CurveRenderer
            ShapePath{
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Colors.surface
                PathSvg {
                    path: root.barMode === "pill"
                        ? root.buildPillBarPath(
                            root.disX, root.disY, root.radX, root.radY, root.pillMargin, sectionsRow.x,
                            Appearance.size.barHeight, workspaces.width, workspaces.showArc, workspaces.height,
                            clock.x, clock.width, clock.height,
                            utility.x, utility.width, utility.height, utility.atScreenBottom)
                        : root.barMode === "stepped"
                            ? root.buildBarPath(
                                root.disX, root.disY, root.radX, root.radY, root.lineDis,
                                Appearance.size.barHeight, workspaces.width, workspaces.showArc, workspaces.height, workspaces.atScreenBottom,
                                clock.x, clock.width, clock.height,
                                utility.x, utility.width, utility.height, utility.atScreenBottom)
                            : root.buildFlatBarPath(
                                root.disX, root.disY, root.radX, root.radY,
                                Appearance.size.barHeight, workspaces.width, workspaces.showArc, workspaces.height, workspaces.atScreenBottom,
                                clock.x, clock.width, clock.height,
                                utility.x, utility.width, utility.height, utility.atScreenBottom)
                }
            }
        }

        Item {
            id: sectionsRow
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin:   root.barMode === "pill" ? root.pillMargin      : 0
            anchors.leftMargin:  root.barMode === "pill" ? root.pillLeftMargin  : 0
            anchors.rightMargin: root.barMode === "pill" ? root.pillRightMargin : 0

            Behavior on anchors.topMargin   { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }
            Behavior on anchors.leftMargin  { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }

            Workspaces{
                id: workspaces
            }

            Clock{
                id: clock
            }

            Utility{
                id: utility
            }
        }

        // ── Pill dashboard panel ──────────────────────────────────────────
        // Floats below the pill bar as an independent rectangle; the pill
        // SVG shape stays compact because utility never enters dashboard state.
        Rectangle {
            id: pillDashPanel
            visible: isPrimary && root.barMode === "pill" && utility.isClicked

            x:      parent.width - width - root.pillRightMargin
            y:      root.pillMargin + Appearance.size.barHeight + 8
            width:  300
            height: parent.height - y - root.pillMargin - 8
            radius: 20
            color:  Colors.surface
            clip:   true

            opacity: 0
            property real _slideX: 340
            transform: Translate { x: pillDashPanel._slideX }

            NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;  running: pillDashPanel.visible }
            NumberAnimation on _slideX { from: 340; to: 0; duration: 300; easing.type: Easing.OutCubic; running: pillDashPanel.visible }

            Loader {
                id: pillDashLoader
                anchors.fill: parent
                active:  pillDashPanel.visible
                visible: false
                Timer {
                    interval: 250
                    running:  pillDashPanel.visible
                    onTriggered: pillDashLoader.visible = true
                }
                sourceComponent: Dashboard {
                    onToggleDashboard: utility.isClicked = false
                }
            }
        }

        // ── Pill weather panel ────────────────────────────────────────────
        Rectangle {
            id: pillWeatherPanel
            visible: isPrimary && root.barMode === "pill" && utility.isWeatherPanelClicked

            x:      parent.width - width - root.pillRightMargin
            y:      root.pillMargin + Appearance.size.barHeight + 8
            width:  Appearance.size.weatherPanelWidth
            height: parent.height - y - root.pillMargin - 8
            radius: 20
            color:  Colors.surface
            clip:   true

            opacity: 0
            property real _slideX: Appearance.size.weatherPanelWidth + 20
            transform: Translate { x: pillWeatherPanel._slideX }

            NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: pillWeatherPanel.visible }
            NumberAnimation on _slideX { from: Appearance.size.weatherPanelWidth + 20; to: 0; duration: 300; easing.type: Easing.OutCubic; running: pillWeatherPanel.visible }

            Loader {
                id: pillWeatherLoader
                anchors.fill: parent
                active:  pillWeatherPanel.visible
                visible: false
                Timer {
                    interval: 250
                    running:  pillWeatherPanel.visible
                    onTriggered: pillWeatherLoader.visible = true
                }
                sourceComponent: WeatherPanel {
                    compact: true
                    onClosed: utility.isWeatherPanelClicked = false
                }
            }
        }

        // ── Pill VPN panel ─────────────────────────────────────────────────
        Rectangle {
            id: pillVpnPanel
            visible: isPrimary && root.barMode === "pill" && utility.isVpnPanelClicked

            x:      parent.width - width - root.pillRightMargin
            y:      root.pillMargin + Appearance.size.barHeight + 8
            width:  pillVpnLoader.item ? pillVpnLoader.item.implicitWidth  : Appearance.size.vpnPanelWidth
            height: pillVpnLoader.item ? pillVpnLoader.item.implicitHeight : 0
            radius: 20
            color:  Colors.surface
            clip:   true

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            opacity: 0
            property real _slideX: Appearance.size.vpnPanelWidth + 20
            transform: Translate { x: pillVpnPanel._slideX }

            NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: pillVpnPanel.visible }
            NumberAnimation on _slideX { from: Appearance.size.vpnPanelWidth + 20; to: 0; duration: 300; easing.type: Easing.OutCubic; running: pillVpnPanel.visible }

            Loader {
                id: pillVpnLoader
                active:  pillVpnPanel.visible
                visible: false
                Timer {
                    interval: 250
                    running:  pillVpnPanel.visible
                    onTriggered: pillVpnLoader.visible = true
                }
                sourceComponent: VpnPanel {
                    onClosed: utility.isVpnPanelClicked = false
                }
            }
        }
    }

    property bool isToolsWidgetClicked: false
    property bool isSettingClicked: false
    property bool showOsd: false

    GlobalShortcut{
        name: "toolsWidget"
        onPressed:{
            if(Hyprland.focusedMonitor.name === layout.screen.name){
                layout.isToolsWidgetClicked = !layout.isToolsWidgetClicked 
            }
        }
    }

    NotificationPanel{
        id: notifPopups
        visible: isPrimary
    }

    // Ensure ServiceGaps singleton initializes (side/bottom gaps via hyprctl)
    readonly property int _gapsInit: ServiceGaps.leftGap
}
