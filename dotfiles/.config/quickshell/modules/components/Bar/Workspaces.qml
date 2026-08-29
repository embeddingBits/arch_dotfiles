import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import Quickshell.Wayland
import Quickshell.Widgets

Item{
    id: root

    readonly property bool isPill: ServiceGaps.isPill

    readonly property bool showArc: !isPill && height > Appearance.size.barHeight + 2

    readonly property real collapsedWidth: outerRow.implicitWidth + 20

    readonly property int wsCount:    SettingsConfig.general.workspaceCount ?? 5
    readonly property bool wsNumbers: SettingsConfig.general.showWorkspaceNumbers ?? false
    readonly property bool perMonitorMode: SettingsConfig.general.perMonitorWorkspaces ?? false

    // Niri: count occupied workspaces on other outputs
    readonly property int otherOccupied: {
        if (!perMonitorMode) return 0
        var count = 0
        var all = ServiceNiri.allWorkspaces
        for (var i = 0; i < all.length; i++) {
            var ws = all[i]
            if (ws.output !== layout.screen.name) {
                // check if workspace has any windows
                var wins = ServiceNiri.getNiriWindowsForWorkspace(ws.idx, ws.output)
                if (wins.length > 0) count++
            }
        }
        return count
    }

    // Active workspace idx for this monitor (niri is_active per output)
    readonly property int activeWsIdx: {
        var all = ServiceNiri.allWorkspaces
        for (var i = 0; i < all.length; i++) {
            var ws = all[i]
            if (ws.output === layout.screen.name && ws.is_active) return ws.idx
        }
        // fallback to focused workspace if no active found (single monitor case)
        for (var j = 0; j < all.length; j++) {
            if (all[j].is_focused) return all[j].idx
        }
        return -1
    }

    // Keyboard focus sits on some other monitor (niri focused workspace output != this screen)
    readonly property bool otherFocused: {
        if (!perMonitorMode) return false
        var focused = null
        var all = ServiceNiri.allWorkspaces
        for (var i = 0; i < all.length; i++) if (all[i].is_focused) { focused = all[i]; break }
        if (!focused) return false
        return (focused.output ?? layout.screen.name) !== layout.screen.name
    }

    readonly property int monitorCount: {
        var outs = ServiceNiri.outputs
        var n = Object.keys(outs).length
        if (n > 0) return n
        return Quickshell.screens.length
    }
    readonly property bool showOtherIndicator: perMonitorMode && monitorCount > 1
    readonly property bool atScreenBottom: showArc && height >= (layout.height - (ServiceGaps.isPill ? ServiceGaps.pillMargin*2 : 0)) - 2

    implicitWidth:  collapsedWidth
    implicitHeight: 40

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.duration.normal
            easing.type: Easing.OutQuad
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.duration.normal
            easing.type: Easing.OutQuad
        }
    }

    RowLayout{
        id: outerRow
        anchors.left: parent.left
        anchors.leftMargin: 10
        y: (40 - height) / 2
        spacing: 5
        Rectangle{
            Layout.preferredWidth: row.implicitWidth + 6
            Layout.preferredHeight: 30
            radius: 15
            color: Colors.surfaceContainer
            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: ScriptModel {
                        values: Array.from({ length: root.wsCount }, (_, i) => i + 1)
                    }

                    delegate: Rectangle {
                        property int workspaceId: modelData
                        // Niri workspace for this screen + idx
                        property var niriWorkspace: ServiceNiri.getWorkspaceByIdx(workspaceId, layout.screen.name)
                        // Fallback for global mode: any workspace with that idx
                        property var fallbackWorkspace: niriWorkspace ?? ServiceWorkspaces.getWorkspace(workspaceId)
                        property var currentWorkspace: niriWorkspace ?? fallbackWorkspace
                        // Occupied means there is at least one window on that workspace (niri always has empty ws object)
                        readonly property var niriWindows: ServiceNiri.getNiriWindowsForWorkspace(workspaceId, layout.screen.name)
                        readonly property bool isOccupied: niriWindows.length > 0
                        readonly property bool showNumbers: root.wsNumbers

                        // For niri, onOtherMonitor only relevant in global (non-perMonitor) mode:
                        // if the workspace we resolved lives on another output, dim it.
                        readonly property bool onOtherMonitor: !root.perMonitorMode
                            && !!currentWorkspace
                            && !!currentWorkspace.output
                            && currentWorkspace.output !== layout.screen.name

                        readonly property bool occupiedHere: isOccupied && !onOtherMonitor

                        readonly property bool isActive: !onOtherMonitor && (root.perMonitorMode
                            ? workspaceId === root.activeWsIdx
                            : (!!currentWorkspace && currentWorkspace.is_focused))

                        visible: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 25
                        Layout.preferredWidth: occupiedHere
                            ? Math.max(25, (topLevels.appList?.width ?? 0) + 12)
                            : 25
                        radius: 15
                        color: isActive     ? Colors.primary
                             : occupiedHere ? Colors.surfaceContainerHighest
                                            : "transparent"

                        border.width: (occupiedHere && !isActive) || onOtherMonitor ? 1 : 0
                        border.color: onOtherMonitor ? Qt.alpha(Colors.outline, 0.35)
                                                     : Qt.alpha(Colors.outline, 0.15)

                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on Layout.preferredWidth  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on color                  { ColorAnimation  { duration: 200 } }

                        Rectangle{
                            visible: !occupiedHere
                            implicitWidth: 5
                            implicitHeight: 5
                            color: onOtherMonitor ? Qt.alpha(Colors.outline, 0.45) : Colors.outline
                            radius: width / 2
                            anchors.centerIn: parent
                        }

                        Loader {
                            id: topLevels
                            anchors.fill: parent
                            active: occupiedHere && !showNumbers
                            visible: active
                            sourceComponent: TopLevels {}
                            property var appList: item ? item.appList : null
                        }

                        CustomText {
                            anchors.centerIn: parent
                            visible: showNumbers && occupiedHere
                            content: workspaceId.toString()
                            size: 10
                            weight: isActive ? 800 : 600
                            customColor: isActive ? Colors.primaryText : Colors.surfaceText
                            Behavior on customColor { ColorAnimation { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Niri: focus workspace idx on this output
                                ServiceNiri.focusWorkspaceByIdx(workspaceId)
                            }
                        }
                    }
                }

                // Other-monitors indicator. Presence is keyed off the monitor count,
                // not the other monitor's workspace count: Hyprland destroys a
                // workspace as soon as you leave it empty, so counting workspaces
                // made this pill appear and vanish — resizing the centred row on
                // this bar every time the *other* monitor changed workspace.
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: root.showOtherIndicator ? 25 : 0
                    opacity: root.showOtherIndicator ? 1 : 0
                    visible: Layout.preferredWidth > 0
                    radius: 12
                    color: root.otherFocused ? Colors.primary : "transparent"
                    border.width: root.otherFocused ? 0 : 1
                    border.color: Qt.alpha(Colors.outline, 0.35)

                    Behavior on color                 { ColorAnimation  { duration: 200 } }
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity               { NumberAnimation { duration: 180 } }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "tv_displays"
                        iconSize: 12
                        customColor: root.otherFocused ? Colors.primaryText : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }

                    CustomToolTip {
                        content: root.otherOccupied + " workspace" + (root.otherOccupied !== 1 ? "s" : "") + " on other monitor" + (root.otherFocused ? " — focused" : "")
                        visible: otherMonHov.containsMouse
                    }
                    MouseArea { id: otherMonHov; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
        Rectangle {
            Layout.leftMargin: 10
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Colors.surfaceContainer

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: ToplevelManager.activeToplevel ? "ad" : "desktop_windows"
                iconSize: 18
                customColor: Colors.surfaceText
                Behavior on customColor { ColorAnimation { duration: 150 } }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth:  titleCol.implicitWidth
            Layout.preferredHeight: titleCol.implicitHeight

            Item {
                clip: true
                height: parent.height
                width: Math.max(0, parent.width
                    - Math.max(0, root.collapsedWidth - root.implicitWidth))

                ColumnLayout {
                    id: titleCol
                    width: implicitWidth
                    spacing: 0

                    CustomText {
                        Layout.maximumWidth: 200
                        content: ToplevelManager.activeToplevel
                                 ? (ToplevelManager.activeToplevel.appId ?? "")
                                 : "Desktop"
                        size: 10
                        weight: 700
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                    CustomText {
                        Layout.maximumWidth: 200
                        content: ToplevelManager.activeToplevel
                                 ? (ToplevelManager.activeToplevel.title ?? "")
                                 : "Workspace " + (root.activeWsIdx > 0 ? root.activeWsIdx : (ServiceNiri.focusedWorkspaceId ?? ""))

                        size: 13
                        weight: 800
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

}
