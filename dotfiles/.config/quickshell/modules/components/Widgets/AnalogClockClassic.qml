import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "analogClock"
    defaultPos: Qt.point(400, 200)
    implicitWidth: 200
    implicitHeight: 200

    property real clockSize: 200

    // Clock face
    MaterialShapes.ShapeCanvas {
        id: face
        anchors.centerIn: parent
        width: root.clockSize
        height: root.clockSize
        roundedPolygon: MaterialShapeFn.getCircle()
        color: Colors.surface
    }

    // Hour numbers — 12, 3, 6, 9 near the face edge
    Repeater {
        model: [
            { label: "12", angle: -90 },
            { label: "3",  angle:   0 },
            { label: "6",  angle:  90 },
            { label: "9",  angle: 180 }
        ]

        delegate: CustomText {
            property real rad: modelData.angle * Math.PI / 180
            property real r: root.clockSize / 2 - 36
            x: root.width  / 2 + r * Math.cos(rad) - implicitWidth  / 2
            y: root.height / 2 + r * Math.sin(rad) - implicitHeight / 2
            content: modelData.label
            size: 60
            weight: 600
            customColor: Colors.primary
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
        }
    }

    // Hour hand
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 10
        height: root.clockSize * 0.27
        radius: 5
        color: Colors.surfaceText
        transformOrigin: Item.Bottom
        rotation: (parseInt(ServiceClock.hour) % 12 + parseInt(ServiceClock.minute) / 60) / 12 * 360
        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Clockwise; duration: 400; easing.type: Easing.OutCubic }
        }
    }

    // Minute hand
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 6
        height: root.clockSize * 0.37
        radius: 3
        color: Colors.surfaceText
        transformOrigin: Item.Bottom
        rotation: (parseInt(ServiceClock.minute) + parseInt(ServiceClock.seconds) / 60) / 60 * 360
        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Clockwise; duration: 400; easing.type: Easing.OutCubic }
        }
    }

    // Second hand — bottom exactly at center
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 2
        height: root.clockSize * 0.40
        radius: 1
        color: Colors.primary
        transformOrigin: Item.Bottom
        rotation: parseInt(ServiceClock.seconds) / 60 * 360
        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Clockwise; duration: 200; easing.type: Easing.Linear }
        }
    }

    // Center cap
    Rectangle {
        anchors.centerIn: parent
        width: 14; height: 14; radius: 7
        color: Colors.primary
        z: 10
    }
    Rectangle {
        anchors.centerIn: parent
        width: 6; height: 6; radius: 3
        color: Colors.primaryText
        z: 11
    }
}
