import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

// Minimal bar for secondary monitors: workspaces | clock | status icons (niri)
Item {
    id: root
    anchors.top:   parent.top
    anchors.left:  parent.left
    anchors.right: parent.right
    height: Appearance.size.barHeight

    readonly property int wsCount:    SettingsConfig.general.workspaceCount ?? 10
    readonly property bool wsNumbers: SettingsConfig.general.showWorkspaceNumbers ?? false
    readonly property bool perMonitorMode: SettingsConfig.general.perMonitorWorkspaces ?? false

    readonly property int otherOccupied: {
        if (!perMonitorMode) return 0
        var count = 0
        var all = ServiceNiri.allWorkspaces
        for (var i = 0; i < all.length; i++) {
            if (all[i].output !== layout.screen.name) {
                var wins = ServiceNiri.getNiriWindowsForWorkspace(all[i].idx, all[i].output)
                if (wins.length > 0) count++
            }
        }
        return count
    }
    readonly property int otherActive: {
        if (!perMonitorMode) return 0
        var count = 0
        var all = ServiceNiri.allWorkspaces
        for (var i = 0; i < all.length; i++) {
            if (all[i].output !== layout.screen.name && all[i].is_active) count++
        }
        return count
    }

    // Bar background — same surface color as the primary bar
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
    }

    RowLayout {
        anchors.fill:       parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 0

        // ── Workspaces ──────────────────────────────────────────────────────
        Rectangle {
            Layout.preferredHeight: 30
            implicitWidth: wsRow.implicitWidth + 6
            radius: 15
            color: Colors.surfaceContainer

            RowLayout {
                id: wsRow
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: ScriptModel {
                        values: Array.from({ length: root.wsCount }, (_, i) => i + 1)
                    }

                    delegate: Rectangle {
                        id: wsItem
                        property int workspaceId: modelData
                        property var niriWs: ServiceNiri.getWorkspaceByIdx(workspaceId, layout.screen.name)
                        property var fallbackWs: niriWs ?? ServiceWorkspaces.getWorkspace(workspaceId)
                        property var currentWorkspace: fallbackWs
                        readonly property var niriWindows: ServiceNiri.getNiriWindowsForWorkspace(workspaceId, layout.screen.name)
                        readonly property bool isOccupied: niriWindows.length > 0
                        readonly property bool isActive: {
                            if (niriWs) return niriWs.is_active
                            // fallback global focused check
                            return !!currentWorkspace && !!currentWorkspace.is_focused
                        }
                        // Per-monitor mode: hide workspaces that belong to other monitors (niri: niriWs null means not on this output)
                        readonly property bool isForThisMonitor: !root.perMonitorMode
                            || !!niriWs

                        visible: isForThisMonitor
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 25
                        Layout.preferredWidth: isForThisMonitor
                            ? (isOccupied ? Math.max(25, (appIcons.appList?.width ?? 0) + 12) : 25)
                            : 0
                        radius: 15
                        color: isActive   ? Colors.primary
                             : isOccupied ? Colors.surfaceContainerHighest
                             : "transparent"
                        border.width: isOccupied && !isActive ? 1 : 0
                        border.color: Qt.alpha(Colors.outline, 0.15)

                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on color                 { ColorAnimation  { duration: 200 } }

                        // Dot for empty workspace
                        Rectangle {
                            visible: !wsItem.isOccupied
                            anchors.centerIn: parent
                            width: 5; height: 5; radius: 3
                            color: Colors.outline
                        }

                        // App icons
                        Loader {
                            id: appIcons
                            anchors.fill: parent
                            active:  wsItem.isOccupied && !root.wsNumbers
                            visible: active
                            sourceComponent: TopLevels {}
                            property var appList: item ? item.appList : null
                        }

                        // Workspace number
                        CustomText {
                            anchors.centerIn: parent
                            visible: root.wsNumbers && wsItem.isOccupied
                            content: wsItem.workspaceId.toString()
                            size: 10; weight: wsItem.isActive ? 800 : 600
                            customColor: wsItem.isActive ? Colors.primaryText : Colors.surfaceText
                            Behavior on customColor { ColorAnimation { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ServiceNiri.focusWorkspaceByIdx(wsItem.workspaceId)
                        }
                    }
                }

                // Other-monitors indicator
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: root.perMonitorMode && root.otherOccupied > 0 ? 25 : 0
                    opacity: root.perMonitorMode && root.otherOccupied > 0 ? 1 : 0
                    visible: Layout.preferredWidth > 0
                    radius: 12
                    color: root.otherActive > 0 ? Colors.primary : "transparent"
                    border.width: root.otherActive > 0 ? 0 : 1
                    border.color: Qt.alpha(Colors.outline, 0.35)

                    Behavior on color                 { ColorAnimation  { duration: 200 } }
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity               { NumberAnimation { duration: 180 } }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "tv_displays"
                        iconSize: 12
                        customColor: root.otherActive > 0 ? Colors.primaryText : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }

                    CustomToolTip {
                        content: root.otherOccupied + " workspace" + (root.otherOccupied !== 1 ? "s" : "") + " on other monitor" + (root.otherActive > 0 ? " (active)" : "")
                        visible: secOtherHov.containsMouse
                    }
                    MouseArea { id: secOtherHov; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Clock ────────────────────────────────────────────────────────────
        ColumnLayout {
            spacing: 0

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.time
                size: 14; weight: 700
                customColor: Colors.surfaceText
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.day + "  " + ServiceClock.date + " " + ServiceClock.month
                size: 10; weight: 400
                customColor: Colors.outline
            }
        }

        Item { Layout.fillWidth: true }

        // ── Status icons: network + battery ─────────────────────────────────
        Rectangle {
            Layout.preferredHeight: 30
            implicitWidth: statusRow.implicitWidth + 8
            radius: 15
            color: Colors.surfaceContainerHigh

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 2

                // Network
                Rectangle {
                    implicitWidth: 28; implicitHeight: 28; radius: 14
                    color: "transparent"
                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content:     ServiceNetwork.icon
                        iconSize:    16
                        customColor: Colors.surfaceText
                    }
                    CustomToolTip {
                        content: ServiceNetwork.connectionLabel.length > 0
                               ? ServiceNetwork.connectionLabel : "No network"
                        visible: netHov.containsMouse
                    }
                    MouseArea { id: netHov; anchors.fill: parent; hoverEnabled: true }
                }

                // Battery
                Rectangle {
                    implicitWidth: 28; implicitHeight: 28; radius: 14
                    color: "transparent"
                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: {
                            if (ServiceUPower.isCharging)  return "battery_android_bolt"
                            const l = ServiceUPower.powerLevel
                            if (l === 1)                   return "battery_android_full"
                            if (l > 0.9)                   return "battery_android_6"
                            if (l > 0.7)                   return "battery_android_5"
                            if (l > 0.5)                   return "battery_android_4"
                            if (l > 0.3)                   return "battery_android_3"
                            if (l > 0.2)                   return "battery_android_2"
                            if (l > 0.0)                   return "battery_android_1"
                            return "battery_android_0"
                        }
                        iconSize: 16
                        customColor: ServiceUPower.powerLevel < 0.2 && !ServiceUPower.isCharging
                                     ? Colors.error : Colors.surfaceText
                        Behavior on customColor { ColorAnimation { duration: 150 } }
                    }
                    CustomToolTip {
                        content: (ServiceUPower.isCharging ? "Charging · " : "")
                               + Math.round(ServiceUPower.powerLevel * 100) + "%"
                        visible: battHov2.containsMouse
                    }
                    MouseArea { id: battHov2; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
