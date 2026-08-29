pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Scope {
    id: scope

    Loader {
        active: ServiceTools.countingDown
        visible: active

        sourceComponent: PanelWindow {
            id: win

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            WlrLayershell.namespace:     "quickshell:countdown"
            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode:               ExclusionMode.Ignore

            mask: Region { item: ring }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: ServiceTools.cancelCountdown()

                Rectangle {
                    id: ring
                    anchors.centerIn: parent
                    width: 132; height: 132
                    radius: 66
                    color: Colors.surfaceContainer

                    CustomText {
                        id: countText
                        anchors.centerIn: parent
                        content: ServiceTools.countdownRemaining.toString()
                        size: 56
                        weight: 700
                        color: Colors.primary

                        onContentChanged: tick.restart()
                        SequentialAnimation {
                            id: tick
                            NumberAnimation { target: countText; property: "scale"; to: 1.22; duration: 90 }
                            SpatialAnim     { target: countText; property: "scale"; to: 1.0;  speed: "fast" }
                        }
                    }

                    CustomText {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
                        content: "Esc to cancel"
                        size: 9
                        color: Colors.outline
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ServiceTools.cancelCountdown()
                    }
                }
            }
        }
    }
}
