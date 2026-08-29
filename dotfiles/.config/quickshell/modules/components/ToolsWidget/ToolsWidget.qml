import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Scope {
    Loader {
        id: loader
        active: GlobalStates.toolsWidgetOpen
        visible: active

        sourceComponent: PanelWindow {
            id: panelWindow
            implicitWidth: 600
            implicitHeight: 600
            WlrLayershell.namespace: "quickshell:toolsWidget"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            mask: Region {
                item: maskRect
                intersection: Intersection.Xor

                Region {
                    item: container
                    intersection: Intersection.Subtract
                }
            }

            Rectangle {
                id: maskRect
                anchors.fill: parent
                color: "transparent"
            }

            HyprlandFocusGrab {
                windows: [panelWindow]
                active: loader.active
                onCleared: GlobalStates.toolsWidgetOpen = false
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: GlobalStates.toolsWidgetOpen = false

                ToolsWidgetOverall {
                    id: container
                    anchors.centerIn: parent
                }
            }
        }
    }

    GlobalShortcut {
        name: "toolsWidget"
        onPressed: GlobalStates.toolsWidgetOpen = !GlobalStates.toolsWidgetOpen
    }
}
