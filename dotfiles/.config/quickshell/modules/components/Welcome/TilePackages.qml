import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

WelcomeTile {
    id: section

    icon: "deployed_code"
    title: "PACKAGES"
    note: section.scanning ? "checking"
        : section.missing.length === 0 ? "all present"
                                       : section.missing.length + " missing"

    readonly property var tools: [
        { cmd: "awww",          pkg: "awww-git",      label: "Wallpapers"  },
        { cmd: "cliphist",      pkg: "cliphist",      label: "Clipboard"   },
        { cmd: "wl-copy",       pkg: "wl-clipboard",  label: "Copy paste"  },
        { cmd: "brightnessctl", pkg: "brightnessctl", label: "Brightness"  },
        { cmd: "grimblast",     pkg: "grimblast-git", label: "Screenshots" },
        { cmd: "swappy",        pkg: "swappy",        label: "Annotation"  },
        { cmd: "wf-recorder",   pkg: "wf-recorder",   label: "Recording"   },
        { cmd: "cava",          pkg: "cava",          label: "Visualiser"  },
        { cmd: "qalc",          pkg: "libqalculate",  label: "Calculator"  },
        { cmd: "qrencode",      pkg: "qrencode",      label: "Nebula Drop" },
        { cmd: "ddcutil",       pkg: "ddcutil",       label: "Monitor DDC" }
    ]

    property var found: ({})
    property bool scanning: true
    property bool venvOk: false

    readonly property var missing: {
        const out = []
        for (const t of section.tools)
            if (section.found[t.cmd] === false) out.push(t.pkg)
        if (!section.scanning && !section.venvOk) out.push("materialyoucolor")
        return out
    }

    function scan() {
        if (checker.running)
            return
        section.scanning = true
        let script = ""
        for (const t of section.tools)
            script += 'command -v ' + t.cmd + ' >/dev/null 2>&1 && echo "' + t.cmd + ':1" || echo "' + t.cmd + ':0"\n'
        script += 'V="${NEBULA_VENV:-$HOME/.local/state/quickshell/.venv}"\n'
        script += '"$V/bin/python" -c "import materialyoucolor" >/dev/null 2>&1 && echo "venv:1" || echo "venv:0"\n'
        checker.command = ["bash", "-c", script]
        checker.running = true
    }

    Process {
        id: checker

        stdout: StdioCollector {
            onStreamFinished: {
                const map = ({})
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(":")
                    if (parts.length !== 2) continue
                    if (parts[0] === "venv") section.venvOk = parts[1] === "1"
                    else map[parts[0]] = parts[1] === "1"
                }
                section.found = map
                section.scanning = false
            }
        }
    }

    property bool copied: false
    Timer { id: copyReset; interval: 1600; onTriggered: section.copied = false }

    Component.onCompleted: section.scan()

    CustomText {
        Layout.fillWidth: true
        content: "Each backs one feature. A missing package switches that feature off, nothing else."
        size: 12
        customColor: Colors.outline
        wrapMode: Text.WordWrap
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6

        StatusChip {
            label: "Colour engine"
            status: section.scanning ? 0 : section.venvOk ? 1 : 2
        }

        Repeater {
            model: section.tools

            StatusChip {
                required property var modelData
                label: modelData.label
                status: section.found[modelData.cmd] === true ? 1
                      : section.found[modelData.cmd] === false ? 2
                                                               : 0
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        M3Button {
            visible: !section.scanning && section.missing.length > 0
            size: "xsmall"
            variant: section.copied ? "filled" : "tonal"
            icon: section.copied ? "check" : "content_copy"
            label: "Copy install command"
            onClicked: {
                Quickshell.clipboardText = "yay -S --needed " + section.missing.join(" ")
                section.copied = true
                copyReset.restart()
            }
        }

        M3Button {
            size: "xsmall"
            variant: "text"
            icon: "refresh"
            label: "Re-check"
            enabledButton: !section.scanning
            onClicked: section.scan()
        }

        Item { Layout.fillWidth: true }
    }
}
