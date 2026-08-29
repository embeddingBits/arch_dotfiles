import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: osdRoot
    implicitHeight: parent.height
    implicitWidth: 300
    color: Settings.layoutColor
    radius: 20
    opacity: 0
    scale: 0.88

    NumberAnimation on opacity { from: 0; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }
    NumberAnimation on scale   { from: 0.88; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            width: 36; height: 36
            radius: 10
            color: Colors.primaryContainer

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: ServicePipewire.muted ? "volume_off"
                       : ServicePipewire.volume > 0.6 ? "volume_up"
                       : ServicePipewire.volume > 0.2 ? "volume_down"
                       : "volume_mute"
                iconSize: 20
                customColor: Colors.primaryContainerText
            }
        }

        M3Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            interactive: false
            progress: ServicePipewire.muted ? 0 : Math.min(ServicePipewire.volume, 1)
        }

        CustomText {
            content: ServicePipewire.muted ? "Muted"
                   : Math.round(Math.min(ServicePipewire.volume * 100, 100)) + "%"
            size: 12
            weight: 600
            customColor: Colors.outline
            Layout.preferredWidth: 38
        }
    }
}
