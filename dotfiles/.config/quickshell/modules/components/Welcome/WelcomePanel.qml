import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.modules.settings
import qs.modules.customComponents

Scope {
    id: scope

    property bool autoChecked: false
    property bool keepAtStartup: false

    function markSeen() {
        if (!scope.keepAtStartup && SettingsConfig.general.welcomeDone !== true)
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, { welcomeDone: true })
    }

    function close() {
        scope.markSeen()
        GlobalStates.welcomeOpen = false
    }

    LazyLoader {
        active: GlobalStates.welcomeOpen

        component: FloatingWindow {
            id: floatWindow
            visible: true
            implicitWidth: 1000
            implicitHeight: 720
            minimumSize: Qt.size(760, 560)
            title: "Nebula Setup"
            color: "transparent"

            onVisibleChanged: if (!floatWindow.visible) scope.close()

            WelcomeContent {
                onClosed: scope.close()
                onPinned: scope.keepAtStartup = true
            }
        }
    }

    GlobalShortcut {
        name: "welcome"
        description: "Open the Nebula setup screen"
        onPressed: GlobalStates.welcomeOpen = !GlobalStates.welcomeOpen
    }

    Timer {
        id: centerTimer
        interval: 140
        onTriggered: Hyprland.dispatch('hl.dsp.window.center({ window = "title:Nebula Setup" })')
    }

    Connections {
        target: GlobalStates
        function onWelcomeOpenChanged() {
            if (GlobalStates.welcomeOpen)
                centerTimer.restart()
        }
    }

    function maybeAutoOpen() {
        if (scope.autoChecked || !SettingsConfig.settingsReady)
            return
        scope.autoChecked = true
        if (SettingsConfig.general.welcomeDone !== true)
            firstRunTimer.start()
    }

    Timer {
        id: firstRunTimer
        interval: 1200
        onTriggered: GlobalStates.welcomeOpen = true
    }

    Connections {
        target: SettingsConfig
        function onSettingsReadyChanged() { scope.maybeAutoOpen() }
    }

    Component.onCompleted: scope.maybeAutoOpen()
}
