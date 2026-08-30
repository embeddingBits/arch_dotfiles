import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Widgets

ShellRoot {
    id: root

    property color colBg: "#1d2021"
    property color colFg: "#ebdbb2"
    property color colAccent: "#d79221"
    property color colBorder: "#d79221" 
    property color colBorderMuted: "#504945" 
    property color colHover: "#3c3836"
    property color colMuted: "#928374"
    property int barHeight: 38
    property string fontFamily: "JetBrainsMono Nerd Font"
    property string fontFamilyFallback: "JetBrainsMono Nerd Font"
    property int barFontSize: 14
    property int clockFontSize: barFontSize
    property int iconFontSize: barFontSize
    property int smallFontSize: barFontSize
    property int radius: 0
    property int radiusSmall: 0

    // ── Waybar-like manifest (config/bar.json) ──
    FileView {
        id: barManifestFile
        path: Qt.resolvedUrl("./config/bar.json")
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
    }
    property string _barManifestText: barManifestFile.loaded ? barManifestFile.text() : ""
    function _stripJsonComments(s) {
        if (!s) return s
        let out = s.replace(/\/\/[^\n]*\n/g, "\n")
        out = out.replace(/\/\*[\s\S]*?\*\//g, "")
        out = out.replace(/,\s*([}\]])/g, "$1")
        return out
    }
    property var _defaultBarManifest: ({
        "height": barHeight,
        "margin-top": 0,
        "margin-bottom": 0,
        "margin-left": 0,
        "margin-right": 0,
        "spacing": 8,
        "padding-left": 8,
        "padding-right": 8,
        "modules-left": ["custom/launcher", "niri/workspaces", "niri/window"],
        "modules-center": ["clock"],
        "modules-right": ["tray", "wireplumber", "memory", "network", "bluetooth", "battery", "custom/power"]
    })
    property var barManifest: {
        try {
            if (!_barManifestText || _barManifestText.trim() === "") return _defaultBarManifest
            let cleaned = _stripJsonComments(_barManifestText)
            let parsed = JSON.parse(cleaned)
            for (let k in _defaultBarManifest) if (!(k in parsed)) parsed[k] = _defaultBarManifest[k]
            return parsed
        } catch (e) {
            console.warn("[Bar] manifest parse failed:", e)
            return _defaultBarManifest
        }
    }
    property var barModulesLeft: barManifest["modules-left"] ?? _defaultBarManifest["modules-left"]
    property var barModulesCenter: barManifest["modules-center"] ?? _defaultBarManifest["modules-center"]
    property var barModulesRight: barManifest["modules-right"] ?? _defaultBarManifest["modules-right"]
    function _normalizeBarModule(name) {
        let n = String(name||"").trim()
        let low = n.toLowerCase()
        if (low === "custom/launcher" || low === "launcher") return "custom/launcher"
        if (low === "niri/workspaces" || low === "workspaces") return "niri/workspaces"
        if (low === "niri/window" || low === "window" || low === "active-window") return "niri/window"
        if (low === "clock") return "clock"
        if (low === "mpris" || low === "mpris#media") return "mpris"
        if (low === "wireplumber" || low === "pulseaudio" || low === "audio") return "wireplumber"
        if (low === "memory") return "memory"
        if (low === "network") return "network"
        if (low === "bluetooth") return "bluetooth"
        if (low === "battery") return "battery"
        if (low === "tray" || low === "system-tray") return "tray"
        if (low === "custom/power" || low === "power") return "custom/power"
        if (low === "custom/separator" || low === "separator") return "custom/separator"
        if (low === "backlight") return "backlight"
        if (low.startsWith("custom/")) return low
        return low
    }
    function _prefWidthForBarModule(m) {
        let n = _normalizeBarModule(m)
        if (n === "wireplumber") return 64
        if (n === "memory") return 78
        if (n === "battery") return 58
        if (n === "custom/power") return 30
        if (n === "custom/launcher") return 28
        if (n === "network") return 28
        if (n === "bluetooth") return 28
        if (n === "custom/separator") return 1
        return -1
    }
    function _compForBarModule(m) {
        let n = _normalizeBarModule(m)
        if (n === "custom/launcher") return _launcherComp
        if (n === "niri/workspaces") return _workspacesComp
        if (n === "niri/window") return _windowComp
        if (n === "clock") return _clockComp
        if (n === "mpris") return _mprisComp
        if (n === "wireplumber") return _audioComp
        if (n === "memory") return _memComp
        if (n === "network") return _networkComp
        if (n === "bluetooth") return _btComp
        if (n === "battery") return _battComp
        if (n === "tray") return _trayComp
        if (n === "custom/power") return _powerComp
        if (n === "custom/separator") return _sepComp
        if (n === "backlight") return _backlightComp
        return _unknownComp
    }

    // ── Bar module Components (for dynamic manifest) ──
    Component {
        id: _launcherComp
        Item {
            width: 28; height: 26
            Rectangle {
                anchors.fill: parent
                color: _launcherMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                radius: root.radius
            }
            Text { anchors.centerIn: parent; text: "󰣇"; font.family: root.fontFamily; font.pixelSize: root.barFontSize; color: root.colFg }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineMenu
                opacity: _launcherMouse.containsMouse ? 1.0 : 0.95
            }
            MouseArea { id: _launcherMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","rofi -show drun &"]) }
        }
    }
    Component {
        id: _workspacesComp
        RowLayout {
            spacing: 6
            Repeater {
                model: root.niriWorkspaces
                delegate: Item {
                    id: wsDelegate
                    required property var modelData
                    property bool focused: modelData.is_focused
                    property bool occupied: modelData.occupied
                    Layout.preferredWidth: wsDelegate.focused ? 30 : 26
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: wsMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                             : wsDelegate.focused ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10)
                             : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: wsDelegate.focused ? "󰝥" : String(wsDelegate.modelData.idx)
                        font.family: root.fontFamily
                        font.pixelSize: root.barFontSize
                        font.weight: wsDelegate.focused ? 700 : 600
                        color: wsDelegate.focused ? root.colAccent : (wsDelegate.occupied ? root.colFg : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.55))
                        opacity: wsDelegate.occupied || wsDelegate.focused ? 1 : 0.60
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: wsDelegate.focused ? 2.5 : 2
                        radius: 1
                        color: wsDelegate.focused ? root.colUnderlineWorkspaces : (wsDelegate.occupied ? Qt.rgba(root.colUnderlineWorkspaces.r, root.colUnderlineWorkspaces.g, root.colUnderlineWorkspaces.b, 0.85) : Qt.rgba(root.colUnderlineWorkspaces.r, root.colUnderlineWorkspaces.g, root.colUnderlineWorkspaces.b, 0.35))
                        opacity: wsMouse.containsMouse ? 1 : 0.9
                    }
                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["niri","msg","action","focus-workspace", String(wsDelegate.modelData.idx)])
                    }
                }
            }
        }
    }
    Component {
        id: _windowComp
        Item {
            visible: root.activeWindowTitle !== ""
            implicitWidth: Math.min(activeWinText.implicitWidth + 32, 280)
            implicitHeight: 26
            width: implicitWidth; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: awMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 6
                Text {
                    text: "󰖲"
                    font.family: root.fontFamily; font.pixelSize: root.barFontSize; color: root.colMuted
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    id: activeWinText
                    text: root.activeWindowTitle
                    font.family: root.fontFamily; font.pixelSize: root.barFontSize; font.weight: 500
                    color: root.colFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    maximumLineCount: 1
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineActiveWindow
                opacity: awMouse.containsMouse ? 1 : 0.9
            }
            MouseArea { id: awMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        }
    }
    Component {
        id: _clockComp
        Item {
            // CenterClock combined with mpris; width dynamic
            implicitWidth: _clockRow.implicitWidth + 28
            implicitHeight: 26
            width: implicitWidth; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: clkMouse.containsMouse || root.calendarOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                id: _clockRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    id: _clk
                    color: root.colFg
                    font.family: root.fontFamily
                    font.weight: 700
                    font.pixelSize: root.barFontSize
                    Layout.alignment: Qt.AlignVCenter
                    property date currentTime: new Date()
                    text: Qt.formatDateTime(currentTime, "dddd hh:mm:ss AP")
                    Timer { interval: 1000; running: true; repeat: true; onTriggered: _clk.currentTime = new Date() }
                }
                Text {
                    visible: root.nowPlayingText !== ""
                    text: "|"
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.6)
                    Layout.alignment: Qt.AlignVCenter
                }
                Item {
                    visible: root.nowPlayingText !== ""
                    Layout.preferredWidth: _nowRow.implicitWidth
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    RowLayout {
                        id: _nowRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: root.nowPlayingIsPlaying ? "󰝚" : "󰏤"
                            font.family: root.fontFamily
                            font.pixelSize: root.barFontSize
                            color: root.nowPlayingIsPlaying ? root.colAccent : root.colMuted
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: root.nowPlayingText
                            font.family: root.fontFamily
                            font.pixelSize: root.barFontSize
                            font.weight: 500
                            color: root.colFg
                            elide: Text.ElideRight
                            Layout.maximumWidth: 260
                            Layout.alignment: Qt.AlignVCenter
                            maximumLineCount: 1
                        }
                    }
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineClock
                opacity: clkMouse.containsMouse || root.calendarOpen ? 1 : 0.92
            }
            MouseArea {
                id: clkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse){
                    if(root.nowPlayingText !== "" && root.activeMprisPlayer){
                        let rowX=_clockRow.x
                        let clockRight=rowX + _clk.implicitWidth + 12
                        if(mouseX > clockRight){
                            let p=root.activeMprisPlayer;
                            if(p.canTogglePlaying) p.togglePlaying();
                            else if(p.isPlaying) p.pause();
                            else p.play();
                            return;
                        }
                    }
                    root.toggleCalendar();
                }
            }
        }
    }
    Component {
        id: _mprisComp
        Item {
            visible: root.nowPlayingText !== ""
            implicitWidth: _mprisRow2.implicitWidth + 16
            implicitHeight: 26
            width: implicitWidth; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _mprisMouse2.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                id: _mprisRow2
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: root.nowPlayingIsPlaying ? "󰝚" : "󰏤"
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    color: root.nowPlayingIsPlaying ? root.colAccent : root.colMuted
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.nowPlayingText
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    font.weight: 500
                    color: root.colFg
                    elide: Text.ElideRight
                    Layout.maximumWidth: 260
                    Layout.alignment: Qt.AlignVCenter
                    maximumLineCount: 1
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineClock
                opacity: _mprisMouse2.containsMouse ? 1 : 0.92
            }
            MouseArea {
                id: _mprisMouse2
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let p = root.activeMprisPlayer;
                    if (!p) return;
                    if (p.canTogglePlaying) p.togglePlaying();
                    else if (p.isPlaying) p.pause();
                    else p.play();
                }
            }
        }
    }
    Component {
        id: _audioComp
        Item {
            implicitWidth: 64; implicitHeight: 26
            width: 64; height: 26
            property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
            property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _audioMouse.containsMouse || root.volumePopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                spacing: 4
                Text {
                    text: {
                        if (!Pipewire.defaultAudioSink?.audio) return "󰖁";
                        if (parent.parent.muted || parent.parent.vol===0) return "󰝟";
                        if (parent.parent.vol < 0.33) return "󰕿";
                        if (parent.parent.vol < 0.66) return "󰖀";
                        return "󰕾";
                    }
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    color: root.colFg
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: Math.round(parent.parent.vol*100) + "%"
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    font.weight: 600
                    color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.90)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineAudio
                opacity: _audioMouse.containsMouse || root.volumePopupOpen ? 1 : 0.92
            }
            MouseArea {
                id: _audioMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleVolume()
                onWheel: function(wheel){
                    if(!Pipewire.defaultAudioSink?.audio) return;
                    let s=0.05; let v=Pipewire.defaultAudioSink.audio.volume + (wheel.angleDelta.y>0?s:-s);
                    Pipewire.defaultAudioSink.audio.volume=Math.max(0,Math.min(1,v));
                    if(Pipewire.defaultAudioSink.audio.muted && v>0) Pipewire.defaultAudioSink.audio.muted=false;
                }
            }
        }
    }
    Component {
        id: _memComp
        Item {
            implicitWidth: 78; implicitHeight: 26
            width: 78; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _memMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                spacing: 4
                Text {
                    text: "󰍛"
                    font.family: root.fontFamily; font.pixelSize: root.barFontSize; color: root.colFg
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.memUsedText
                    font.family: root.fontFamily; font.pixelSize: root.barFontSize; font.weight: 600
                    color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.90)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineMemory
                opacity: _memMouse.containsMouse ? 1 : 0.92
            }
            MouseArea {
                id: _memMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if(!memProc.running) memProc.running=true
            }
        }
    }
    Component {
        id: _networkComp
        Item {
            width: 28; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _netMouse.containsMouse || root.wifiPopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: {
                    let d=root.wifiDev;
                    if(!d) return "󰤯";
                    if(!Networking.wifiEnabled) return "󰤮";
                    for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) {
                        let s=root.wifiNets[i].signalStrength||0;
                        if(s>0.66) return "󰤨";
                        if(s>0.33) return "󰤥";
                        return "󰤢";
                    }
                    return "󰤯";
                }
                font.family: root.fontFamily
                font.pixelSize: root.barFontSize
                color: root.colFg
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineNetwork
                opacity: _netMouse.containsMouse || root.wifiPopupOpen ? 1 : 0.92
            }
            MouseArea { id: _netMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleWifi() }
        }
    }
    Component {
        id: _btComp
        Item {
            width: 28; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _btMouse.containsMouse || root.bluetoothPopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: {
                    let a=root.btAdapter;
                    if(!a) return "󰂯";
                    if(!a.enabled) return "󰂲";
                    for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) return "󰂱";
                    return "󰂯";
                }
                font.family: root.fontFamily
                font.pixelSize: root.barFontSize
                color: root.colFg
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineBluetooth
                opacity: _btMouse.containsMouse || root.bluetoothPopupOpen ? 1 : 0.92
            }
            MouseArea { id: _btMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBluetooth() }
        }
    }
    Component {
        id: _battComp
        Item {
            visible: UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery
            implicitWidth: 58; implicitHeight: 26
            width: 58; height: 26
            property real pct: (UPower.displayDevice?.percentage ?? 0)
            property int devState: (UPower.displayDevice?.state ?? 0)
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _battMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            RowLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                spacing: 4
                Text {
                    text: {
                        let p=parent.parent.pct*100; let ch=parent.parent.devState===1;
                        if(ch) return "󰂄";
                        if(p>90) return "󰁹";
                        if(p>70) return "󰂀";
                        if(p>50) return "󰁿";
                        if(p>30) return "󰁾";
                        if(p>15) return "󰁼";
                        return "󰁺";
                    }
                    font.family: root.fontFamily
                    font.pixelSize: root.barFontSize
                    color: parent.parent.pct<0.2 && parent.parent.devState!==1 ? "#cc241d" : root.colFg
                    Layout.alignment: Qt.AlignVCenter
                }
                Text { text: Math.round(parent.parent.pct*100)+"%"; font.family: root.fontFamily; font.pixelSize: root.barFontSize; font.weight: 600; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineBattery
                opacity: _battMouse.containsMouse ? 1 : 0.92
            }
            MouseArea { id: _battMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        }
    }
    Component {
        id: _trayComp
        RowLayout {
            spacing: 2
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property var modelData
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: trayMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    }
                    IconImage { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; width: 16; height: 16; source: modelData.icon; asynchronous: true }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineTray
                        opacity: trayMouse.containsMouse ? 1 : 0.85
                    }
                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: function(mouse){
                            if(mouse.button===Qt.LeftButton) modelData.activate();
                            else if(mouse.button===Qt.RightButton && modelData.hasMenu) modelData.display(Qt.point(width/2,height));
                        }
                    }
                }
            }
        }
    }
    Component {
        id: _powerComp
        Item {
            width: 30; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _powMouse.containsMouse ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.12) : "transparent"
            }
            Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: "󰐥"; font.family: root.fontFamily; font.pixelSize: root.barFontSize; color: _powMouse.containsMouse? root.colAccent : root.colFg }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlinePower
                opacity: _powMouse.containsMouse ? 1 : 0.92
            }
            MouseArea { id: _powMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","wlogout &"]) }
        }
    }
    Component {
        id: _sepComp
        Rectangle {
            width: 1; height: 16
            color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.35)
            opacity: 0.6
        }
    }
    Component {
        id: _backlightComp
        Item {
            width: 28; height: 26
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: _blMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "󰃠"
                font.family: root.fontFamily
                font.pixelSize: root.barFontSize
                color: root.colFg
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 2; radius: 1
                color: root.colUnderlineNetwork
                opacity: _blMouse.containsMouse ? 1 : 0.92
            }
            MouseArea { id: _blMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        }
    }
    Component {
        id: _unknownComp
        Item {
            property string modName: ""
            width: _unkText.implicitWidth + 12; height: 26
            Rectangle { anchors.fill: parent; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.05) }
            Text {
                id: _unkText
                anchors.centerIn: parent
                text: modName
                font.family: root.fontFamily
                font.pixelSize: 10
                color: root.colMuted
            }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 2; radius: 1; color: root.colMuted; opacity: 0.5 }
        }
    }

    // ── underline colors per bar element (distinct) ──
    property color colUnderlineMenu: "#fabd2f"
    property color colUnderlineActiveWindow: "#d5c4a1"
    property color colUnderlineWorkspaces: "#fe8019"
    property color colUnderlineClock: "#83a598"
    property color colUnderlineTray: "#a89984"
    property color colUnderlineAudio: "#8ec07c"
    property color colUnderlineMemory: "#689d6a"
    property color colUnderlineNetwork: "#458588"
    property color colUnderlineBluetooth: "#d3869b"
    property color colUnderlineBattery: "#b8bb26"
    property color colUnderlinePower: "#fb4934"
    property color colUnderlineApps: "#b16286"

    property bool calendarOpen: false
    property date today: new Date()
    property string todayKey: dateKey(today.getFullYear(), today.getMonth(), today.getDate())
    property int calYear: today.getFullYear()
    property int calMonth: today.getMonth()
    property int weekStart: 1
    property date calViewDate: new Date(calYear, calMonth, 1)
    property var calWeeks: monthGrid(calYear, calMonth, weekStart, todayKey)
    property real yearDone: yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
    property int yearDonePercent: Math.round(yearDone * 100)

    property bool volumePopupOpen: false
    property bool wifiPopupOpen: false
    property bool bluetoothPopupOpen: false
    function closeAllPopups(){
        calendarOpen=false; volumePopupOpen=false; wifiPopupOpen=false; bluetoothPopupOpen=false;
    }
    function toggleVolume(){ let o=!volumePopupOpen; closeAllPopups(); volumePopupOpen=o; }
    function toggleWifi(){ let o=!wifiPopupOpen; closeAllPopups(); wifiPopupOpen=o; }
    function toggleBluetooth(){ let o=!bluetoothPopupOpen; closeAllPopups(); bluetoothPopupOpen=o; }
    function toggleCalendar(){ let o=!calendarOpen; closeAllPopups(); calendarOpen=o; if(o) refreshCalendar(); }

    function pad2(v){ let n=Number(v); return (n<10?"0":"")+n; }
    function dateKey(y,m,d){ return y+"-"+pad2(m+1)+"-"+pad2(d); }
    function dayOfYear(y,m,d){ return Math.round((Date.UTC(y,m,d)-Date.UTC(y,0,1))/86400000)+1; }
    function daysInYear(y){ return dayOfYear(y,11,31); }
    function yearProgress(y,m,d){ let tot=daysInYear(y); return tot<=0?0:Math.max(0,Math.min(1,(dayOfYear(y,m,d)-1)/tot)); }
    function isoWeek(y,m,d){
        let dt=new Date(Date.UTC(y,m,d)); let wd=dt.getUTCDay()||7;
        dt.setUTCDate(dt.getUTCDate()+4-wd);
        let ys=new Date(Date.UTC(dt.getUTCFullYear(),0,1));
        return Math.ceil(((dt.getTime()-ys.getTime())/86400000+1)/7);
    }
    function weekdayOrder(start){ let s=((start%7)+7)%7; let o=[]; for(let i=0;i<7;i++) o.push((s+i)%7); return o; }
    function monthGrid(year, month, weekStart, todayKey){
        let start=((weekStart%7)+7)%7;
        let leading=(new Date(year,month,1).getDay()-start+7)%7;
        let cursor=new Date(year,month,1-leading);
        let tk=String(todayKey||""); let weeks=[];
        for(let w=0;w<6;w++){
            let days=[]; let th=null;
            for(let d=0;d<7;d++){
                let cy=cursor.getFullYear(), cm=cursor.getMonth(), cd=cursor.getDate();
                let wd=cursor.getDay(); let k=dateKey(cy,cm,cd);
                if(wd===4) th={year:cy,month:cm,day:cd};
                days.push({key:k,year:cy,month:cm,day:cd,weekday:wd,inMonth:cm===month&&cy===year, weekend:wd===0||wd===6, today:k===tk});
                cursor.setDate(cursor.getDate()+1);
            }
            let anchor=th||days[0];
            weeks.push({week: isoWeek(anchor.year,anchor.month,anchor.day), days:days});
        }
        return weeks;
    }
    function refreshCalendar(){
        root.today=new Date();
        root.todayKey=dateKey(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.calYear=root.today.getFullYear(); root.calMonth=root.today.getMonth();
        root.calWeeks=monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
        root.yearDone=yearProgress(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.yearDonePercent=Math.round(root.yearDone*100);
    }
    function stepCalMonth(delta){
        let d=new Date(root.calYear, root.calMonth+delta, 1);
        root.calYear=d.getFullYear(); root.calMonth=d.getMonth();
        root.calWeeks=monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
    }

    // ── Festival / Event data ──
    // Fixed recurring festivals (MM-DD)
    function fixedFestivalsFor(md){
        let m={
            "01-01": ["New Year's Day"],
            "01-13": ["Lohri"],
            "01-14": ["Makar Sankranti"],
            "01-26": ["Republic Day \uD83C\uDDEE\uD83C\uDDF3"],
            "02-14": ["Valentine's Day"],
            "03-08": ["Maha Shivratri", "International Women's Day"],
            "03-14": ["Holi \u2022 Festival of Colours"],
            "04-13": ["Baisakhi"],
            "04-14": ["Ambedkar Jayanti"],
            "05-01": ["Labour Day / Maharashtra Day"],
            "06-05": ["World Environment Day"],
            "06-21": ["International Yoga Day"],
            "08-15": ["Independence Day \uD83C\uDDEE\uD83C\uDDF3"],
            "08-27": ["Ganesh Chaturthi"],
            "09-05": ["Teachers' Day"],
            "10-02": ["Gandhi Jayanti"],
            "10-12": ["Dussehra / Vijayadashami"],
            "10-20": ["Diwali \u2022 Festival of Lights"],
            "10-21": ["Govardhan Puja"],
            "10-22": ["Bhai Dooj"],
            "11-14": ["Children's Day"],
            "11-24": ["Guru Nanak Jayanti"],
            "12-25": ["Christmas \u2603"],
            "12-31": ["New Year's Eve"]
        };
        return m[md] || [];
    }
    function specialFestivalsFor(ymd){
        let m={
            "2026-01-01": ["New Year's Day"],
            "2026-03-03": ["Holi"],
            "2026-03-20": ["Eid al-Fitr \u2606"],
            "2026-03-31": ["Ram Navami"],
            "2026-04-05": ["Easter Sunday"],
            "2026-05-27": ["Eid al-Adha"],
            "2026-08-28": ["Raksha Bandhan"],
            "2026-08-29": ["Raksha Bandhan (obs.)"],
            "2026-09-04": ["Janmashtami"],
            "2026-09-14": ["Onam"],
            "2026-10-02": ["Gandhi Jayanti", "Dussehra"],
            "2026-10-20": ["Diwali"],
            "2026-11-08": ["Karva Chauth"],
            "2026-12-25": ["Christmas"]
        };
        return m[ymd] || [];
    }
    function festivalsForDate(y,m,d){
        let md=pad2(m+1)+"-"+pad2(d);
        let ymd=y+"-"+md;
        let fixed=fixedFestivalsFor(md);
        let spec=specialFestivalsFor(ymd);
        // merge unique
        let out=[]; let seen={};
        for(let i=0;i<fixed.length;i++){ if(!seen[fixed[i]]){ seen[fixed[i]]=true; out.push(fixed[i]); } }
        for(let i=0;i<spec.length;i++){ if(!seen[spec[i]]){ seen[spec[i]]=true; out.push(spec[i]); } }
        // also check month-day from special that may overlap already handled, but we also want to avoid duplicate of fixed that already includes; above merges.
        return out;
    }
    function eventDotColor(idx){
        let palette=["#fabd2f","#fe8019","#83a598","#8ec07c","#d3869b","#fb4934","#458588","#b8bb26"];
        return palette[idx % palette.length];
    }
    function upcomingEventsFromToday(count, daysAhead){
        let res=[]; let lim=count||6; let span=daysAhead||60;
        let cur=new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        for(let i=0;i<span && res.length<lim;i++){
            let y=cur.getFullYear(), m=cur.getMonth(), d=cur.getDate();
            let ev=festivalsForDate(y,m,d);
            if(ev.length>0){
                res.push({key: dateKey(y,m,d), date: new Date(y,m,d), events: ev});
            }
            cur.setDate(cur.getDate()+1);
        }
        return res;
    }

    property var niriWorkspaces: []
    property var niriRaw: []
    property var niriWindows: []
    property var groupedRunningApps: {
        let map = {};
        let order = [];
        for (let i = 0; i < niriWindows.length; i++) {
            let w = niriWindows[i];
            if (!w) continue;
            let rawAid = String(w.app_id || w.appId || "unknown");
            if (rawAid === "" || rawAid === "unknown") rawAid = w.title ? String(w.title).split(" ")[0] : "unknown";
            let low = rawAid.toLowerCase();
            let key = low;
            let displayId = rawAid;
            // canonicalize allowed apps to avoid duplicate icons for same logical app
            if(low.indexOf("spotify") !== -1){ key = "spotify"; displayId = "spotify"; }
            else if(low.indexOf("telegram") !== -1){ key = "telegram"; displayId = "telegram"; }
            else if(low.indexOf("vesktop") !== -1 || low.indexOf("discord") !== -1){ key = "vesktop"; displayId = "vesktop"; }
            else { key = low; displayId = rawAid; }
            if (!map[key]) {
                map[key] = { key: key, appId: displayId, count: 0, windows: [], isFocused: false, titles: [], lastFocused: 0 };
                order.push(key);
            }
            map[key].count++;
            map[key].windows.push(w);
            if (w.is_focused) map[key].isFocused = true;
            if (w.title) map[key].titles.push(String(w.title));
            let ts = 0;
            if (w.focus_timestamp) {
                let s = Number(w.focus_timestamp.secs) || 0;
                let n = Number(w.focus_timestamp.nanos) || 0;
                ts = s * 1000000000 + n;
            }
            if (ts > map[key].lastFocused) map[key].lastFocused = ts;
        }
        let out = [];
        for (let i = 0; i < order.length; i++) out.push(map[order[i]]);
        out.sort((a,b) => b.lastFocused - a.lastFocused);
        return out;
    }
    // filtered to only show selected persistent apps (spotify, telegram, vesktop/discord)
    property var allowedAppIds: ["spotify", "telegram", "vesktop", "discord"]
    property var filteredRunningApps: {
        let filtered = [];
        for(let i=0;i<groupedRunningApps.length;i++){
            let entry = groupedRunningApps[i];
            let low = String(entry.appId||"").toLowerCase();
            for(let j=0;j<allowedAppIds.length;j++){
                if(low.indexOf(allowedAppIds[j]) !== -1){
                    filtered.push(entry);
                    break;
                }
                // also check titles for fallback (e.g. web apps where app_id is generic)
                // but keep strict to appId for now
            }
        }
        return filtered;
    }
    function appIconName(appId){
        let aid = String(appId||"");
        if(!aid) return "";
        let lower = aid.toLowerCase();
        // explicit icon candidates for allowed apps
        let candidates = [];
        if(lower.indexOf("spotify") !== -1){
            candidates = ["spotify-launcher","spotify","spotify-client"];
        } else if(lower.indexOf("telegram") !== -1){
            candidates = ["org.telegram.desktop","telegram","telegram-desktop"];
        } else if(lower.indexOf("vesktop") !== -1){
            candidates = ["vesktop","discord","Discord"];
        } else if(lower.indexOf("discord") !== -1){
            candidates = ["discord","vesktop","Discord"];
        }
        for(let i=0;i<candidates.length;i++){
            let cand = candidates[i];
            if(Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(cand)){
                let p = Quickshell.iconPath(cand, "");
                if(p && p !== "") return p;
            }
            let e = DesktopEntries.heuristicLookup(cand);
            if(e && e.icon){
                let pp = Quickshell.iconPath(e.icon, "");
                if(pp && pp !== "") return pp;
            }
        }
        let entry = DesktopEntries.heuristicLookup(aid);
        if(entry && entry.icon){
            let p = Quickshell.iconPath(entry.icon, "");
            if(p && p !== "") return p;
        }
        if(lower !== aid){
            let e2 = DesktopEntries.heuristicLookup(lower);
            if(e2 && e2.icon){
                let p2 = Quickshell.iconPath(e2.icon, "");
                if(p2 && p2 !== "") return p2;
            }
        }
        if(Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(aid)){
            let p3 = Quickshell.iconPath(aid, "");
            if(p3 && p3 !== "") return p3;
        }
        if(Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(lower)){
            let p4 = Quickshell.iconPath(lower, "");
            if(p4 && p4 !== "") return p4;
        }
        // try raw candidates without has check as last resort
        for(let i=0;i<candidates.length;i++){
            let p = Quickshell.iconPath(candidates[i], "");
            if(p && p !== "" && p.indexOf("NOTFOUND")===-1) return p;
        }
        let fallback = Quickshell.iconPath("application-x-executable", "");
        if(fallback && fallback !== "") return fallback;
        return "";
    }
    function focusGroupedApp(group){
        if(!group || !group.windows || group.windows.length===0) return;
        let wins = group.windows;
        if(wins.length===1){
            let nid = wins[0].id;
            if(nid!==undefined) Quickshell.execDetached(["niri","msg","action","focus-window","--id", String(nid)]);
            return;
        }
        let focusedIdx = -1;
        for(let i=0;i<wins.length;i++) if(wins[i].is_focused) focusedIdx=i;
        if(focusedIdx!==-1){
            let nextIdx = (focusedIdx+1)%wins.length;
            let nid = wins[nextIdx].id;
            if(nid!==undefined) Quickshell.execDetached(["niri","msg","action","focus-window","--id", String(nid)]);
        } else {
            let best = wins[0];
            let bestTs = -1;
            for(let i=0;i<wins.length;i++){
                let w=wins[i];
                let ts = w.focus_timestamp ? (Number(w.focus_timestamp.secs)||0)*1000000000 + (Number(w.focus_timestamp.nanos)||0) : 0;
                if(ts>bestTs){ bestTs=ts; best=w; }
            }
            if(best && best.id!==undefined) Quickshell.execDetached(["niri","msg","action","focus-window","--id", String(best.id)]);
        }
    }
    function closeGroupedApp(group, onlyFocused){
        if(!group || !group.windows || group.windows.length===0) return;
        let wins = group.windows;
        let target = null;
        if(onlyFocused){
            for(let i=0;i<wins.length;i++) if(wins[i].is_focused){ target=wins[i]; break; }
        }
        if(!target){
            let bestTs=-1;
            for(let i=0;i<wins.length;i++){
                let w=wins[i];
                let ts = w.focus_timestamp ? (Number(w.focus_timestamp.secs)||0)*1000000000 + (Number(w.focus_timestamp.nanos)||0) : 0;
                if(ts>bestTs){ bestTs=ts; target=w; }
            }
        }
        if(target && target.id!==undefined) Quickshell.execDetached(["niri","msg","action","close-window","--id", String(target.id)]);
    }
    property string activeWindowTitle: ""
    property string activeWindowAppId: ""
    property real memUsedGB: 0
    property real memTotalGB: 0
    property string memUsedText: memUsedGB.toFixed(1) + "G"
    // ── now playing (Mpris) ──
    property var mprisPlayers: Mpris.players ? Mpris.players.values : []
    property var activeMprisPlayer: {
        for(let i=0;i<mprisPlayers.length;i++) if(mprisPlayers[i] && mprisPlayers[i].isPlaying) return mprisPlayers[i];
        for(let i=0;i<mprisPlayers.length;i++) if(mprisPlayers[i] && mprisPlayers[i].trackTitle) return mprisPlayers[i];
        return null;
    }
    property string nowPlayingText: {
        let p=activeMprisPlayer;
        if(!p) return "";
        let t=p.trackTitle||"";
        let a=p.trackArtist||p.trackArtists||"";
        if(t && a) return a + " - " + t;
        if(t) return t;
        if(a) return a;
        return p.identity||"";
    }
    property bool nowPlayingIsPlaying: activeMprisPlayer ? activeMprisPlayer.isPlaying : false
    Process {
        id: niriProc
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t=String(text||"").trim();
                if(!t) return;
                try{
                    let arr=JSON.parse(t);
                    if(!Array.isArray(arr)) return;
                    root.niriRaw=arr;
                    let map={};
                    for(let i=0;i<arr.length;i++){
                        let w=arr[i]; let idx=Number(w.idx);
                        if(!isFinite(idx)) continue;
                        if(!map[idx]) map[idx]={idx:idx, is_focused:false, is_active:false, occupied:false, output: w.output||""};
                        if(w.is_focused) map[idx].is_focused=true;
                        if(w.is_active) map[idx].is_active=true;
                        if(w.active_window_id!==null && w.active_window_id!==undefined) map[idx].occupied=true;
                    }
                    let out=[];
                    for(let k in map) out.push(map[k]);
                    for(let c=1;c<=5;c++) if(!map[c]) out.push({idx:c, is_focused:false, is_active:false, occupied:false, output:""});
                    out.sort((a,b)=>a.idx-b.idx);
                    root.niriWorkspaces=out;
                }catch(e){ console.warn("niri workspaces parse failed", e); }
            }
        }
    }
    Process {
        id: niriWindowsProc
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t=String(text||"").trim();
                if(!t) return;
                try{
                    let wins=JSON.parse(t);
                    if(!Array.isArray(wins)) return;
                    root.niriWindows=wins;
                    let occupiedSet={};
                    for(let i=0;i<wins.length;i++) occupiedSet[wins[i].workspace_id]=true;
                    let idToIdx={};
                    for(let i=0;i<root.niriRaw.length;i++) idToIdx[root.niriRaw[i].id]=root.niriRaw[i].idx;
                    let idxOccupied={};
                    for(let id in occupiedSet){ let idx=idToIdx[id]; if(idx!==undefined) idxOccupied[idx]=true; }
                    let cur=root.niriWorkspaces.slice();
                    for(let j=0;j<cur.length;j++) if(idxOccupied[cur[j].idx]) cur[j].occupied=true;
                    root.niriWorkspaces=cur;
                    // active window title
                    let focused=null;
                    for(let i=0;i<wins.length;i++) if(wins[i] && wins[i].is_focused){ focused=wins[i]; break; }
                    if(focused){
                        root.activeWindowTitle=String(focused.title||focused.app_id||"");
                        root.activeWindowAppId=String(focused.app_id||"");
                    } else {
                        // fallback: active_window_id from focused workspace
                        let awId=null;
                        for(let i=0;i<root.niriRaw.length;i++) if(root.niriRaw[i].is_focused) awId=root.niriRaw[i].active_window_id;
                        let found=null;
                        if(awId!==null) for(let i=0;i<wins.length;i++) if(wins[i].id===awId) found=wins[i];
                        if(found){ root.activeWindowTitle=String(found.title||found.app_id||""); root.activeWindowAppId=String(found.app_id||""); }
                        else { root.activeWindowTitle=""; root.activeWindowAppId=""; }
                    }
                }catch(e){}
            }
        }
    }
    Timer { id: niriPollTimer; interval: 200; running: true; repeat: true; onTriggered: { if(!niriProc.running) niriProc.running=true; if(!niriWindowsProc.running) niriWindowsProc.running=true; } }
    Component.onCompleted: { niriProc.running=true; niriWindowsProc.running=true; if(!memProc.running) memProc.running=true; }
    Process {
        id: niriEventProc
        command: ["niri", "msg", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: function(line){
                let s=String(line||"");
                if(s.indexOf("Workspace")!==-1 || s.indexOf("Window")!==-1){
                    if(!niriProc.running) niriProc.running=true;
                    if(!niriWindowsProc.running) niriWindowsProc.running=true;
                }
            }
        }
    }

    // ── memory usage polling (used GB) ──
    Process {
        id: memProc
        command: ["bash","-c","awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} END{printf \"%.0f %.0f\", (t-a), t}' /proc/meminfo"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let s=String(text||"").trim();
                if(!s) return;
                let parts=s.split(/\s+/);
                if(parts.length>=2){
                    let usedKB=Number(parts[0]); let totalKB=Number(parts[1]);
                    if(isFinite(usedKB) && isFinite(totalKB) && totalKB>0){
                        root.memUsedGB=usedKB/1024/1024;
                        root.memTotalGB=totalKB/1024/1024;
                    }
                }
            }
        }
    }
    Timer { id: memPollTimer; interval: 3000; running: true; repeat: true; onTriggered: if(!memProc.running) memProc.running=true }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    property var netDevices: Networking.devices ? Networking.devices.values : []
    property var wifiDev: {
        for(let i=0;i<netDevices.length;i++) if(netDevices[i] && netDevices[i].type===DeviceType.Wifi) return netDevices[i];
        return null;
    }
    property var wifiNets: wifiDev && wifiDev.networks ? wifiDev.networks.values : []
    property var btAdapter: Bluetooth.defaultAdapter
    property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []

    PanelWindow {
        id: bar
        anchors { left: true; right: true; top: true }
        margins {
            top: barManifest["margin-top"] ?? barManifest["margin"] ?? 0
            bottom: barManifest["margin-bottom"] ?? barManifest["margin"] ?? 0
            left: barManifest["margin-left"] ?? barManifest["margin"] ?? 0
            right: barManifest["margin-right"] ?? barManifest["margin"] ?? 0
        }
        implicitHeight: barManifest["height"] ?? root.barHeight
        color: root.colBg

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            border.color: "transparent"
            border.width: 0
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.25) }
        }

        Item {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: barManifest["padding-left"] ?? barManifest["padding"] ?? 8
            anchors.rightMargin: barManifest["padding-right"] ?? barManifest["padding"] ?? 8

            // ── Left (dynamic) ──
            RowLayout {
                id: leftSection
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: barManifest["spacing"] ?? 8
                Repeater {
                    model: root.barModulesLeft
                    delegate: Loader {
                        required property var modelData
                        property string mod: String(modelData)
                        Layout.preferredWidth: root._prefWidthForBarModule(mod)
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: root._compForBarModule(mod)
                        onLoaded: if (item && item.hasOwnProperty("modName")) item.modName = mod
                    }
                }
            }

            // ── Center (dynamic, centered) ──
            Item {
                id: centerSection
                anchors.centerIn: parent
                width: centerRow.implicitWidth
                height: parent.height
                RowLayout {
                    id: centerRow
                    anchors.centerIn: parent
                    spacing: barManifest["spacing"] ?? 8
                    Repeater {
                        model: root.barModulesCenter
                        delegate: Loader {
                            required property var modelData
                            property string mod: String(modelData)
                            Layout.preferredWidth: root._prefWidthForBarModule(mod)
                            Layout.preferredHeight: 26
                            Layout.alignment: Qt.AlignVCenter
                            sourceComponent: root._compForBarModule(mod)
                            onLoaded: if (item && item.hasOwnProperty("modName")) item.modName = mod
                        }
                    }
                }
            }

            // ── Right (dynamic) ──
            RowLayout {
                id: rightSection
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: barManifest["spacing"] ?? 8
                Repeater {
                    model: root.barModulesRight
                    delegate: Loader {
                        required property var modelData
                        property string mod: String(modelData)
                        Layout.preferredWidth: root._prefWidthForBarModule(mod)
                        Layout.preferredHeight: 26
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: root._compForBarModule(mod)
                        onLoaded: if (item && item.hasOwnProperty("modName")) item.modName = mod
                    }
                }
            }
        }
    }

    PopupWindow {
        id: calPopup
        visible: root.calendarOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: Math.round(bar.width/2 - implicitWidth/2)
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 380
        implicitHeight: calColumn.implicitHeight + 28
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: calColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Item {
                    width: parent.width; height: 42
                    Row { anchors.centerIn: parent; spacing: 12
                        Text { text: "󰃭"; font.family: root.fontFamily; font.pixelSize: 28; color: root.colFg; anchors.baseline: heroDate.baseline }
                        Text { id: heroDate; text: Qt.formatDate(root.today, "MMMM d"); font.family: root.fontFamily; font.pixelSize: 26; font.weight: 700; color: root.colFg }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.refreshCalendar() }
                }
                Column {
                    width: parent.width; spacing: 4
                    RowLayout {
                        width: parent.width; spacing: 8
                        Text { text: String(root.today.getFullYear()); font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.4); font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }
                        Text { id: yearPct; text: root.yearDonePercent + "%"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                    }
                    Rectangle {
                        width: parent.width; height: 6; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.12)
                        Rectangle { width: parent.width * root.yearDone; height: parent.height; radius: root.radius; color: root.colAccent; Behavior on width { NumberAnimation{ duration:160; easing.type: Easing.OutCubic } } }
                    }
                }
                Item {
                    width: parent.width; height: 30
                    Text { anchors.centerIn: parent; width: 140; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.calViewDate, "MMMM yyyy").toUpperCase(); font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; color: Qt.darker(root.colFg,1.2) }
                    Rectangle {
                        anchors.left: parent.left; width: 28; height: 28; radius: root.radius
                        color: prevMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                        border.color: prevMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰅁"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.stepCalMonth(-1) }
                    }
                    Rectangle {
                        anchors.right: parent.right; width: 28; height: 28; radius: root.radius
                        color: nextMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                        border.color: nextMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰅂"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.stepCalMonth(1) }
                    }
                }
                Row {
                    width: parent.width; spacing: 2
                    Item { width: 28; height: 16 }
                    Repeater {
                        model: root.weekdayOrder(root.weekStart)
                        delegate: Text {
                            required property int modelData
                            width: (parent.width - 28 - 6*2)/7; height: 16
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            text: ["SUN","MON","TUE","WED","THU","FRI","SAT"][modelData].substring(0,2)
                            font.family: root.fontFamily; font.pixelSize: 9; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.5)
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 2
                    Repeater {
                        model: root.calWeeks
                        delegate: Row {
                            required property var modelData
                            width: parent.width; spacing: 2
                            Text { width: 28; height: 30; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: String(modelData.week); font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.8) }
                            Repeater {
                                model: modelData.days
                                delegate: Item {
                                    required property var modelData
                                    width: (parent.parent.width - 28 - 6*2)/7; height: 34
                                    property var dayEvents: root.festivalsForDate(modelData.year, modelData.month, modelData.day)
                                    property bool hasEvents: dayEvents.length > 0
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: root.radius
                                        color: dayMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : (modelData.today ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.14) : "transparent")
                                        border.width: modelData.today ? 1 : 0
                                        border.color: root.colBorder
                                    }
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: String(modelData.day)
                                            font.family: root.fontFamily; font.pixelSize: 12; font.weight: modelData.today ? 700 : 400
                                            color: modelData.inMonth ? (modelData.weekend ? Qt.darker(root.colFg,1.3) : root.colFg) : Qt.darker(root.colFg,2.0)
                                        }
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 2
                                            visible: hasEvents
                                            Repeater {
                                                model: dayEvents.slice(0,3)
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    required property int index
                                                    width: 5; height: 5; radius: 2.5
                                                    color: root.eventDotColor(index)
                                                }
                                            }
                                            // if many events show +n
                                            Text {
                                                visible: dayEvents.length > 3
                                                text: "+"+(dayEvents.length-3)
                                                font.family: root.fontFamily; font.pixelSize: 6; color: root.colMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                    // limit dot display to 3
                                    MouseArea {
                                        id: dayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: hasEvents ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    }
                                    ToolTip {
                                        visible: dayMouse.containsMouse && hasEvents
                                        delay: 300
                                        timeout: 3000
                                        text: dayEvents.join("\n")
                                        contentItem: Text {
                                            text: dayMouse.containsMouse && hasEvents ? dayEvents.join("\n") : ""
                                            font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg
                                            wrapMode: Text.Wrap
                                        }
                                        background: Rectangle {
                                            color: root.colBg
                                            border.color: root.colBorder
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }
            WheelHandler { onWheel: function(e){ if(e.angleDelta.y!==0) root.stepCalMonth(e.angleDelta.y>0?-1:1); } }
        }
    }

    PopupWindow {
        id: volumePopup
        visible: root.volumePopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 90
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: volumeCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: volumeCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 12
                Row {
                    width: parent.width
                    Text { text: "󰕾  Audio"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 12; height: 1 }
                    Text { text: Pipewire.defaultAudioSink?.audio?.muted ? "MUTED" : Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%" ; font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                }
                Column {
                    width: parent.width; spacing: 6
                    RowLayout { width: parent.width
                        Text { text: "OUTPUT"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                        Item { Layout.fillWidth: true; height: 1 }
                        Text { text: Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                    }
                    Rectangle {
                        width: parent.width; height: 28; radius: root.radius; color: "transparent"; border.color: root.colBorderMuted; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 8
                            Text { text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰕾"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
                            Item {
                                Layout.fillWidth: true; height: 6; Layout.alignment: Qt.AlignVCenter
                                Rectangle { anchors.fill: parent; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18) }
                                Rectangle {
                                    width: parent.width * (Pipewire.defaultAudioSink?.audio.volume??0); height: parent.height; radius: root.radius; color: root.colAccent
                                }
                                Slider {
                                    id: outSlider
                                    anchors.fill: parent
                                    from: 0; to: 1; stepSize: 0.02
                                    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                                    onMoved: { if(Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume=value; }
                                    background: Item {}
                                    handle: Rectangle { visible: false; width: 1; height: 1 }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: volMuteMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"; border.color: volMuteMouse.containsMouse ? root.colBorderMuted : "transparent"; border.width: 1
                                Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰝧"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg }
                                MouseArea { id: volMuteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted=!Pipewire.defaultAudioSink.audio.muted }
                            }
                        }
                    }
                    Column {
                        width: parent.width; spacing: 4
                        Repeater {
                            model: {
                                let ns=Pipewire.nodes ? Pipewire.nodes.values : [];
                                let out=[];
                                for(let i=0;i<ns.length;i++){ let n=ns[i]; if(n && n.isSink && !n.isStream) out.push(n); }
                                return out.slice(0,5);
                            }
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width; height: 26; radius: root.radius
                                color: sinkMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : (Pipewire.defaultAudioSink && modelData.id===Pipewire.defaultAudioSink.id ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.12) : "transparent")
                                border.color: Pipewire.defaultAudioSink && modelData.id===Pipewire.defaultAudioSink.id ? root.colBorderMuted : (sinkMouse.containsMouse ? root.colBorderMuted : "transparent")
                                border.width: 1
                                Row {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                    Text { text: "󰓃"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.description || modelData.name || "Unknown"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 30; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea { id: sinkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink=modelData }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    RowLayout { width: parent.width
                        Text { text: "INPUT"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                        Item { Layout.fillWidth: true; height: 1 }
                        Text { text: Pipewire.defaultAudioSource?.audio ? Math.round((Pipewire.defaultAudioSource.audio.volume??0)*100)+"%" : "--"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                    }
                    Rectangle {
                        visible: !!Pipewire.defaultAudioSource
                        width: parent.width; height: 28; radius: root.radius; color: "transparent"; border.color: root.colBorderMuted; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 8
                            Text { text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                            Item {
                                Layout.fillWidth: true; height: 6
                                Rectangle { anchors.fill: parent; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18) }
                                Rectangle { width: parent.width * (Pipewire.defaultAudioSource?.audio.volume??0); height: parent.height; radius: root.radius; color: root.colAccent }
                                Slider {
                                    anchors.fill: parent
                                    from: 0; to: 1; stepSize: 0.02
                                    value: Pipewire.defaultAudioSource?.audio.volume ?? 0
                                    onMoved: if(Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.volume=value
                                    background: Item {}
                                    handle: Rectangle { visible: false; width: 1; height: 1 }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: inMuteMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"; border.color: inMuteMouse.containsMouse ? root.colBorderMuted : "transparent"; border.width: 1
                                Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg }
                                MouseArea { id: inMuteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.muted=!Pipewire.defaultAudioSource.audio.muted }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    visible: {
                        let ns=Pipewire.nodes?Pipewire.nodes.values:[]; let c=0;
                        for(let i=0;i<ns.length;i++) if(ns[i] && ns[i].isStream && ns[i].isSink) c++;
                        return c>0;
                    }
                    Text { text: "APPS"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let ns=Pipewire.nodes?Pipewire.nodes.values:[]; let out=[];
                            for(let i=0;i<ns.length;i++){ let n=ns[i]; if(n && n.isStream && n.isSink) out.push(n); }
                            return out.slice(0,6);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 30; radius: root.radius; color: streamMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.06) : "transparent"; border.color: streamMouse.containsMouse ? root.colBorderMuted : "transparent"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 6
                                Text { text: modelData.audio?.muted ? "󰝟" : "󰕾"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
                                Text {
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    text: modelData.description || modelData.name || "Stream"
                                    font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg
                                }
                                Text { text: Math.round((modelData.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2) }
                                Rectangle {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: "transparent"; border.color: "transparent"; border.width: 1
                                    Text { anchors.centerIn: parent; text: modelData.audio?.muted ? "󰝟" : "󰝧"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(modelData.audio) modelData.audio.muted=!modelData.audio.muted }
                                }
                            }
                            Slider {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.leftMargin: 6; anchors.rightMargin: 6; anchors.bottomMargin: 2
                                height: 4; from: 0; to: 1.2; value: modelData.audio.volume??0
                                onMoved: if(modelData.audio) modelData.audio.volume=value
                                background: Rectangle { radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.14); implicitHeight: 4 }
                                handle: Rectangle { visible: false }
                            }
                            MouseArea { id: streamMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: wifiPopup
        visible: root.wifiPopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 48
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: wifiCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: wifiCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Row {
                    width: parent.width
                    Text { text: "󰖩  Wi-Fi"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 8; height: 1 }
                    Text {
                        text: Networking.wifiEnabled ? "ON" : "OFF"
                        font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                        color: Networking.wifiEnabled ? root.colAccent : Qt.darker(root.colFg,1.4)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                    Rectangle {
                        width: 44; height: 22; radius: root.radius; color: Networking.wifiEnabled ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.18) : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                        border.color: root.colBorderMuted; border.width: 1
                        Rectangle {
                            width: 16; height: 16; radius: root.radius; color: root.colFg
                            x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                            y: 3
                            Behavior on x { NumberAnimation{ duration:140; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Networking.wifiEnabled=!Networking.wifiEnabled }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.colBorderMuted; opacity: 0.5 }
                Column {
                    width: parent.width; spacing: 4
                    visible: {
                        for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) return true;
                        return false;
                    }
                    Text { text: "CONNECTED"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let out=[];
                            for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) out.push(root.wifiNets[i]);
                            return out.slice(0,1);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 32; radius: root.radius; color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10); border.color: root.colBorderMuted; border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "󰤨"; font.family: root.fontFamily; font.pixelSize: 13; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.ssid || modelData.name || "Wi-Fi"; font.family: root.fontFamily; font.pixelSize: 12; font.weight: 600; color: root.colFg; elide: Text.ElideRight; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: Math.round((modelData.signalStrength||0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2); anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    Text { text: "AVAILABLE"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let all=root.wifiNets.slice(0);
                            all.sort((a,b)=> (b.signalStrength||0)-(a.signalStrength||0));
                            return all.slice(0,8);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: root.radius
                            color: wifiRowMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                            border.color: modelData.connected ? root.colBorderMuted : (wifiRowMouse.containsMouse ? root.colBorderMuted : "transparent")
                            border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text {
                                    text: {
                                        let s=modelData.signalStrength||0;
                                        if(s>0.66) return "󰤨";
                                        if(s>0.33) return "󰤥";
                                        return "󰤢";
                                    }
                                    font.family: root.fontFamily; font.pixelSize: 12; color: modelData.connected ? root.colAccent : root.colFg; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: modelData.ssid || modelData.name || "Hidden"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 90; anchors.verticalCenter: parent.verticalCenter; font.weight: modelData.connected?600:400 }
                                Text { text: modelData.security!==0 ? "󰌾" : ""; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.connected ? "●" : ""; font.family: root.fontFamily; font.pixelSize: 8; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: wifiRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if(modelData.connected) modelData.disconnect();
                                    else {
                                        if(modelData.known) modelData.connect();
                                        else {
                                            if(modelData.security===0) modelData.connect();
                                            else Quickshell.execDetached(["bash","-c","alacritty -e nmtui &"]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.wifiNets.length===0
                        text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi disabled"
                        font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.5); font.italic: true
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footWifiMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰑓 Refresh"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footWifiMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(root.wifiDev) root.wifiDev.scannerEnabled=true }
                    }
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footWifi2Mouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰖩 Settings"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footWifi2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","nm-connection-editor &"]) }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: btPopup
        visible: root.bluetoothPopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 12
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: btCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: btCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Row {
                    width: parent.width
                    Text { text: "󰂯  Bluetooth"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 8; height: 1 }
                    Text { text: root.btAdapter && root.btAdapter.enabled ? "ON" : "OFF"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: root.btAdapter && root.btAdapter.enabled ? root.colAccent : Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                    Rectangle {
                        width: 44; height: 22; radius: root.radius; color: root.btAdapter && root.btAdapter.enabled ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.18) : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                        border.color: root.colBorderMuted; border.width: 1
                        Rectangle { width: 16; height: 16; radius: root.radius; color: root.colFg; x: root.btAdapter && root.btAdapter.enabled ? parent.width - width - 3 : 3; y: 3; Behavior on x { NumberAnimation{ duration:140; easing.type: Easing.OutCubic } } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(root.btAdapter) root.btAdapter.enabled=!root.btAdapter.enabled }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.colBorderMuted; opacity: 0.5 }
                Column {
                    width: parent.width; spacing: 4
                    visible: {
                        for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) return true;
                        return false;
                    }
                    Text { text: "CONNECTED"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let out=[];
                            for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) out.push(root.btDevices[i]);
                            return out.slice(0,4);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 32; radius: root.radius; color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10); border.color: root.colBorderMuted; border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "󰂱"; font.family: root.fontFamily; font.pixelSize: 13; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name || modelData.deviceName || modelData.address || "Device"; font.family: root.fontFamily; font.pixelSize: 12; font.weight: 600; color: root.colFg; elide: Text.ElideRight; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.batteryAvailable ? Math.round(modelData.battery*100)+"%" : ""; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(modelData.disconnect) modelData.disconnect(); else if(modelData.connected) Quickshell.execDetached(["bluetoothctl","disconnect", modelData.address]) }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    Text { text: "DEVICES"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: root.btDevices.slice(0,8)
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: root.radius
                            color: btRowMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                            border.color: modelData.connected ? root.colBorderMuted : (btRowMouse.containsMouse ? root.colBorderMuted : "transparent")
                            border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂲"); font.family: root.fontFamily; font.pixelSize: 12; color: modelData.connected ? root.colAccent : root.colFg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name || modelData.deviceName || modelData.address || "Unknown"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; font.weight: modelData.connected?600:400 }
                                Text { text: modelData.connected ? "●" : ""; font.family: root.fontFamily; font.pixelSize: 8; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: btRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if(modelData.connected){
                                        if(modelData.disconnect) modelData.disconnect();
                                        else Quickshell.execDetached(["bluetoothctl","disconnect", modelData.address]);
                                    } else {
                                        if(modelData.paired) {
                                            if(modelData.connect) modelData.connect();
                                            else Quickshell.execDetached(["bluetoothctl","connect", modelData.address]);
                                        } else {
                                            Quickshell.execDetached(["bluetoothctl","pair", modelData.address]);
                                            if(modelData.connect) Qt.callLater(function(){ modelData.connect(); });
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.btDevices.length===0
                        text: !root.btAdapter ? "No adapter" : (!root.btAdapter.enabled ? "Bluetooth off" : "Scanning…")
                        font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.5); font.italic: true
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footBtMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰂯 Scan"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footBtMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(root.btAdapter) root.btAdapter.discovering=!root.btAdapter.discovering }
                    }
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footBt2Mouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰂯 Settings"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footBt2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","blueman-manager &"]) }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: root.calendarOpen || root.volumePopupOpen || root.wifiPopupOpen || root.bluetoothPopupOpen
        anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
        color: "transparent"
        exclusiveZone: 0
        MouseArea { anchors.fill: parent; onClicked: root.closeAllPopups() }
    }

    Scope {
        id: volumeOsd
        PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
        Connections {
            target: Pipewire.defaultAudioSink?.audio
            function onVolumeChanged() { volumeOsd.shouldShowOsd = true; hideTimer.restart(); }
        }
        property bool shouldShowOsd: false
        Timer { id: hideTimer; interval: 1000; onTriggered: volumeOsd.shouldShowOsd=false }
        LazyLoader {
            active: volumeOsd.shouldShowOsd
            PanelWindow {
                anchors.bottom: true
                margins.bottom: screen.height / 5
                exclusiveZone: 0
                implicitWidth: 400
                implicitHeight: 50
                color: root.colBg
                mask: Region {}
                Rectangle {
                    anchors.fill: parent
                    border.color: root.colBorder
                    border.width: 1
                    radius: root.radius
                    color: root.colBg
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 15 }
                        Text {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            font.family: root.fontFamily; font.pixelSize: 18; color: root.colFg
                            text: {
                                const s=Pipewire.defaultAudioSink;
                                if(!s?.audio) return "\uf026";
                                if(s.audio.muted||s.audio.volume===0) return "\uf026";
                                if(s.audio.volume<0.5) return "\uf027";
                                return "\uf028";
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 6; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18)
                            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } radius: root.radius; implicitWidth: parent.width*(Pipewire.defaultAudioSink?.audio.volume??0); color: root.colAccent; Behavior on implicitWidth{ NumberAnimation{duration:120; easing.type:Easing.OutCubic} } }
                        }
                        Text { text: Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 12; font.weight:600; color: root.colFg }
                    }
                }
            }
        }
    }
}
