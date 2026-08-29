pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Scope {
    id: scope

    property string path: ""
    property bool   shown: false

    Connections {
        target: ServiceTools
        function onScreenshotReady(p) {
            scope.path  = p
            scope.shown = true
            dismiss.restart()
        }
    }

    Timer {
        id: dismiss
        interval: 6000
        onTriggered: scope.shown = false
    }

    Loader {
        active: scope.shown && scope.path !== ""
        visible: active

        sourceComponent: PanelWindow {
            id: win

            anchors { right: true; bottom: true }
            implicitWidth:  320
            implicitHeight: 220
            color: "transparent"
            WlrLayershell.namespace:     "quickshell:screenshotPreview"
            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode:               ExclusionMode.Ignore

            mask: Region { item: card }

            property real _slide: 40
            property real _op: 0
            Component.onCompleted: Qt.callLater(() => { win._slide = 0; win._op = 1 })
            Behavior on _slide { SpatialAnim { speed: "default" } }
            Behavior on _op    { EffectsAnim { speed: "default" } }

            Rectangle {
                id: card
                anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
                width: 288
                height: 188
                radius: 24
                color: Colors.surfaceContainerLow
                clip: true
                opacity: win._op
                transform: Translate { x: win._slide }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 104
                        radius: 14
                        color: Colors.surfaceContainerHighest
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + scope.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 576
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        PreviewAction {
                            Layout.fillWidth: true
                            icon: "content_copy"; label: "Copy"
                            onTriggered: { ServiceTools.copyScreenshot(scope.path); scope.shown = false }
                        }
                        PreviewAction {
                            Layout.fillWidth: true
                            icon: "edit"; label: "Edit"
                            onTriggered: { ServiceTools.editScreenshot(scope.path); scope.shown = false }
                        }
                        PreviewAction {
                            Layout.fillWidth: true
                            icon: "folder_open"; label: "Open"
                            onTriggered: { Quickshell.execDetached(["xdg-open", scope.path]); scope.shown = false }
                        }
                        PreviewAction {
                            Layout.fillWidth: true
                            icon: "delete"; label: "Delete"; danger: true
                            onTriggered: { ServiceTools.deleteScreenshot(scope.path); scope.shown = false }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    onEntered: dismiss.stop()
                    onExited:  dismiss.restart()
                }
            }
        }
    }

    component PreviewAction: Rectangle {
        id: pa
        implicitHeight: 52
        radius: 14
        color: Colors.surfaceContainer

        property string icon: ""
        property string label: ""
        property bool   danger: false
        signal triggered()

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: pa.danger ? Colors.error : Colors.surfaceText
            opacity: ma.pressed ? 0.14 : ma.containsMouse ? 0.09 : 0
            Behavior on opacity { EffectsAnim { speed: "fast" } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 3

            MaterialIconSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                content: pa.icon
                iconSize: 17
                color: pa.danger ? Colors.error : Colors.surfaceText
            }
            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: pa.label
                size: 9; weight: 600
                color: pa.danger ? Colors.error : Colors.surfaceVariantText
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pa.triggered()
        }
    }
}
