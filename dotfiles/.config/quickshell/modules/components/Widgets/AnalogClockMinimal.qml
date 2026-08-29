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
        anchors.centerIn: parent
        width: root.clockSize
        height: root.clockSize
        roundedPolygon: MaterialShapeFn.getCircle()
        color: Colors.surface
    }

    // 12 o'clock dot — absolute y so it's independent of ShapeCanvas geometry
    Rectangle {
        x: root.width  / 2 - width  / 2
        y: root.height / 2 - root.clockSize / 2 + 12
        width: 6; height: 6; radius: 3
        color: Colors.primary
    }

    // Hour hand
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 6
        height: root.clockSize * 0.30
        radius: 3
        color: Colors.surfaceVariantText
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
        width: 3
        height: root.clockSize * 0.40
        radius: 1.5
        color: Colors.surfaceVariantText
        transformOrigin: Item.Bottom
        rotation: (parseInt(ServiceClock.minute) + parseInt(ServiceClock.seconds) / 60) / 60 * 360
        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Clockwise; duration: 400; easing.type: Easing.OutCubic }
        }
    }

    // Second hand
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 2
        height: root.clockSize * 0.42
        radius: 1
        color: Colors.primary
        transformOrigin: Item.Bottom
        rotation: parseInt(ServiceClock.seconds) / 60 * 360
        Behavior on rotation {
            RotationAnimation { direction: RotationAnimation.Clockwise; duration: 200; easing.type: Easing.Linear }
        }
    }

    // Center dot
    Rectangle {
        anchors.centerIn: parent
        width: 8; height: 8; radius: 4
        color: Colors.surfaceVariantText
        z: 10
    }

    // Date badge — absolute position, ~65% radius at 4 o'clock direction
    Rectangle {
        id: badge
        x: root.width  / 2 + root.clockSize * 0.36 - width  / 2
        y: root.height / 2 + root.clockSize * 0.04 - height / 2
        height: 22
        width: dateText.implicitWidth + 16
        radius: 11
        color: Colors.primary
        z: 5

        CustomText {
            id: dateText
            anchors.centerIn: parent
            content: ServiceClock.date
            size: 12
            weight: 700
            customColor: Colors.primaryText
        }
    }
}
