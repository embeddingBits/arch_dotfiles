import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

// Brief confirmation pill for game mode. Its own surface on the Overlay layer
// because everything else the shell draws is hidden by the time this needs to
// be seen — and it must show even though game mode turns DND on.
//
// Click-through (empty mask): this can appear over a fullscreen game, so it
// must never eat a click.
Scope {
    Loader {
        active: ServiceGameMode.toastVisible
        visible: active

        sourceComponent: PanelWindow {
            id: toastWindow
            implicitWidth: 220
            implicitHeight: 56
            visible: true
            color: "transparent"

            anchors.top: true
            margins.top: 90

            WlrLayershell.namespace: "quickshell:gameModeToast"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            mask: Region {}

            Rectangle {
                id: pill
                anchors.centerIn: parent
                implicitWidth: content.implicitWidth + 32
                implicitHeight: 44
                radius: height / 2
                color: Settings.layoutColor
                opacity: 0
                scale: 0.88

                NumberAnimation on opacity { from: 0; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }
                NumberAnimation on scale   { from: 0.88; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }

                RowLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: 10

                    MaterialIconSymbol {
                        content: "sports_esports"
                        iconSize: 20
                        fill: ServiceGameMode.active ? 1 : 0
                        customColor: ServiceGameMode.active ? Colors.primary : Colors.outline
                    }

                    CustomText {
                        content: ServiceGameMode.toastText
                        size: 14
                    }
                }
            }
        }
    }
}
