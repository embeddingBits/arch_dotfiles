import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

Rectangle{
    id: root
    property bool compact: false
    implicitHeight: root.compact ? 38 : 46
    color: "transparent"

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0


        ExpressiveIconRow {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: Settings.quickIcons
            iconFor: function(m, active) { return active ? m.iconActive : m.icon }
            activeCheck: function(i) {
                if (i === 0) return !ServiceNetwork.wifiEnabled
                if (i === 1) return ServiceNotification.muted
                if (i === 2) return ServicePipewire.muted
                if (i === 3) return ServicePipewire.micMuted
                if (i === 4) return ServiceIdleInhibit.active
                return false
            }
            onTriggered: i => {
                if      (i === 0) ServiceNetwork.toggleWifi()
                else if (i === 1) ServiceNotification.toggleMute()
                else if (i === 2) ServicePipewire.toggleMute()
                else if (i === 3) ServicePipewire.toggleMicMute()
                else if (i === 4) ServiceIdleInhibit.toggle()
            }
        }
    }
}

