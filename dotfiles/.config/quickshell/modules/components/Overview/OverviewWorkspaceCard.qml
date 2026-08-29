import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// One workspace in the overview grid. The whole card is a drop target — the
// overview hit-tests the cursor against the grid and flips `dropTarget` — so a
// window can be dropped on empty card space, not only onto an existing tile.
Rectangle {
    id: root

    // Takes an id, not a HyprlandWorkspace: Hyprland destroys a workspace as soon
    // as it empties, so a card has to be able to exist — and be dropped onto —
    // with nothing behind it. It resolves the live workspace itself.
    required property int wsId

    // The toplevel currently in flight, so its source tile can dim
    property var draggingToplevel: null
    // Set by the overview's hit-test while a drag hovers this card
    property bool dropTarget: false

    signal activateRequested()
    signal windowActivateRequested(var toplevel)
    signal windowDragStarted(var toplevel, real wx, real wy)
    signal windowDragMoved(real wx, real wy)
    signal windowDragEnded()

    // Niri workspace for this idx on the current (focused) output
    readonly property var workspace: ServiceNiri.getWorkspaceByIdx(root.wsId, ServiceNiri.currentOutput) ?? ServiceWorkspaces.getWorkspace(root.wsId)
    readonly property bool isActive: workspace?.is_active ?? workspace?.is_focused ?? workspace?.active ?? false
    // Prefer niri windows count; fallback to Hyprland toplevels count
    readonly property int windowCount: matchedToplevels.length
    readonly property bool empty: root.windowCount === 0
    readonly property string monitorName: workspace?.output ?? workspace?.monitor?.name ?? ServiceNiri.currentOutput ?? ""

    readonly property bool showMonitor:
        root.monitorName !== "" && (Object.keys(ServiceNiri.outputs).length > 1 || Quickshell.screens.length > 1)

    // Matched Wayland toplevels for live captures (niri windows -> Wayland)
    readonly property var matchedToplevels: {
        // Try niri first
        var niriWs = ServiceNiri.getWorkspaceByIdx(root.wsId, ServiceNiri.currentOutput)
        if (niriWs) {
            var niriWins = ServiceNiri.getNiriWindowsForWorkspace(root.wsId, niriWs.output)
            if (niriWins.length === 0) return []
            var allToplevels = ToplevelManager.toplevels ? (ToplevelManager.toplevels.values ?? []) : []
            // Match each niri window to a Wayland toplevel via appId/title heuristic
            var used = {}
            var result = []
            for (var i = 0; i < niriWins.length; i++) {
                var nw = niriWins[i]
                var best = null, bestScore = -1
                for (var j = 0; j < allToplevels.length; j++) {
                    var tl = allToplevels[j]
                    if (used[j]) continue
                    var appId = tl.wayland?.appId ?? tl.appId ?? ""
                    if (appId !== nw.app_id) continue
                    var score = 1
                    var title = tl.title ?? ""
                    if (nw.title && title) {
                        if (title === nw.title) score = 3
                        else if (title.includes(nw.title) || nw.title.includes(title)) score = 2
                    }
                    if (score > bestScore) { bestScore = score; best = tl; if (score === 3) break }
                }
                // fallback: if no appId match, try title-only
                if (!best) {
                    for (var k = 0; k < allToplevels.length; k++) {
                        if (used[k]) continue
                        var tl2 = allToplevels[k]
                        if (nw.title && tl2.title && nw.title === tl2.title) { best = tl2; break }
                    }
                }
                if (best) {
                    // find its index for used tracking
                    for (var u = 0; u < allToplevels.length; u++) if (allToplevels[u] === best) { used[u] = true; break }
                    result.push(best)
                } else {
                    // No Wayland match – create a synthetic toplevel wrapper from niri window so we at least show icon/title
                    result.push({
                        wayland: { appId: nw.app_id ?? "", close: function(){} },
                        title: nw.title ?? "",
                        appId: nw.app_id ?? "",
                        activated: nw.is_focused,
                        // synthetic flag so OverviewWindowTile can handle close via ServiceNiri
                        _niriId: nw.id
                    })
                }
            }
            return result
        }
        // Fallback Hyprland
        if (workspace && workspace.toplevels) {
            return workspace.toplevels.values ?? workspace.toplevels ?? []
        }
        return []
    }

    radius: 14
    color: root.dropTarget ? Qt.alpha(Colors.primary, 0.12)
         : root.isActive         ? Colors.surfaceContainerHigh
                                 : Colors.surfaceContainer
    Behavior on color { ColorAnimation { duration: 160 } }

    border.width: root.dropTarget || root.isActive ? 2 : 1
    border.color: root.dropTarget ? Colors.primary
                : root.isActive         ? Qt.alpha(Colors.primary, 0.55)
                                        : Qt.alpha(Colors.outline, 0.14)
    Behavior on border.color { ColorAnimation { duration: 160 } }

    // Lift towards the cursor on hover-with-payload, so the drop target is
    // obvious without having to read the border
    scale: root.dropTarget ? 1.02 : 1
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    // Click empty card space to jump to the workspace
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activateRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 8
                color: root.isActive ? Colors.primary : Colors.surfaceContainerHighest
                Behavior on color { ColorAnimation { duration: 160 } }

                CustomText {
                    anchors.centerIn: parent
                    content: root.wsId.toString()
                    size: 11
                    weight: 800
                    customColor: root.isActive ? Colors.primaryText : Colors.outline
                    Behavior on customColor { ColorAnimation { duration: 160 } }
                }
            }

            CustomText {
                content: root.windowCount === 0
                    ? "Empty"
                    : root.windowCount + (root.windowCount === 1 ? " window" : " windows")
                size: 11
                weight: 600
                customColor: Colors.outline
            }

            Item { Layout.fillWidth: true }

            // Monitor chip
            Rectangle {
                Layout.preferredHeight: 18
                Layout.preferredWidth: monText.implicitWidth + 14
                radius: 9
                color: Colors.surfaceContainerHighest
                visible: root.showMonitor

                CustomText {
                    id: monText
                    anchors.centerIn: parent
                    content: root.monitorName
                    size: 9
                    weight: 700
                    customColor: Colors.outline
                }
            }
        }

        // ── Windows ───────────────────────────────────────────────────
        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real gap: 6

            // Roughly square grid, then cells stretch to fill whatever is left.
            // A fixed column count wastes half the card at one window and
            // squashes tiles to nothing at six.
            readonly property int cols:
                Math.max(1, Math.ceil(Math.sqrt(Math.max(1, root.windowCount))))
            readonly property int rows:
                Math.max(1, Math.ceil(Math.max(1, root.windowCount) / body.cols))

            readonly property real cellW:
                Math.max(1, (body.width  - (body.cols - 1) * body.gap) / body.cols)
            readonly property real cellH:
                Math.max(1, (body.height - (body.rows - 1) * body.gap) / body.rows)

            // Empty placeholder — also the drop hint
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Colors.outline, 0.25)
                visible: root.empty

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIconSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        content: root.dropTarget ? "move_down" : "web_asset_off"
                        iconSize: 20
                        customColor: root.dropTarget ? Colors.primary : Colors.outline
                    }

                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: root.dropTarget ? "Drop here" : "No windows"
                        size: 10
                        weight: 600
                        customColor: root.dropTarget ? Colors.primary : Colors.outline
                    }
                }
            }

            Grid {
                anchors.fill: parent
                columns: body.cols
                spacing: body.gap
                visible: !root.empty

                Repeater {
                    model: root.matchedToplevels

                    delegate: OverviewWindowTile {
                        required property var modelData
                        toplevel: modelData
                        width: body.cellW
                        height: body.cellH
                        dragging: root.draggingToplevel === modelData

                        onActivateRequested: root.windowActivateRequested(modelData)
                        onDragStarted: (wx, wy) => root.windowDragStarted(modelData, wx, wy)
                        onDragMoved:   (wx, wy) => root.windowDragMoved(wx, wy)
                        onDragEnded:   root.windowDragEnded()
                    }
                }
            }
        }
    }
}
