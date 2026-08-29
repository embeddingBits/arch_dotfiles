import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

WelcomeTile {
    id: tile

    icon: "monitor"
    title: "DISPLAYS"

    readonly property string primary: SettingsConfig.general.primaryMonitor ?? ""

    CustomText {
        Layout.fillWidth: true
        content: "The primary screen carries the full bar, the dashboard and the widget canvas."
        size: 12
        customColor: Colors.outline
        wrapMode: Text.WordWrap
    }

    M3ButtonGroup {
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        fillWidth: true
        model: {
            const out = []
            for (const s of Quickshell.screens)
                out.push({ value: s.name, label: s.name, icon: "monitor" })
            return out
        }
        activeCheck: v => tile.primary === "" ? v === Quickshell.screens[0].name : tile.primary === v
        onSegmentClicked: v => SettingsConfig.general = Object.assign({}, SettingsConfig.general, {
            primaryMonitor: v
        })
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        CustomToogle {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 30
            isToggleOn: SettingsConfig.general.perMonitorWorkspaces ?? false
            onToggled: state => SettingsConfig.general = Object.assign({}, SettingsConfig.general, {
                perMonitorWorkspaces: state
            })
        }

        CustomText {
            Layout.fillWidth: true
            content: "Split workspaces per monitor"
            size: 12
        }
    }
}
