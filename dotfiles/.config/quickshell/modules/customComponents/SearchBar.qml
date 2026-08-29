import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Rectangle{
    radius: 20
    color: Colors.surfaceContainerHigh

    RowLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        MaterialIconSymbol{
            content: "search"
            iconSize: 20
        }

        TextInput{
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            clip: true
            width: parent.width - parent.height
            text: ""
            height: parent.height - 12
            font.pixelSize: 18
            font.weight: 800
            color: Colors.inverseSurface

        }
    }
}
