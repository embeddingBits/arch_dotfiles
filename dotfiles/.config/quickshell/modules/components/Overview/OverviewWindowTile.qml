import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// One window in the overview: a live capture of the window itself plus a footer
// carrying the app icon and title.
//
// The capture is the point — with three terminals open, an icon grid tells you
// nothing about which is which, and the title alone is often just "zsh".
Rectangle {
    id: root

    // HyprlandToplevel. `.wayland` is the handle ScreencopyView captures from.
    required property var toplevel

    signal activateRequested()
    signal dragStarted(real globalX, real globalY)
    signal dragMoved(real globalX, real globalY)
    signal dragEnded()

    readonly property string appId: root.toplevel?.wayland?.appId ?? root.toplevel?.app_id ?? root.toplevel?.appId ?? ""
    readonly property string title: root.toplevel?.title ?? ""
    readonly property bool isActive: root.toplevel?.activated ?? root.toplevel?.is_focused ?? false
    readonly property bool isUrgent: root.toplevel?.urgent ?? root.toplevel?.is_urgent ?? false

    // Set by the card while this tile's ghost is in flight
    property bool dragging: false

    radius: 12
    color: Colors.surfaceContainerHigh
    clip: true
    opacity: root.dragging ? 0.35 : 1
    Behavior on opacity { NumberAnimation { duration: 140 } }

    border.width: root.isActive || root.isUrgent ? 2 : 1
    border.color: root.isUrgent ? Colors.error
                : root.isActive ? Colors.primary
                : Qt.alpha(Colors.outline, 0.18)
    Behavior on border.color { ColorAnimation { duration: 160 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        // ── Live capture ──────────────────────────────────────────────
        Item {
            id: captureSlot
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScreencopyView {
                id: capture
                anchors.fill: parent
                anchors.margins: 3
                captureSource: root.toplevel?.wayland ?? null
                live: true
                paintCursor: false
                // Sized off the slot, not off the view itself — the view's own
                // width comes from these anchors, and feeding that back in is a
                // loop waiting to happen.
                constraintSize: Qt.size(captureSlot.width, captureSlot.height)
            }

            // Until the first frame lands, a bare surface colour reads as a
            // broken tile; the app icon at least identifies it.
            Image {
                anchors.centerIn: parent
                width: 34
                height: 34
                visible: !capture.hasContent
                source: Quickshell.iconPath(
                    DesktopEntries.heuristicLookup(root.appId)?.icon, "image-missing")
                sourceSize: Qt.size(34, 34)
                fillMode: Image.PreserveAspectFit
            }
        }

        // ── Footer ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 6
            Layout.topMargin: 2
            spacing: 6

            Image {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: Quickshell.iconPath(
                    DesktopEntries.heuristicLookup(root.appId)?.icon, "image-missing")
                sourceSize: Qt.size(14, 14)
                fillMode: Image.PreserveAspectFit
            }

            CustomText {
                Layout.fillWidth: true
                content: root.title !== "" ? root.title : root.appId
                size: 10
                weight: 600
                elide: Text.ElideRight
                customColor: root.isActive ? Colors.primary : Colors.surfaceText
            }
        }
    }

    CustomToolTip {
        content: root.title
        visible: hoverArea.containsMouse && root.title !== ""
    }

    // ── Click to focus, press-and-drag to move ────────────────────────
    // Drag is reported in window coordinates and the ghost is drawn by the
    // overview: a ScreencopyView reparented mid-drag drops its capture context,
    // so the thing that follows the cursor is a cheap stand-in, not this tile.
    //
    // Sits above the content on purpose. ScreencopyView is a live scene-graph
    // item covering nearly the whole tile, and anything it does with mouse
    // events would otherwise eat the press before the drag could arm.
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        z: 20
        hoverEnabled: true
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true

        property point pressPos: Qt.point(0, 0)
        property bool armed: false

        readonly property int threshold: 6

        function toWindow(mx, my) {
            return root.mapToItem(null, mx, my)
        }

        onPressed: e => {
            pressPos = Qt.point(e.x, e.y)
            armed = true
        }

        onPositionChanged: e => {
            if (!armed) return
            if (!root.dragging) {
                const dx = e.x - pressPos.x
                const dy = e.y - pressPos.y
                if (dx * dx + dy * dy < threshold * threshold) return
                const p = toWindow(e.x, e.y)
                root.dragStarted(p.x, p.y)
            } else {
                const p = toWindow(e.x, e.y)
                root.dragMoved(p.x, p.y)
            }
        }

        onReleased: {
            armed = false
            if (root.dragging) root.dragEnded()
            else root.activateRequested()
        }

        onCanceled: {
            armed = false
            if (root.dragging) root.dragEnded()
        }
    }

    // ── Close ─────────────────────────────────────────────────────────
    // Floated over the capture rather than sitting in the footer row, so it can
    // out-rank the drag handler above without the footer having to.
    Rectangle {
        id: closeButton
        z: 30
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 5
        width: 20
        height: 20
        radius: 10
        color: closeArea.containsMouse ? Colors.errorContainer
                                       : Qt.alpha(Colors.surface, 0.85)
        opacity: (hoverArea.containsMouse || closeArea.containsMouse) && !root.dragging ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 130 } }
        Behavior on color   { ColorAnimation  { duration: 130 } }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: "close"
            iconSize: 13
            customColor: closeArea.containsMouse ? Colors.errorContainerText : Colors.outline
        }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.toplevel?._niriId !== undefined) {
                    // Synthetic niri window – close via niri IPC
                    var nw = root.toplevel
                    // Try ServiceNiri
                    if (typeof ServiceNiri !== "undefined" && ServiceNiri.closeWindow) ServiceNiri.closeWindow(nw._niriId)
                } else {
                    root.toplevel?.wayland?.close()
                }
            }
        }
    }
}
