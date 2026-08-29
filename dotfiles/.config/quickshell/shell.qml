//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.modules.components.layout
import qs.modules.components.AppLauncher
import qs.modules.components.Setting
import qs.modules.components.Osd
import qs.modules.components.MusicVis
import qs.modules.components.Dock
import qs.modules.components.Widgets
import qs.modules.components.ToolsWidget
import qs.modules.components.ShutdownWindow
import qs.modules.components.Screenshot
import qs.modules.components.Overview
import qs.modules.components.Welcome
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

ShellRoot{
    DockPanel{}

    Variants{
        model: Quickshell.screens
        delegate: Item{
            required property var modelData
            Layout{
                screen: modelData
                isPrimary: {
                    const pm = SettingsConfig.general.primaryMonitor ?? ""
                    if (pm === "") return true
                    // Failover: if the configured primary is disconnected, first screen takes over
                    const primaryExists = Quickshell.screens.some(s => s.name === pm)
                    if (!primaryExists) return modelData === Quickshell.screens[0]
                    return modelData.name === pm
                }
            }
        }
    }

    AppLauncher{}
    SettingsPanel{}
    ToolsWidget{}
    Shutdown{}
    Loader{
        active: SettingsConfig.general.musicVisOn
        sourceComponent:Vis{
            anchors {
                left: true
                right: true
                bottom: true
            }
        }
    }


    WidgetScreen{
    }





    // Fullscreen area selector (replaces slurp for screenshot/recording area mode)
    AreaSelectorOverlay {}

    // Live Text — hyprctl dispatch global quickshell:ocr
    LiveTextOverlay {}

    // Post-capture thumbnail with Copy / Edit / Open / Delete
    ScreenshotPreview {}

    // Delayed-capture countdown
    CaptureCountdown {}

    // Workspace manager with live previews — hyprctl dispatch global quickshell:overview
    Overview {}

    WelcomePanel {}

}
