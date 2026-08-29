import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.components.CustomContextMenu
import qs.modules.components.Osd

Scope {
    id: root

    Loader{
        id: loader
        active: false
        sourceComponent: PanelWindow {
            id: panelWindow
            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            Timer{
                interval: 200
                running: true
                onTriggered: child.active = true
            }
            Loader{
                id: child
                anchors.fill: parent
                active: false
                sourceComponent: ShutdownContent{
                }
            }

        }
        Connections{
            target: GlobalStates
            function onShutdownWindowChanged(){
                if(GlobalStates.shutdownWindow){
                    loader.active = true
                }else{
                    loader.active = false
                }
            }
        }
        GlobalShortcut {
            name: "shutdown"
            onPressed: {
                if (GlobalStates.shutdownWindow) {
                    GlobalStates.shutdownWindow = false
                } else {
                    GlobalStates.shutdownWindow = true
                }
            }
        }
    }
}
