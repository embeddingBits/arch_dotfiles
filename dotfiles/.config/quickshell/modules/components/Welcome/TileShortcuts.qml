import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

WelcomeTile {
    id: section

    icon: "keyboard"
    title: "SHORTCUTS"
    note: "Nebula never edits your config"

    readonly property var binds: [
        { what: "App launcher", name: "appLauncher",       keys: ["Super", "Ctrl", "Return"], hypr: "SUPER CTRL, Return", lua: "SUPER + CTRL + RETURN", locked: false },
        { what: "Overview",     name: "overview",          keys: ["Super", "Tab"],            hypr: "SUPER, Tab",         lua: "SUPER + TAB",           locked: false },
        { what: "Clipboard",    name: "clipboard",         keys: ["Super", "V"],              hypr: "SUPER, V",           lua: "SUPER + V",             locked: false },
        { what: "Wallpapers",   name: "wallpaperLauncher", keys: ["Super", "W"],              hypr: "SUPER, W",           lua: "SUPER + W",             locked: false },
        { what: "Tools",        name: "toolsWidget",       keys: ["Super", "S"],              hypr: "SUPER, S",           lua: "SUPER + S",             locked: false },
        { what: "Nebula Drop",  name: "filedrop",          keys: ["Super", "F"],              hypr: "SUPER, F",           lua: "SUPER + F",             locked: false },
        { what: "AI panel",     name: "ai",                keys: ["Super", "D"],              hypr: "SUPER, D",           lua: "SUPER + D",             locked: false },
        { what: "Settings",     name: "settingOpen",       keys: ["Super", "Ctrl", "S"],      hypr: "SUPER CTRL, S",      lua: "SUPER + CTRL + S",      locked: false },
        { what: "Cheat sheet",  name: "cheatsheet",        keys: ["Super", "/"],              hypr: "SUPER, Slash",       lua: "SUPER + SLASH",         locked: false },
        { what: "Lock screen",  name: "lock",              keys: ["Super", "L"],              hypr: "SUPER, L",           lua: "SUPER + L",             locked: true  },
        { what: "Session menu", name: "shutdown",          keys: ["Super", "Shift", "S"],     hypr: "SUPER SHIFT, S",     lua: "SUPER + SHIFT + S",     locked: true  }
    ]

    function hyprBlock() {
        let out = "# Nebula\n"
        for (const b of section.binds)
            out += "bind = " + b.hypr + ", global, quickshell:" + b.name + "\n"
        out += "bind = , XF86MonBrightnessUp, global, quickshell:brightnessIncrease\n"
        out += "bind = , XF86MonBrightnessDown, global, quickshell:brightnessDecrease\n"
        return out
    }

    function luaBlock() {
        let out = "-- Nebula\n"
        for (const b of section.binds) {
            out += 'hl.bind("' + b.lua + '", hl.dsp.global("quickshell:' + b.name + '")'
            out += b.locked ? ', { locked = true })\n' : ')\n'
        }
        out += 'hl.bind("XF86MonBrightnessUp",   hl.dsp.global("quickshell:brightnessIncrease"))\n'
        out += 'hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightnessDecrease"))\n'
        return out
    }

    property string copied: ""

    Timer {
        id: copyReset
        interval: 1600
        onTriggered: section.copied = ""
    }

    function copy(which, text) {
        Quickshell.clipboardText = text
        section.copied = which
        copyReset.restart()
    }

    CustomText {
        Layout.fillWidth: true
        content: "Live in the shell right now. Pick your own keys, copy a block, paste it in."
        size: 12
        customColor: Colors.outline
        wrapMode: Text.WordWrap
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: section.binds

            Rectangle {
                id: bindTile
                required property var modelData

                width: bindRow.implicitWidth + 28
                height: 40
                radius: 20
                color: Colors.surfaceContainerHigh

                RowLayout {
                    id: bindRow
                    anchors.centerIn: parent
                    spacing: 10

                    CustomText {
                        content: bindTile.modelData.what
                        size: 12
                    }

                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        Repeater {
                            model: bindTile.modelData.keys
                            KeyCap { required property string modelData; key: modelData }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        M3Button {
            size: "xsmall"
            variant: section.copied === "hypr" ? "filled" : "tonal"
            icon: section.copied === "hypr" ? "check" : "content_copy"
            label: "hyprland.conf"
            onClicked: section.copy("hypr", section.hyprBlock())
        }

        M3Button {
            size: "xsmall"
            variant: section.copied === "lua" ? "filled" : "tonal"
            icon: section.copied === "lua" ? "check" : "content_copy"
            label: "Lua config"
            onClicked: section.copy("lua", section.luaBlock())
        }

        Item { Layout.fillWidth: true }
    }
}
