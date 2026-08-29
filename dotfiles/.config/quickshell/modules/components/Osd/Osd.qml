import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Scope{
    Loader{
        id: loader
        active: GlobalStates.osdOpen
        sourceComponent:PanelWindow{
            id: panelWindow
            implicitWidth: Appearance.size.osdWidth
            implicitHeight: Appearance.size.osdHeight
            visible: true
            color: "transparent"
            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.None


            OsdContent{

            }

        }
    }
    Timer{
        id: timer
        interval: 2000
        onTriggered:{
            GlobalStates.osdOpen = false
        }
    }

    Connections {
        target: ServicePipewire.sink?.audio ?? null
        function onVolumeChanged() {
            GlobalStates.osdOpen = true
            timer.restart()
            //root.triggerOsd()
        }
        function onMutedChanged(){
            GlobalStates.osdOpen = true
            timer.restart()
        }
        // function onMutedChanged() {
        //     if (!ServicePipewire.ready) return
        //     //root.triggerOsd()
        // }
    }
}
