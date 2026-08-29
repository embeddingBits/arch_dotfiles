import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Scope{
    Loader{
        id: loader
        active: false
        sourceComponent: PanelWindow{
            id: panelWindow
            implicitWidth: 380
            anchors.left: true
            anchors.top: true
            anchors.bottom: true
            WlrLayershell.namespace: "quickshell:appLauncher"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
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

            HyprlandFocusGrab{
                id: grab
                windows: [panelWindow]
                active: loader.active
                onCleared: () => {
                    if(!active) {
                        GlobalStates.appLauncherOpen = false
                    }
                }
            }

            Shape {
                id: bgShape
                z: 1
                preferredRendererType: Shape.CurveRenderer
                visible: child.width > 0

                // Same arc parameters as the top bar (disX/disY/radX/radY = 18)
                readonly property real dX: 18
                readonly property real dY: 18
                readonly property real rX: 18
                readonly property real rY: 18

                // Mirrors buildFlatBarPath in Layout.qml but grows rightward from the left screen edge.
                // effDX clamps the arc offset so arcs never self-intersect when w is very small.
                function buildPath(dX, dY, rX, rY, left, right, top, bottom, w) {
                    const effDX = Math.min(dX, w / 2)
                    function A(sw, ex, ey) { return `A ${rX} ${rY} 0 0 ${sw} ${ex} ${ey} ` }
                    function L(x,  y)      { return `L ${x} ${y} ` }
                    const CW = 1, CCW = 0
                    let p = `M ${left} ${top - dY} `
                    p += A(CCW, left + effDX, top)      // top-left concave flare
                    p += L(right - effDX,     top)       // top edge
                    p += A(CW,  right, top    + effDX)  // top-right convex corner
                    p += L(right,      bottom - effDX)  // right wall
                    p += A(CW,  right - effDX, bottom)  // bottom-right convex corner
                    p += L(left + effDX,       bottom)  // bottom edge
                    p += A(CCW, left, bottom  + dY)     // bottom-left concave flare
                    p += L(left,      top     - dY)     // close: left screen edge
                    return p
                }

                ShapePath {
                    strokeWidth: -1
                    fillColor: Settings.layoutColor
                    PathSvg {
                        path: bgShape.buildPath(
                            bgShape.dX, bgShape.dY, bgShape.rX, bgShape.rY,
                            container.x,
                            container.x + child.width,
                            container.y,
                            container.y + container.height,
                            child.width
                        )
                    }
                }
            }

            Item {
                id: container
                z: 10
                implicitWidth: Math.max(20, child.width)
                implicitHeight: Math.max(100, child.implicitHeight)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    id: child
                    width: 0
                    implicitHeight: 720
                    clip: true

                    states: State {
                        name: "open"
                        when: GlobalStates.appLauncherOpen
                        PropertyChanges { target: child; width: 380 }
                    }

                    transitions: Transition {
                        NumberAnimation {
                            properties: "width"
                            duration:   Appearance.duration.large
                            easing.type: Easing.OutQuad
                        }
                    }

                    AppLauncherContent{
                        anchors.fill: parent
                        onClosed:{
                            GlobalStates.appLauncherOpen = false
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onAppLauncherOpenChanged() {
            if (GlobalStates.appLauncherOpen) {
                loader.active = true
            } else if (loader.active) {
                animationTimer.start()
            }
        }
    }

    Timer{
        id: animationTimer
        interval: Appearance.duration.large
        onTriggered:{
            loader.active = false
        }
    }

    GlobalShortcut{
        name: "appLauncher"
        onPressed:{
            GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen
        }
    }

    IpcHandler {
        target: "appLauncher"
        function toggle(): void { GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen }
        function open(): void { GlobalStates.appLauncherOpen = true }
        function close(): void { GlobalStates.appLauncherOpen = false }
    }
    // lowercase alias - niri users often type applauncher
    IpcHandler {
        target: "applauncher"
        function toggle(): void { GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen }
        function open(): void { GlobalStates.appLauncherOpen = true }
        function close(): void { GlobalStates.appLauncherOpen = false }
    }

}
