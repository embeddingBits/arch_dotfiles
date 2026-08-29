import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs.modules.components.LockScreen

ShellRoot {
    GreeterContext {
        id: greeterContext

        // When authentication succeeds and is ready to launch
        onReadyToLaunch: {
            // Launch Hyprland session
            greeterContext.launchSession()
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            // WlrLayershell for Sway - fullscreen overlay
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Anchor to all edges to fill screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            GreeterSurface {
                anchors.fill: parent
                context: greeterContext
            }
        }
    }
}
