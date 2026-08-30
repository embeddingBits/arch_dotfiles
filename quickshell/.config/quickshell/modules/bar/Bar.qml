import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io

import "../../config/Theme.qml" as Theme

PanelWindow {
    id: bar

    required property var niriService
    required property var calendarService
    required property var memoryService

    required property bool calendarOpen
    required property bool volumePopupOpen
    required property bool wifiPopupOpen
    required property bool bluetoothPopupOpen

    signal toggleCalendar
    signal toggleVolume
    signal toggleWifi
    signal toggleBluetooth

    // ── Manifest loading (waybar-like) ──
    FileView {
        id: manifestFile
        path: Qt.resolvedUrl("../../config/bar.json")
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
    }

    // Use function call text() as per Quickshell docs: FileView.text()
    property string manifestText: manifestFile.loaded ? manifestFile.text() : ""

    // Strip // and /* */ comments to allow JSONC waybar-style files
    function stripJsonComments(s) {
        if (!s) return s
        // remove // line comments (but keep inside strings - simple heuristic: not perfect)
        let out = s.replace(/\/\/[^\n]*\n/g, "\n")
        out = out.replace(/\/\*[\s\S]*?\*\//g, "")
        // remove trailing commas before } or ]
        out = out.replace(/,\s*([}\]])/g, "$1")
        return out
    }

    property var defaultManifest: ({
        "height": Theme.barHeight,
        "margin-top": 0,
        "margin-bottom": 0,
        "margin-left": 0,
        "margin-right": 0,
        "spacing": 8,
        "padding-left": Theme.barPadding,
        "padding-right": Theme.barPadding,
        "modules-left": ["custom/launcher", "niri/workspaces", "niri/window"],
        "modules-center": ["clock"],
        "modules-right": ["tray", "wireplumber", "memory", "network", "bluetooth", "battery", "custom/power"]
    })

    property var manifest: {
        try {
            if (!manifestText || manifestText.trim() === "") return defaultManifest
            let cleaned = stripJsonComments(manifestText)
            let parsed = JSON.parse(cleaned)
            // fill defaults for missing keys
            for (let k in defaultManifest) if (!(k in parsed)) parsed[k] = defaultManifest[k]
            return parsed
        } catch (e) {
            console.warn("[Bar] manifest parse failed, using defaults:", e, "\n", manifestText ? manifestText.slice(0,200) : "")
            return defaultManifest
        }
    }

    property var modulesLeft: manifest["modules-left"] ?? defaultManifest["modules-left"]
    property var modulesCenter: manifest["modules-center"] ?? defaultManifest["modules-center"]
    property var modulesRight: manifest["modules-right"] ?? defaultManifest["modules-right"]

    // normalized helper: waybar aliases -> internal
    function normalizeModule(name) {
        let n = String(name || "").trim()
        let low = n.toLowerCase()
        // waybar style mapping
        if (low === "custom/launcher" || low === "launcher") return "custom/launcher"
        if (low === "niri/workspaces" || low === "workspaces" || low === "hyprland/workspaces") return "niri/workspaces"
        if (low === "niri/window" || low === "window" || low === "niri/window#active" || low === "active-window") return "niri/window"
        if (low === "clock") return "clock"
        if (low === "mpris" || low === "mpris#media" || low === "cava" || low === "media") return "mpris"
        if (low === "wireplumber" || low === "pulseaudio" || low === "audio" || low === "wireplumber#audio") return "wireplumber"
        if (low === "memory") return "memory"
        if (low === "network" || low === "network#wifi" || low === "network#ethernet") return "network"
        if (low === "bluetooth") return "bluetooth"
        if (low === "battery" || low === "battery#bat0") return "battery"
        if (low === "tray" || low === "system-tray" || low === "tray#system") return "tray"
        if (low === "custom/power" || low === "power" || low === "custom/powermenu") return "custom/power"
        if (low === "custom/separator" || low === "separator" || low === "custom/spacer") return "custom/separator"
        if (low === "backlight" || low === "backlight#intel_backlight") return "backlight"
        if (low.startsWith("custom/")) return low
        return low
    }

    // per-module width hint for fixed-size modules (RowLayout needs Layout.preferredWidth)
    function preferredWidthFor(m) {
        let n = normalizeModule(m)
        if (n === "wireplumber") return 64
        if (n === "memory") return 78
        if (n === "battery") return 58
        if (n === "custom/power") return 30
        if (n === "custom/launcher") return 28
        if (n === "network") return 28
        if (n === "bluetooth") return 28
        if (n === "custom/separator") return 1
        // tray, workspaces, window, clock are dynamic
        return -1
    }

    function componentFor(m) {
        let n = normalizeModule(m)
        if (n === "custom/launcher") return launcherComp
        if (n === "niri/workspaces") return workspacesComp
        if (n === "niri/window") return windowComp
        if (n === "clock") return clockComp
        if (n === "mpris") return mprisComp
        if (n === "wireplumber") return audioComp
        if (n === "memory") return memoryComp
        if (n === "network") return networkComp
        if (n === "bluetooth") return bluetoothComp
        if (n === "battery") return batteryComp
        if (n === "tray") return trayComp
        if (n === "custom/power") return powerComp
        if (n === "custom/separator") return separatorComp
        if (n === "backlight") return backlightComp
        // fallback for unknown custom/*
        return unknownComp
    }

    // ── Components for each module ──
    Component { id: launcherComp; MenuButton {} }
    Component { id: workspacesComp; Workspaces { niriService: bar.niriService } }
    Component { id: windowComp; ActiveWindow { niriService: bar.niriService } }
    Component {
        id: clockComp
        CenterClock {
            calendarOpen: bar.calendarOpen
            calendarService: bar.calendarService
            onToggleCalendar: bar.toggleCalendar()
        }
    }
    Component {
        id: mprisComp
        Item {
            id: mprisRoot
            property var mprisPlayers: Mpris.players ? Mpris.players.values : []
            property var activePlayer: {
                for (let i=0;i<mprisPlayers.length;i++) if (mprisPlayers[i] && mprisPlayers[i].isPlaying) return mprisPlayers[i];
                for (let i=0;i<mprisPlayers.length;i++) if (mprisPlayers[i] && mprisPlayers[i].trackTitle) return mprisPlayers[i];
                return null
            }
            property string nowText: {
                let p = activePlayer;
                if (!p) return "";
                let t = p.trackTitle || "";
                let a = p.trackArtist || p.trackArtists || "";
                if (t && a) return a + " - " + t;
                if (t) return t;
                if (a) return a;
                return p.identity || "";
            }
            property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
            visible: nowText !== ""
            implicitWidth: mprisRow.implicitWidth + 16
            implicitHeight: 26
            width: implicitWidth; height: 26
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: mprisMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
            }
            RowLayout {
                id: mprisRow
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: mprisRoot.isPlaying ? "󰝚" : "󰏤"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    color: mprisRoot.isPlaying ? Theme.accent : Theme.muted
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: mprisRoot.nowText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    font.weight: 500
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.maximumWidth: 260
                    Layout.alignment: Qt.AlignVCenter
                    maximumLineCount: 1
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: Theme.underlineClock
                opacity: mprisMouse.containsMouse ? 1 : 0.92
            }
            MouseArea {
                id: mprisMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let p = mprisRoot.activePlayer;
                    if (!p) return;
                    if (p.canTogglePlaying) p.togglePlaying();
                    else if (p.isPlaying) p.pause();
                    else p.play();
                }
            }
        }
    }
    Component {
        id: audioComp
        Item {
            implicitWidth: 64; implicitHeight: 26
            AudioWidget {
                anchors.fill: parent
                volumePopupOpen: bar.volumePopupOpen
                onToggleVolume: bar.toggleVolume()
            }
        }
    }
    Component {
        id: memoryComp
        Item {
            implicitWidth: 78; implicitHeight: 26
            MemoryWidget {
                anchors.fill: parent
                memoryService: bar.memoryService
            }
        }
    }
    Component { id: networkComp; NetworkWidget { wifiPopupOpen: bar.wifiPopupOpen; onToggleWifi: bar.toggleWifi() } }
    Component { id: bluetoothComp; BluetoothWidget { bluetoothPopupOpen: bar.bluetoothPopupOpen; onToggleBluetooth: bar.toggleBluetooth() } }
    Component { id: batteryComp; BatteryWidget {} }
    Component { id: trayComp; SystemTrayWidget {} }
    Component { id: powerComp; PowerButton {} }
    Component {
        id: separatorComp
        Rectangle {
            width: 1; height: 16
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
            opacity: 0.6
        }
    }
    Component {
        id: backlightComp
        // Placeholder - backlight not implemented, show icon with tooltip
        Item {
            width: 28; height: 26
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: blMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "󰃠"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.barFontSize
                color: Theme.fg
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: Theme.underlineNetwork
                opacity: blMouse.containsMouse ? 1 : 0.92
            }
            MouseArea { id: blMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        }
    }
    Component {
        id: unknownComp
        Item {
            property string modName: ""
            width: unkText.implicitWidth + 12; height: 26
            Rectangle { anchors.fill: parent; radius: Theme.radius; color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) }
            Text {
                id: unkText
                anchors.centerIn: parent
                text: modName
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.muted
            }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 2; radius: 1; color: Theme.muted; opacity: 0.5 }
        }
    }

    // ── Panel geometry from manifest ──
    anchors {
        left: true
        right: true
        top: true
    }
    // margins like waybar's margin-top etc.
    // Quickshell PanelWindow uses `margins` group
    margins {
        top: manifest["margin-top"] ?? manifest["margin"] ?? 0
        bottom: manifest["margin-bottom"] ?? manifest["margin"] ?? 0
        left: manifest["margin-left"] ?? manifest["margin"] ?? 0
        right: manifest["margin-right"] ?? manifest["margin"] ?? 0
    }
    implicitHeight: manifest["height"] ?? Theme.barHeight
    color: Theme.bg

    // ── Background + bottom separator ──
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: "transparent"
        border.width: 0
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.25)
        }
    }

    Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: manifest["padding-left"] ?? manifest["padding"] ?? Theme.barPadding
        anchors.rightMargin: manifest["padding-right"] ?? manifest["padding"] ?? Theme.barPadding

        // ── Left section (dynamic) ──
        RowLayout {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: manifest["spacing"] ?? 8

            Repeater {
                model: bar.modulesLeft
                delegate: Loader {
                    required property var modelData
                    required property int index
                    property string mod: String(modelData)
                    property string norm: bar.normalizeModule(mod)
                    Layout.preferredWidth: bar.preferredWidthFor(mod)
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: bar.componentFor(mod)
                    onLoaded: {
                        if (item && item.hasOwnProperty("modName")) item.modName = mod
                    }
                }
            }
        }

        // ── Center section (dynamic, centered) ──
        Item {
            id: centerContainer
            anchors.centerIn: parent
            // width = content width, height = bar height
            width: centerRow.implicitWidth
            height: parent.height
            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: bar.manifest["spacing"] ?? 8
                Repeater {
                    model: bar.modulesCenter
                    delegate: Loader {
                        required property var modelData
                        property string mod: String(modelData)
                        Layout.preferredWidth: bar.preferredWidthFor(mod)
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: bar.componentFor(mod)
                        onLoaded: {
                            if (item && item.hasOwnProperty("modName")) item.modName = mod
                        }
                    }
                }
            }
        }

        // ── Right section (dynamic) ──
        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: manifest["spacing"] ?? 8

            Repeater {
                model: bar.modulesRight
                delegate: Loader {
                    required property var modelData
                    property string mod: String(modelData)
                    Layout.preferredWidth: bar.preferredWidthFor(mod)
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: bar.componentFor(mod)
                    onLoaded: {
                        if (item && item.hasOwnProperty("modName")) item.modName = mod
                    }
                }
            }
        }
    }

    // Keep original CenterClock's margins handling for when clock is in center: override height handling
    // If manifest changes, bar will hot-reload due to FileView watchChanges
}
