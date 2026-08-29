import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapesFn


Item{
    id: root
    implicitHeight: 400
    implicitWidth: 400

    property bool editMode: false

    scale: root.editMode ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    layer.enabled: root.editMode
    layer.smooth: true
    layer.textureSize: root.editMode ? Qt.size(width * 1.05, height * 1.05) : Qt.size(width, height)

    Component.onCompleted: {
        root.x = SettingsConfig.widgets.temperatureX
        root.y = SettingsConfig.widgets.temperatureY
    }

    onXChanged: if (editMode) tempSaveTimer.restart()
    onYChanged: if (editMode) tempSaveTimer.restart()

    Timer {
        id: tempSaveTimer
        interval: 500
        repeat: false
        onTriggered: {
            SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { temperatureX: root.x, temperatureY: root.y })
        }
    }

    MouseArea {
        anchors.fill: parent
        drag.target: root.editMode ? root : undefined
        cursorShape: root.editMode ? Qt.SizeAllCursor : Qt.ArrowCursor
        onDoubleClicked: root.editMode = true
        onReleased: if (root.editMode) root.editMode = false
    }


    Rectangle{
        anchors.centerIn: parent
        implicitWidth: 300
        implicitHeight: 70
        color: Colors.primary
        radius: 30



        RowLayout{
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle{
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                radius: width / 2
                color: Colors.primaryText

                MaterialIconSymbol{
                    anchors.centerIn: parent
                    content: ServiceWeather.weatherIconPath
                    iconSize: 30
                    color: Colors.primary
                }
            }

            Rectangle{
                Layout.preferredHeight: 50
                Layout.fillWidth: true
                radius: width / 2
                color: Colors.primaryText

                RowLayout{
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 20
                    CustomText{
                        content: ServiceWeather.temperature
                        size: 24
                        color: Colors.primary
                    }

                    CustomText{
                        content: ServiceWeather.description
                        size: 16
                        color: Colors.outline
                    }
                }
            }
        }
    }
}
