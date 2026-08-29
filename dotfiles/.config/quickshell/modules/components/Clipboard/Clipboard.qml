import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Scope{
    Loader{
        id: clipLoader
        active: GlobalStates.clipboardOpen
        property bool animation: false
        sourceComponent:PanelWindow{
            id: clipboardPanel
            implicitWidth: 400
            implicitHeight: 600
            anchors.bottom: true
            WlrLayershell.namespace: "quickshell:clipboard"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
                
            HyprlandFocusGrab{
                id: grab2
                windows: [clipboardPanel]
                active: clipLoader.active
                onCleared: () => {
                    if(!active) {
                        clipLoader.animation = false
                        animationTimer.start()
                    }
                }
            }

            ClipboardContent{
                implicitHeight: clipLoader.animation ? parent.height : 0
                onClosed:{
                    clipLoader.animation = false
                    animationTimer.start();
                }


            }
        }
    }

    Timer{
        id: animationTimer
        interval: 300
        onTriggered:{
            if(GlobalStates.clipboardOpen) GlobalStates.clipboardOpen = false
        }
    }

    GlobalShortcut{
        name: "clipboard"
        onPressed:{
            if(GlobalStates.clipboardOpen){
                clipLoader.animation = false
                animationTimer.start();
            }else{
                GlobalStates.clipboardOpen = true
                clipLoader.animation = true
            }
        }
    }

}
