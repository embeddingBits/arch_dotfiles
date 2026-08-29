pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    property bool screenLocked: false
    property bool startAnimation: false

    // LockContext is lightweight, keep it loaded
    LockContext {
        id: lockContext

        // Gates the caps-lock watcher process — nothing polls while unlocked
        active: root.screenLocked

        onUnlocked: {
            //root.screenLocked = false
            timer.start()
            root.startAnimation = true
        }
    }

    Timer{
        id: timer
        interval: 900
        onTriggered:{
            root.screenLocked = false
            root.startAnimation = false
        }
    }

    WlSessionLock {
        id: lock
        locked: root.screenLocked

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            ScreencopyView {
                anchors.fill: parent
                captureSource: lockSurface.screen
            }

            // Loader unloads the UI when not locked to save memory
            Loader {
                id: contentLoader
                active: root.screenLocked
                anchors.fill: parent

                sourceComponent: Item {
                    anchors.fill: parent

                    LockSurface {
                        width: parent.width
                        height: parent.height
                        context: lockContext

                        NumberAnimation on y {
                            from: -1200; to: 0; running: true
                            duration: 600; easing.type: Easing.OutCubic
                        }
                        NumberAnimation on y {
                            from: 0; to: -1200; running: root.startAnimation
                            duration: 600; easing.type: Easing.InCubic
                        }
                    }
                }
            }
        }
    }

    // Triggered by: hyprctl dispatch global quickshell:lock
    GlobalShortcut {
        name: "lock"
        description: "Lock the screen"

        onPressed: {
            root.screenLocked = true
            root.startAnimation = false
        }
    }
}
