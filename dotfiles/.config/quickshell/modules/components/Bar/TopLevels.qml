import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.utils
import qs.modules.services
import Quickshell.Widgets

Item{
    id: toplevels
    anchors.fill: parent
    property alias appList : appList

    // Niri: prefer Hyprland toplevels if available, else derive from ServiceNiri via currentWorkspace
    readonly property var effectiveModel: {
        if (currentWorkspace && currentWorkspace.toplevels) return currentWorkspace.toplevels
        // Niri fallback: currentWorkspace is a niri workspace (has idx/output)
        if (currentWorkspace && currentWorkspace.idx !== undefined) {
            return ServiceNiri.getNiriWindowsForWorkspace(currentWorkspace.idx, currentWorkspace.output ?? currentWorkspace.monitor?.name)
        }
        return null
    }

    ListView{
        id: appList
        width: contentWidth
        height: parent.height
        orientation: Qt.Horizontal
        spacing: 2
        interactive: false
        anchors.centerIn: parent
        model: toplevels.effectiveModel

        delegate: Item{
            id: iconItem
            height: 40
            width: 25
            anchors.verticalCenter: parent?.verticalCenter



            Component.onCompleted:{
                ServiceWorkspaces.refreshToplevels()

            }

            opacity: 0
            NumberAnimation on opacity{
                from: 0
                to: 1
                duration: 200
                running: true
            }



            IconImage{
                id: icon
                anchors.centerIn: parent
                implicitSize: 16
                // Niri windows have app_id/title, Hyprland toplevels have wayland.appId
                source: {
                    var appId = modelData.app_id ?? modelData.appId ?? modelData.wayland?.appId ?? ""
                    if (!appId && modelData.title) appId = modelData.title
                    return Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon, "image-missing")
                }

            }

            //Drag.active: dragArea.drag.active
            //Drag.hotSpot.x: width / 2
            //Drag.hotSpot.y: height / 2

            /*MouseArea{
                 id: dragArea
                 anchors.fill: parent
                 acceptedButtons: Qt.RightButton | Qt.LeftButton
                 cursorShape: Qt.PointingHandCursor

                 drag.target: iconItem
                 drag.axis: Drag.XAndYAxis

                 onPressed: function(mouse){
                     mouse.accepted = true

                     // Store original position and parent
                     iconItem.originalX = iconItem.x
                     iconItem.originalY = iconItem.y
                     iconItem.originalWidth = iconItem.width
                     iconItem.originalHeight = iconItem.height
                     iconItem.originalParent = iconItem.parent
                     if (!overlay) {
                         var globalPos = iconItem.mapToItem(overlay, 0, 0)
                         iconItem.parent = overlay
                         iconItem.x = globalPos.x
                         iconItem.y = globalPos.y
                         iconItem.z = 10
                     }

                     icon.implicitSize = 22
                 }

                 onPositionChanged: {
                 }

                 onClicked: function(mouse){
                     if(mouse.button === Qt.LeftButton){
                         if(currentWorkspace){
                             currentWorkspace.activate()
                         } else {
                             Hyprland.dispatch(`workspace ${index + 1}`)
                         }
                     }
                 }

                 onReleased: {
                     if (workspacesRow) {
                         var globalPos = iconItem.mapToItem(workspacesRow, iconItem.width/2, iconItem.height/2)
                         var targetWorkspaceIndex = -1

                         for (var i = 0; i < workspacesRow.count; i++) {
                             var workspaceItem = workspacesRow.itemAt(i)
                             if (workspaceItem && 
                             globalPos.x >= workspaceItem.x && 
                             globalPos.x <= workspaceItem.x + workspaceItem.width &&
                             globalPos.y >= workspaceItem.y && 
                             globalPos.y <= workspaceItem.y + workspaceItem.height) {
                                 targetWorkspaceIndex = i
                                 break
                             }
                         }

                         if (targetWorkspaceIndex >= 0 && modelData && modelData.address) {
                             var targetWorkspaceId = targetWorkspaceIndex + 1
                             var currentWorkspaceId = currentWorkspace ? currentWorkspace.id : -1

                             if (targetWorkspaceId !== currentWorkspaceId) {
                                 Hyprland.dispatch("movetoworkspacesilent " + targetWorkspaceId + ",address:0x" + modelData.address)
                             }
                         }
                     }

                     iconItem.parent = iconItem.originalParent
                     iconItem.x = iconItem.originalX
                     iconItem.y = iconItem.originalY
                     iconItem.width = iconItem.originalWidth
                     iconItem.height = iconItem.originalHeight
                     iconItem.z = 0
                     icon.implicitSize = 18
                 }
             }*/
         }
    }
}
