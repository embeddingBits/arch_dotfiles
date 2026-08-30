import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../config/Theme.qml" as Theme

Item {
    id: root

    visible: UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery
    Layout.preferredWidth: 58
    Layout.preferredHeight: 26

    property real pct: (UPower.displayDevice?.percentage ?? 0)
    property int devState: (UPower.displayDevice?.state ?? 0)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: battMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: 4

        Text {
            text: {
                let p = root.pct * 100;
                let ch = root.devState === 1;
                if (ch)
                    return "󰂄";
                if (p > 90)
                    return "󰁹";
                if (p > 70)
                    return "󰂀";
                if (p > 50)
                    return "󰁿";
                if (p > 30)
                    return "󰁾";
                if (p > 15)
                    return "󰁼";
                return "󰁺";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: root.pct < 0.2 && root.devState !== 1 ? "#cc241d" : Theme.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Math.round(root.pct * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            font.weight: 600
            color: Theme.fg
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: Theme.underlineBattery
        opacity: battMouse.containsMouse ? 1 : 0.92
    }

    MouseArea {
        id: battMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
