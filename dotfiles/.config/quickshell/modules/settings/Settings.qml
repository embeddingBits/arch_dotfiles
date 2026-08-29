pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.utils

Singleton{
    id: settings

    property string layoutColor: Colors.surface
    property string activeTheme: "Wallpaper"
    property int    dashboardHeight: 400
    property string wallpaper: Colors.wallpaper
    property string matugenSetting: "Light"
    property string matugenTheme: matugenSetting.toLowerCase()
    property string currentDisplayMode: "Extended"
    property string currentMatugenStyle: "default"
    property string matugenScheme: "scheme-content"

    // Workspace configur ation per monitor
    property var monitorWorkspaces: ({
        "eDP-1": { // Your HDMI monitor name - adjust this
            workspaces: [1, 2, 3, 4, 5],
            type: "external"
        }
            //,
        // "eDP-1": { // Your laptop display name - adjust this
        //     workspaces: [6, 7, 8, 9, 10],
        //     type: "laptop"
        // }
    })

    property string firstColor:"#833ab4"
    property string secondColor:"#fd1d1d"
    property string thirdColor:"#fcb045"

    property var quickIcons:[
        {
            name: "Airplane",
            icon: "travel",
            iconActive: "airplanemode_inactive"

        },
        {
            name: "Notification",
            icon: "notifications",
            iconActive: "notifications_off"
        },
        {
            name: "Speaker",
            icon: "volume_up",
            iconActive: "volume_off"
        },
        {
            name: "Mic",
            icon: "mic",
            iconActive: "mic_off"
        },
        {
            name: "Awake",
            icon: "bedtime",
            iconActive: "coffee"
        }

    ]
    property var themeModes:[
        {
            name: "Dark",
            icon: "bedtime"
        },
        {
            name: "Light",
            icon: "sunny"
        }
    ]

    property var pages:[
        {
            name: "Theme",
            icon: "palette",
        },
        {
            name: "Sound",
            icon: "volume_up"
        },
        {
            name: "Notifications",
            icon: "notifications"
        },
        {
            name: "Widgets",
            icon: "widgets"
        },
        {
            name: "Networking",
            icon: "android_wifi_4_bar"
        },
        {
            name: "Bluetooth",
            icon: "bluetooth"
        },
        {
            name: "Weather",
            icon: "partly_cloudy_day"
        },
        {
            name: "Media",
            icon: "perm_media"
        },
        {
            name: "About",
            icon: 'info'
        },
        {
            name: "Appearance",
            icon: "style"
        },
        {
            name: "Sleep",
            icon: "bedtime"
        },
        {
            name: "Storage",
            icon: "hard_drive"
        }
    ]

    property var displayModes:[
        {
            name: "Extended",
            icon: "pan_zoom"
        },
        {
            name: "Mirror",
            icon: "tv_displays"
        },
        {
            name: "Single",
            icon: "monitor"
        }
    ]

    property var fonts: [
        { name: "Adwaita Sans" },
        { name: "Cantarell" },
        { name: "DejaVu Sans" },
        { name: "Fira Sans" },
        { name: "Liberation Sans" },
        { name: "Noto Sans" },
        { name: "Readex Pro" },
        { name: "Rubik" }
    ]

    property var displayFonts: [
        { name: "Titan One" },
        { name: "Orbitron" },
        { name: "Michroma" },
        { name: "Just Another Hand" },
        { name: "Fira Sans" }
    ]

    property var transitionTypes: [
        { name: "fade" },
        { name: "simple" },
        { name: "none" },
        { name: "left" },
        { name: "right" },
        { name: "top" },
        { name: "bottom" },
        { name: "wipe" },
        { name: "wave" },
        { name: "grow" },
        { name: "center" },
        { name: "any" },
        { name: "outer" },
        { name: "random" }
    ]

    property var matugen:[
        {
            name: "scheme-tonal-spot"
        },
        {
            name: "scheme-content"
        },
        {
            name: "scheme-expressive"
        },
        {
            name: "scheme-fidelity"
        },
        {
            name: "scheme-fruit-salad"
        },
        {
            name:"scheme-monochrome"
        },
        {
            name:"scheme-neutral"
        },
        {
            name: "scheme-rainbow"
        }    
    ]

    function setActiveTheme(theme): void{
        settings.activeTheme = theme
    }

    function setMatugenTheme(theme): void{
        settings.matugenTheme = theme
    }

    function setMatugenSetting(type): void{
        settings.matugenSetting = type
    }

    // Get workspaces for a specific monitor
    function getWorkspacesForMonitor(monitorName): var {
        if (monitorWorkspaces[monitorName]) {
            return monitorWorkspaces[monitorName].workspaces
        }
        // Fallback: return 1-5 if monitor not found
        return [1, 2, 3, 4, 5]
    }

    // Get all workspaces NOT assigned to this monitor (for other screen indicator)
    function getOtherScreenWorkspaces(monitorName): var {
        var otherWorkspaces = []
        for (var monitor in monitorWorkspaces) {
            if (monitor !== monitorName) {
                otherWorkspaces = otherWorkspaces.concat(monitorWorkspaces[monitor].workspaces)
            }
        }
        return otherWorkspaces
    }
}
